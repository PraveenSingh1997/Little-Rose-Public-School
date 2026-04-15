import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// All fields that can be extracted from a scanned admission form.
class AdmissionOcrResult {
  final String rawText;
  final String? firstName;
  final String? lastName;
  final String? fatherName;
  final String? motherName;
  final DateTime? dateOfBirth;
  final String? formNumber;
  final String? scholarNumber;
  final String? admissionNumber;
  final String? address;
  final String? fatherOccupation;
  final String? fatherQualification;
  final String? motherQualification;
  final String? guardianName;
  final String? mobile;
  final String? officePhone;
  final String? udiseNumber;
  final String? aadharNumber;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? lastPassedClass;
  final String? lastPassedYear;
  final String? lastPassedPercentage;
  final String? lastPassedTotal;
  final String? category; // general | obc | sc | st
  final String? className; // raw text class, e.g. "Grade 9"

  const AdmissionOcrResult({
    required this.rawText,
    this.firstName,
    this.lastName,
    this.fatherName,
    this.motherName,
    this.dateOfBirth,
    this.formNumber,
    this.scholarNumber,
    this.admissionNumber,
    this.address,
    this.fatherOccupation,
    this.fatherQualification,
    this.motherQualification,
    this.guardianName,
    this.mobile,
    this.officePhone,
    this.udiseNumber,
    this.aadharNumber,
    this.bankAccountNumber,
    this.ifscCode,
    this.lastPassedClass,
    this.lastPassedYear,
    this.lastPassedPercentage,
    this.lastPassedTotal,
    this.category,
    this.className,
  });

  int get detectedCount => [
        firstName, lastName, fatherName, motherName, dateOfBirth,
        formNumber, scholarNumber, admissionNumber, address,
        fatherOccupation, fatherQualification, motherQualification,
        guardianName, mobile, officePhone, udiseNumber, aadharNumber,
        bankAccountNumber, ifscCode, lastPassedClass, lastPassedYear,
        lastPassedPercentage, lastPassedTotal, category, className,
      ].where((v) => v != null).length;
}

