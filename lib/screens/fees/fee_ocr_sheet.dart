import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ocr_service.dart';

/// Result returned to the caller when OCR succeeds.
class OcrFillData {
  final double? amount;
  final DateTime? paymentDate;
  final String? transactionId;
  final String? receiptNumber;
  final String? paymentMethod;
  final String? studentName;
  final String? monthYear;

  const OcrFillData({
    this.amount,
    this.paymentDate,
    this.transactionId,
    this.receiptNumber,
    this.paymentMethod,
    this.studentName,
    this.monthYear,
  });
}

/// Shows a modal bottom sheet that walks the user through:
///   1. Choosing camera or gallery
///   2. Running OCR
///   3. Previewing extracted fields (with inline edit)
///   4. Confirming → returns [OcrFillData]
Future<OcrFillData?> showFeeOcrSheet(BuildContext context) {
  return showModalBottomSheet<OcrFillData>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _FeeOcrSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _FeeOcrSheet extends StatefulWidget {
  const _FeeOcrSheet();

  @override
  State<_FeeOcrSheet> createState() => _FeeOcrSheetState();
}

enum _OcrStep { pick, scanning, review, unsupported }

class _FeeOcrSheetState extends State<_FeeOcrSheet> {
  _OcrStep _step = _OcrStep.pick;
  String? _imagePath;
  OcrReceiptResult? _result;
  String? _error;

  // Editable controllers for the review step
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _txnCtrl = TextEditingController();
  final _rcptCtrl = TextEditingController();
  final _studentCtrl = TextEditingController();
  String _method = 'cash';

  @override
  void dispose() {
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    _txnCtrl.dispose();
    _rcptCtrl.dispose();
    _studentCtrl.dispose();
    super.dispose();
  }

  // ── Source selection ─────────────────────────────────────────────────────────

  Future<void> _scan(ImageSource source) async {
    if (!OcrService.isSupported) {
      setState(() => _step = _OcrStep.unsupported);
      return;
    }
    setState(() { _step = _OcrStep.scanning; _error = null; });
    try {
      final result = await OcrService.scanFromSource(source);
      if (result == null) {
        // User cancelled
        setState(() => _step = _OcrStep.pick);
        return;
      }
      _populateControllers(result);
      setState(() {
        _result = result;
        _step = _OcrStep.review;
      });
    } catch (e) {
      setState(() {
        _error = 'OCR failed: $e';
        _step = _OcrStep.pick;
      });
    }
  }

  void _populateControllers(OcrReceiptResult r) {
    _amountCtrl.text = r.amount != null ? r.amount!.toStringAsFixed(0) : '';
    if (r.paymentDate != null) {
      final d = r.paymentDate!;
      _dateCtrl.text =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } else {
      _dateCtrl.text = '';
    }
    _txnCtrl.text = r.transactionId ?? '';
    _rcptCtrl.text = r.receiptNumber ?? '';
    _studentCtrl.text = r.studentName ?? '';
    _method = r.paymentMethod ?? 'cash';
  }

  // ── Confirm ──────────────────────────────────────────────────────────────────

  void _confirm() {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    DateTime? date;
    final parts = _dateCtrl.text.split('/');
    if (parts.length == 3) {
      date = DateTime.tryParse(
          '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}');
    }
    Navigator.pop(
      context,
      OcrFillData(
        amount: amount,
        paymentDate: date,
        transactionId: _txnCtrl.text.trim().isEmpty ? null : _txnCtrl.text.trim(),
        receiptNumber: _rcptCtrl.text.trim().isEmpty ? null : _rcptCtrl.text.trim(),
        paymentMethod: _method,
        studentName: _studentCtrl.text.trim().isEmpty ? null : _studentCtrl.text.trim(),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: switch (_step) {
        _OcrStep.pick => _buildPickStep(cs),
        _OcrStep.scanning => _buildScanningStep(cs),
        _OcrStep.review => _buildReviewStep(cs),
        _OcrStep.unsupported => _buildUnsupportedStep(cs),
      },
    );
  }

  // ── Step: pick source ────────────────────────────────────────────────────────

  Widget _buildPickStep(ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.document_scanner_rounded,
                  color: cs.onPrimaryContainer, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scan Fee Receipt',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700)),
                Text('Auto-fill from a payment receipt',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_error != null) ...[
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: cs.onErrorContainer, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error!,
                        style: TextStyle(
                            color: cs.onErrorContainer, fontSize: 12))),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (!OcrService.isSupported) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: cs.secondary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'OCR is available on Android & iOS only.\nOn this platform you can enter details manually.',
                        style: TextStyle(
                            color: cs.onSecondaryContainer, fontSize: 12))),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SourceButton(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: cs.primary,
                onTap: OcrService.isSupported
                    ? () => _scan(ImageSource.camera)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SourceButton(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: cs.tertiary,
                onTap: OcrService.isSupported
                    ? () => _scan(ImageSource.gallery)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  // ── Step: scanning ───────────────────────────────────────────────────────────

  Widget _buildScanningStep(ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 32),
        CircularProgressIndicator(color: cs.primary),
        const SizedBox(height: 20),
        Text('Reading receipt…',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text('Extracting amount, date and transaction details',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Step: review extracted fields ────────────────────────────────────────────

  Widget _buildReviewStep(ColorScheme cs) {
    final extracted = _result!;
    final hasAny = extracted.hasData;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(hasAny ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  color: hasAny ? Colors.green : cs.error, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasAny
                      ? 'Receipt scanned — verify & confirm'
                      : 'Could not extract data — enter manually',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Image preview (small thumbnail)
          if (_imagePath != null && !kIsWeb) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_imagePath!),
                height: 120,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 16),
          ],

          _ReviewField(
            label: 'Amount (₹)',
            controller: _amountCtrl,
            icon: Icons.currency_rupee_rounded,
            keyboardType: TextInputType.number,
            highlight: extracted.amount != null,
          ),
          const SizedBox(height: 10),
          _ReviewField(
            label: 'Payment Date (DD/MM/YYYY)',
            controller: _dateCtrl,
            icon: Icons.calendar_today_rounded,
            keyboardType: TextInputType.datetime,
            highlight: extracted.paymentDate != null,
          ),
          const SizedBox(height: 10),
          _ReviewField(
            label: 'Transaction / UPI Ref',
            controller: _txnCtrl,
            icon: Icons.receipt_long_rounded,
            highlight: extracted.transactionId != null,
          ),
          const SizedBox(height: 10),
          _ReviewField(
            label: 'Receipt Number',
            controller: _rcptCtrl,
            icon: Icons.numbers_rounded,
            highlight: extracted.receiptNumber != null,
          ),
          const SizedBox(height: 10),
          _ReviewField(
            label: 'Student Name (hint)',
            controller: _studentCtrl,
            icon: Icons.person_outline_rounded,
            highlight: extracted.studentName != null,
          ),
          const SizedBox(height: 10),

          // Payment method
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(
              labelText: 'Payment Method',
              prefixIcon: Icon(Icons.payment_rounded),
            ),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Cash')),
              DropdownMenuItem(value: 'online', child: Text('Online / UPI')),
              DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
              DropdownMenuItem(value: 'card', child: Text('Card')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _method = v);
            },
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Use These Details'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _step = _OcrStep.pick),
            child: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }

  // ── Step: unsupported platform ───────────────────────────────────────────────

  Widget _buildUnsupportedStep(ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Icon(Icons.devices_other_rounded, size: 48, color: cs.onSurfaceVariant),
        const SizedBox(height: 16),
        Text('OCR not available on this platform',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Receipt scanning works on Android & iOS.\nOn Windows/Web, please enter the details manually.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Enter Manually'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onTap == null;
    return Material(
      color: disabled
          ? cs.surfaceContainerHighest
          : color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon,
                  size: 32,
                  color: disabled ? cs.onSurfaceVariant : color),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: disabled ? cs.onSurfaceVariant : color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  final bool highlight;

  const _ReviewField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon,
            color: highlight ? cs.primary : null),
        suffixIcon: highlight
            ? Icon(Icons.auto_fix_high_rounded,
                color: cs.primary, size: 18)
            : null,
        enabledBorder: highlight
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              )
            : null,
      ),
    );
  }
}
