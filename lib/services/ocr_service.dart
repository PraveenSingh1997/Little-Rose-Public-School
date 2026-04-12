import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

// ML Kit is only available on Android / iOS
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Fields extracted from a scanned fee receipt.
class OcrReceiptResult {
  final String rawText;
  final double? amount;
  final DateTime? paymentDate;
  final String? transactionId;
  final String? receiptNumber;
  final String? paymentMethod; // 'cash' | 'online' | 'cheque' | 'card'
  final String? studentName;
  final String? monthYear;

  const OcrReceiptResult({
    required this.rawText,
    this.amount,
    this.paymentDate,
    this.transactionId,
    this.receiptNumber,
    this.paymentMethod,
    this.studentName,
    this.monthYear,
  });

  bool get hasData =>
      amount != null ||
      paymentDate != null ||
      transactionId != null ||
      receiptNumber != null;
}

class OcrService {
  static final _picker = ImagePicker();

  // ── Platform check ──────────────────────────────────────────────────────────

  /// True on Android and iOS only — ML Kit does not support web or desktop.
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Pick an image from [source] and run OCR on it.
  /// Returns null if the user cancelled or if the platform is unsupported.
  static Future<OcrReceiptResult?> scanFromSource(
      ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (file == null) return null;

    if (!isSupported) {
      // On web / desktop: return raw text placeholder so the caller can
      // still show the form pre-filled with empty values.
      return const OcrReceiptResult(rawText: '');
    }

    return _processFile(file.path);
  }

  // ── OCR + parsing ───────────────────────────────────────────────────────────

  static Future<OcrReceiptResult> _processFile(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(path);
      final recognised = await recognizer.processImage(inputImage);
      final raw = recognised.text;
      return _parse(raw);
    } finally {
      recognizer.close();
    }
  }

  /// Parse raw OCR text into structured fields.
  static OcrReceiptResult _parse(String raw) {
    final text = raw.replaceAll('\n', ' ');

    return OcrReceiptResult(
      rawText: raw,
      amount: _extractAmount(text),
      paymentDate: _extractDate(text),
      transactionId: _extractTransactionId(text),
      receiptNumber: _extractReceiptNumber(text),
      paymentMethod: _extractPaymentMethod(text),
      studentName: _extractStudentName(text),
      monthYear: _extractMonthYear(text),
    );
  }

  // ── Field extractors ────────────────────────────────────────────────────────

  static double? _extractAmount(String text) {
    // Patterns: ₹ 1,200  |  Rs. 1200  |  Amount: 1200  |  Total: 1,200.00
    final patterns = [
      RegExp(r'[₹Rs\.]+\s*(\d{1,6}(?:,\d{3})*(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'(?:Amount|Total|Amt|Fee)[:\s]+(\d{1,6}(?:,\d{3})*(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'(\d{3,6}(?:\.\d{2})?)\s*(?:only|/-)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final raw = m.group(1)!.replaceAll(',', '');
        final v = double.tryParse(raw);
        if (v != null && v > 0 && v < 1000000) return v;
      }
    }
    return null;
  }

  static DateTime? _extractDate(String text) {
    // DD/MM/YYYY  |  DD-MM-YYYY  |  YYYY-MM-DD  |  DD MMM YYYY
    final patterns = [
      RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})'),
      RegExp(r'(\d{4})[\/\-](\d{2})[\/\-](\d{2})'),
      RegExp(
          r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})',
          caseSensitive: false),
    ];
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    // DD/MM/YYYY or DD-MM-YYYY
    final m1 = patterns[0].firstMatch(text);
    if (m1 != null) {
      final d = int.tryParse(m1.group(1)!);
      final mo = int.tryParse(m1.group(2)!);
      final y = int.tryParse(m1.group(3)!);
      if (d != null && mo != null && y != null && mo <= 12 && d <= 31) {
        return DateTime(y, mo, d);
      }
    }

    // YYYY-MM-DD
    final m2 = patterns[1].firstMatch(text);
    if (m2 != null) {
      final y = int.tryParse(m2.group(1)!);
      final mo = int.tryParse(m2.group(2)!);
      final d = int.tryParse(m2.group(3)!);
      if (y != null && mo != null && d != null) {
        return DateTime(y, mo, d);
      }
    }

    // DD MMM YYYY
    final m3 = patterns[2].firstMatch(text);
    if (m3 != null) {
      final d = int.tryParse(m3.group(1)!);
      final mo = months[m3.group(2)!.toLowerCase()];
      final y = int.tryParse(m3.group(3)!);
      if (d != null && mo != null && y != null) {
        return DateTime(y, mo, d);
      }
    }

    return null;
  }

  static String? _extractTransactionId(String text) {
    // UPI Ref, Txn ID, UTR, NEFT/IMPS ref no
    final p = RegExp(
        r'(?:Txn|Transaction|UPI\s*Ref|UTR|Ref\.?\s*No|NEFT|IMPS)[:\s#\.]*([A-Z0-9]{6,22})',
        caseSensitive: false);
    return p.firstMatch(text)?.group(1);
  }

  static String? _extractReceiptNumber(String text) {
    final p = RegExp(
        r'(?:Receipt|Rcpt|R\.?\s*No|Invoice)[:\s#\.]*([A-Z0-9\-\/]{3,20})',
        caseSensitive: false);
    return p.firstMatch(text)?.group(1);
  }

  static String? _extractPaymentMethod(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('upi') ||
        lower.contains('gpay') ||
        lower.contains('phonepe') ||
        lower.contains('paytm') ||
        lower.contains('neft') ||
        lower.contains('imps') ||
        lower.contains('rtgs') ||
        lower.contains('online') ||
        lower.contains('net banking')) { return 'online'; }
    if (lower.contains('cheque') || lower.contains('check') || lower.contains('dd ')) { return 'cheque'; }
    if (lower.contains('card') ||
        lower.contains('debit') ||
        lower.contains('credit') ||
        lower.contains('swipe')) { return 'card'; }
    if (lower.contains('cash')) { return 'cash'; }
    return null;
  }

  static String? _extractStudentName(String text) {
    final p = RegExp(
        r'(?:Student|Name|Paid\s+By)[:\s]+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)',
        caseSensitive: false);
    return p.firstMatch(text)?.group(1)?.trim();
  }

  static String? _extractMonthYear(String text) {
    // "April 2025" | "Apr-25" | "04/2025"
    final p = RegExp(
        r'(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s\-]+(\d{4}|\d{2})',
        caseSensitive: false);
    final m = p.firstMatch(text);
    if (m != null) return m.group(0);
    return null;
  }
}