class AdmissionOcrService {
  static final _picker = ImagePicker();

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<AdmissionOcrResult?> scanFromSource(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2048,
    );
    if (file == null) return null;
    if (!isSupported) {
      return const AdmissionOcrResult(rawText: '');
    }
    return _processFile(file.path);
  }

  static Future<AdmissionOcrResult> _processFile(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(path);
      final recognised = await recognizer.processImage(inputImage);
      return _parse(recognised.text);
    } finally {
      recognizer.close();
    }
  }

  // ── Parser ────────────────────────────────────────────────────────────────

  static AdmissionOcrResult _parse(String raw) {
    final lines =
        raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final flat = raw.replaceAll('\n', ' ');

    return AdmissionOcrResult(
      rawText: raw,
      firstName: _extractStudentFirst(flat, lines),
      lastName: _extractStudentLast(flat, lines),
      fatherName: _labelValue(flat, lines,
          [r"Father'?s?\s*Name", r'Father\s*Name']),
      motherName: _labelValue(flat, lines,
          [r"Mother'?s?\s*Name", r'Mother\s*Name']),
      dateOfBirth: _extractDob(flat),
      formNumber: _labelValue(flat, lines,
          [r'Form\s*No\.?', r'Form\s*Number', r'Form\s*#']),
      scholarNumber: _labelValue(flat, lines,
          [r'Scholar\s*No\.?', r'Scholar\s*Number']),
      admissionNumber: _labelValue(flat, lines,
          [r'Admission\s*No\.?', r'Adm\.?\s*No', r'Adm\s*Number']),
      address: _extractAddress(flat, lines),
      fatherOccupation: _labelValue(flat, lines,
          [r'Occupation\s*of\s*Father', r'Father.*Occup', r'Occupation']),
      fatherQualification:
          _extractQual(flat, lines, 'father'),
      motherQualification:
          _extractQual(flat, lines, 'mother'),
      guardianName: _labelValue(flat, lines,
          [r"Guardian'?s?\s*Name", r'Guardian\s*Name']),
      mobile: _extractPhone(flat, mobile: true),
      officePhone: _extractPhone(flat, mobile: false),
      udiseNumber: _extractUdise(flat),
      aadharNumber: _extractAadhar(flat),
      bankAccountNumber: _extractBankAccount(flat),
      ifscCode: _extractIfsc(flat),
      lastPassedClass: _extractLpField(flat, 'class'),
      lastPassedYear: _extractLpField(flat, 'year'),
      lastPassedPercentage: _extractLpField(flat, 'percent'),
      lastPassedTotal: _extractLpField(flat, 'total'),
      category: _extractCategory(flat),
      className: _labelValue(flat, lines,
          [r'Class\s+in\s+which', r'Class\s*(?:for\s*)?Admission', r'Class']),
    );
  }

  // ── Field extractors ──────────────────────────────────────────────────────

  static String? _extractStudentFirst(String text, List<String> lines) {
    final p = RegExp(
        r'(?:Name\s+of\s+the\s+Student|Student\s*Name|Name)[:\s]+([A-Z][a-zA-Z]+)',
        caseSensitive: false);
    final m = p.firstMatch(text);
    if (m != null) {
      return _cap(m.group(1)!.trim().split(RegExp(r'\s+')).first);
    }
    return null;
  }

  static String? _extractStudentLast(String text, List<String> lines) {
    final p = RegExp(
        r'(?:Name\s+of\s+the\s+Student|Student\s*Name|Name)[:\s]+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)+)',
        caseSensitive: false);
    final m = p.firstMatch(text);
    if (m != null) {
      final parts = m.group(1)!.trim().split(RegExp(r'\s+'));
      if (parts.length > 1) {
        return parts.sublist(1).map(_cap).join(' ');
      }
    }
    return null;
  }

  /// Match a labelled field inline or on the next line.
  static String? _labelValue(
      String text, List<String> lines, List<String> patterns) {
    for (final pat in patterns) {
      // Inline: "Father's Name: Ram Kumar"
      final p = RegExp(
          '$pat[:\\s]+([A-Za-z][A-Za-z .]{1,40}?)(?=\\s{2,}|[|,]|\$)',
          caseSensitive: false);
      final m = p.firstMatch(text);
      if (m != null) {
        final v = m.group(1)?.trim();
        if (v != null && v.length > 2) return v;
      }
    }
    // Next-line: find label line, next line is the value
    for (int i = 0; i < lines.length - 1; i++) {
      for (final pat in patterns) {
        if (RegExp(pat, caseSensitive: false).hasMatch(lines[i])) {
          final next = lines[i + 1].trim();
          if (next.length > 2 && !RegExp(r'^\d+$').hasMatch(next)) {
            return next;
          }
        }
      }
    }
    return null;
  }

  static DateTime? _extractDob(String text) {
    final patterns = [
      RegExp(
          r'(?:DOB|Date\s+of\s+Birth|D\.O\.B)[:\s]+(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})',
          caseSensitive: false),
      RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final d = int.tryParse(m.group(1)!);
        final mo = int.tryParse(m.group(2)!);
        final y = int.tryParse(m.group(3)!);
        if (d != null && mo != null && y != null &&
            mo <= 12 && d <= 31 && y > 1980 && y < 2030) {
          return DateTime(y, mo, d);
        }
      }
    }
    return null;
  }

  static String? _extractAddress(String text, List<String> lines) {
    final p = RegExp(
        r'Address[:\s]+(.{10,100}?)(?=\s{2,}|City|State|Pin|Mobile|Phone|\|)',
        caseSensitive: false);
    return p.firstMatch(text)?.group(1)?.trim();
  }

  static String? _extractQual(
      String text, List<String> lines, String parent) {
    final p = RegExp('Qualification.*?$parent[:\\s]+([A-Za-z.+]{2,20})',
        caseSensitive: false);
    return p.firstMatch(text)?.group(1)?.trim();
  }

  static String? _extractPhone(String text, {required bool mobile}) {
    if (mobile) {
      final p = RegExp(r'(?:Mobile|Mob\.?)[:\s]+(\d{10})',
          caseSensitive: false);
      final m = p.firstMatch(text);
      if (m != null) return m.group(1);
      // Fallback: any standalone 10-digit number
      final fb = RegExp(r'\b([6-9]\d{9})\b');
      return fb.firstMatch(text)?.group(1);
    } else {
      final p = RegExp(
          r'(?:Office|Tel\.?|Telephone|Landline)[:\s]+([\d\s\-]{8,14})',
          caseSensitive: false);
      return p.firstMatch(text)?.group(1)?.replaceAll(RegExp(r'\s'), '').trim();
    }
  }

  static String? _extractUdise(String text) {
    final p = RegExp(r'UDISE[:\s#.]*(\d{11})', caseSensitive: false);
    return p.firstMatch(text)?.group(1);
  }

  static String? _extractAadhar(String text) {
    final p = RegExp(
        r'(?:Aadhar|Aadhaar|UIDAI)[:\s#.]*(\d{4}\s?\d{4}\s?\d{4})',
        caseSensitive: false);
    final m = p.firstMatch(text);
    if (m != null) return m.group(1)!.replaceAll(' ', '');
    // Standalone 12-digit number
    final fb = RegExp(r'\b(\d{4}\s\d{4}\s\d{4})\b');
    return fb.firstMatch(text)?.group(1)?.replaceAll(' ', '');
  }

  static String? _extractBankAccount(String text) {
    final p = RegExp(
        r'(?:Bank\s*A[/]?c|Account\s*No\.?|Bank\s*Account)[:\s#.]*(\d{9,18})',
        caseSensitive: false);
    return p.firstMatch(text)?.group(1);
  }

  static String? _extractIfsc(String text) {
    final p = RegExp(r'IFSC[:\s#.]*([A-Z]{4}0[A-Z0-9]{6})',
        caseSensitive: false);
    return p.firstMatch(text)?.group(1)?.toUpperCase();
  }

  static String? _extractLpField(String text, String field) {
    switch (field) {
      case 'class':
        final p = RegExp(
            r'(?:Last\s+Passed|Last\s+Class)[:\s]+(\d{1,2}|[IVX]{1,4})',
            caseSensitive: false);
        return p.firstMatch(text)?.group(1);
      case 'year':
        final p = RegExp(r'(?:Year|Yr)\.?\s*[:\s]+(\d{4})',
            caseSensitive: false);
        return p.firstMatch(text)?.group(1);
      case 'percent':
        final p = RegExp(
            r'(?:Percentage|%|Pct)\s*[:\s]+(\d{1,3}(?:\.\d{1,2})?)',
            caseSensitive: false);
        return p.firstMatch(text)?.group(1);
      case 'total':
        final p =
            RegExp(r'Total\s*[:\s]+(\d{2,4})', caseSensitive: false);
        return p.firstMatch(text)?.group(1);
      default:
        return null;
    }
  }

  static String? _extractCategory(String text) {
    final p = RegExp(r'(?:Category|Caste)[:\s]+(\w+)', caseSensitive: false);
    final m = p.firstMatch(text);
    if (m != null) {
      final cat = m.group(1)!.toLowerCase();
      if (cat == 'sc') return 'sc';
      if (cat == 'st') return 'st';
      if (cat == 'obc') return 'obc';
      if (cat.startsWith('gen')) return 'general';
    }
    // Checked checkboxes near labels (✓ / ✗ / ☑)
    if (RegExp(r'[✓✗☑]\s*SC|SC\s*[✓✗☑]').hasMatch(text)) return 'sc';
    if (RegExp(r'[✓✗☑]\s*ST|ST\s*[✓✗☑]').hasMatch(text)) return 'st';
    if (RegExp(r'[✓✗☑]\s*OBC|OBC\s*[✓✗☑]').hasMatch(text)) return 'obc';
    if (RegExp(r'[✓✗☑]\s*(?:General|Gen)|(?:General|Gen)\s*[✓✗☑]')
        .hasMatch(text)) {
      return 'general';
    }
    return null;
  }

  static String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
}
