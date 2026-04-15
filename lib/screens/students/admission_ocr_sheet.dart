import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/admission_ocr_service.dart';

/// Data that gets applied back to the Add/Edit Student form.
class AdmissionOcrFill {
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
  final String? category;

  const AdmissionOcrFill({
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
  });
}

/// Show the OCR bottom sheet. Returns [AdmissionOcrFill] if the user confirms,
/// or null if cancelled.
Future<AdmissionOcrFill?> showAdmissionOcrSheet(BuildContext context) {
  return showModalBottomSheet<AdmissionOcrFill>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _AdmissionOcrSheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _AdmissionOcrSheet extends StatefulWidget {
  const _AdmissionOcrSheet();

  @override
  State<_AdmissionOcrSheet> createState() => _AdmissionOcrSheetState();
}

enum _Step { pick, scanning, review, unsupported }

class _AdmissionOcrSheetState extends State<_AdmissionOcrSheet> {
  _Step _step = _Step.pick;
  AdmissionOcrResult? _result;
  String? _error;

  // ── Editable controllers for review step ──────────────────────────────────
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _fatherCtrl = TextEditingController();
  final _motherCtrl = TextEditingController();
  final _formNoCtrl = TextEditingController();
  final _scholarCtrl = TextEditingController();
  final _admNoCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _fatherOccCtrl = TextEditingController();
  final _fatherQualCtrl = TextEditingController();
  final _motherQualCtrl = TextEditingController();
  final _guardianCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _officeCtrl = TextEditingController();
  final _udiseCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _lpClassCtrl = TextEditingController();
  final _lpYearCtrl = TextEditingController();
  final _lpPctCtrl = TextEditingController();
  final _lpTotalCtrl = TextEditingController();
  String? _dobValue;     // displayed date string
  DateTime? _dobParsed;
  String? _category;

  @override
  void dispose() {
    for (final c in [
      _firstCtrl, _lastCtrl, _fatherCtrl, _motherCtrl,
      _formNoCtrl, _scholarCtrl, _admNoCtrl, _addressCtrl,
      _fatherOccCtrl, _fatherQualCtrl, _motherQualCtrl, _guardianCtrl,
      _mobileCtrl, _officeCtrl, _udiseCtrl, _aadharCtrl,
      _bankCtrl, _ifscCtrl, _lpClassCtrl, _lpYearCtrl, _lpPctCtrl, _lpTotalCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fillControllers(AdmissionOcrResult r) {
    _firstCtrl.text = r.firstName ?? '';
    _lastCtrl.text = r.lastName ?? '';
    _fatherCtrl.text = r.fatherName ?? '';
    _motherCtrl.text = r.motherName ?? '';
    _formNoCtrl.text = r.formNumber ?? '';
    _scholarCtrl.text = r.scholarNumber ?? '';
    _admNoCtrl.text = r.admissionNumber ?? '';
    _addressCtrl.text = r.address ?? '';
    _fatherOccCtrl.text = r.fatherOccupation ?? '';
    _fatherQualCtrl.text = r.fatherQualification ?? '';
    _motherQualCtrl.text = r.motherQualification ?? '';
    _guardianCtrl.text = r.guardianName ?? '';
    _mobileCtrl.text = r.mobile ?? '';
    _officeCtrl.text = r.officePhone ?? '';
    _udiseCtrl.text = r.udiseNumber ?? '';
    _aadharCtrl.text = r.aadharNumber ?? '';
    _bankCtrl.text = r.bankAccountNumber ?? '';
    _ifscCtrl.text = r.ifscCode ?? '';
    _lpClassCtrl.text = r.lastPassedClass ?? '';
    _lpYearCtrl.text = r.lastPassedYear ?? '';
    _lpPctCtrl.text = r.lastPassedPercentage ?? '';
    _lpTotalCtrl.text = r.lastPassedTotal ?? '';
    _dobParsed = r.dateOfBirth;
    _dobValue = r.dateOfBirth != null
        ? '${r.dateOfBirth!.day.toString().padLeft(2, '0')}/'
            '${r.dateOfBirth!.month.toString().padLeft(2, '0')}/'
            '${r.dateOfBirth!.year}'
        : null;
    _category = r.category;
  }

  Future<void> _scan(ImageSource source) async {
    setState(() {
      _step = _Step.scanning;
      _error = null;
    });
    try {
      final result = await AdmissionOcrService.scanFromSource(source);
      if (result == null) {
        // User cancelled
        setState(() => _step = _Step.pick);
        return;
      }
      if (!AdmissionOcrService.isSupported) {
        setState(() => _step = _Step.unsupported);
        return;
      }
      _result = result;
      _fillControllers(result);
      setState(() => _step = _Step.review);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _step = _Step.pick;
      });
    }
  }

  void _confirm() {
    Navigator.pop(
      context,
      AdmissionOcrFill(
        firstName: _firstCtrl.text.trim().isEmpty ? null : _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim().isEmpty ? null : _lastCtrl.text.trim(),
        fatherName: _fatherCtrl.text.trim().isEmpty ? null : _fatherCtrl.text.trim(),
        motherName: _motherCtrl.text.trim().isEmpty ? null : _motherCtrl.text.trim(),
        dateOfBirth: _dobParsed,
        formNumber: _formNoCtrl.text.trim().isEmpty ? null : _formNoCtrl.text.trim(),
        scholarNumber: _scholarCtrl.text.trim().isEmpty ? null : _scholarCtrl.text.trim(),
        admissionNumber: _admNoCtrl.text.trim().isEmpty ? null : _admNoCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        fatherOccupation: _fatherOccCtrl.text.trim().isEmpty ? null : _fatherOccCtrl.text.trim(),
        fatherQualification: _fatherQualCtrl.text.trim().isEmpty ? null : _fatherQualCtrl.text.trim(),
        motherQualification: _motherQualCtrl.text.trim().isEmpty ? null : _motherQualCtrl.text.trim(),
        guardianName: _guardianCtrl.text.trim().isEmpty ? null : _guardianCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim(),
        officePhone: _officeCtrl.text.trim().isEmpty ? null : _officeCtrl.text.trim(),
        udiseNumber: _udiseCtrl.text.trim().isEmpty ? null : _udiseCtrl.text.trim(),
        aadharNumber: _aadharCtrl.text.trim().isEmpty ? null : _aadharCtrl.text.trim(),
        bankAccountNumber: _bankCtrl.text.trim().isEmpty ? null : _bankCtrl.text.trim(),
        ifscCode: _ifscCtrl.text.trim().isEmpty ? null : _ifscCtrl.text.trim(),
        lastPassedClass: _lpClassCtrl.text.trim().isEmpty ? null : _lpClassCtrl.text.trim(),
        lastPassedYear: _lpYearCtrl.text.trim().isEmpty ? null : _lpYearCtrl.text.trim(),
        lastPassedPercentage: _lpPctCtrl.text.trim().isEmpty ? null : _lpPctCtrl.text.trim(),
        lastPassedTotal: _lpTotalCtrl.text.trim().isEmpty ? null : _lpTotalCtrl.text.trim(),
        category: _category,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Drag handle
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: EdgeInsets.only(
                left: 24, right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: _buildStep(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case _Step.pick:
        return _buildPick(context);
      case _Step.scanning:
        return _buildScanning();
      case _Step.review:
        return _buildReview(context);
      case _Step.unsupported:
        return _buildUnsupported(context);
    }
  }

  // ── Step 1: Source picker ──────────────────────────────────────────────────

  Widget _buildPick(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Scan Admission Form',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          'Take a photo or pick from gallery to auto-fill the student form.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 28),
        _SourceButton(
          icon: Icons.camera_alt_outlined,
          label: 'Take Photo',
          subtitle: 'Photograph the physical form',
          onTap: () => _scan(ImageSource.camera),
        ),
        const SizedBox(height: 14),
        _SourceButton(
          icon: Icons.photo_library_outlined,
          label: 'Choose from Gallery',
          subtitle: 'Select a saved photo',
          onTap: () => _scan(ImageSource.gallery),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  // ── Step 2: Scanning ───────────────────────────────────────────────────────

  Widget _buildScanning() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 48),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        const Text('Reading admission form…',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('Extracting student details',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        const SizedBox(height: 48),
      ],
    );
  }

  // ── Step 3: Review ─────────────────────────────────────────────────────────

  Widget _buildReview(BuildContext context) {
    final detected = _result?.detectedCount ?? 0;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$detected field${detected == 1 ? '' : 's'} detected — review and confirm',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text('Blue fields were auto-filled. Edit anything before applying.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 20),

        // ── Admission Info ─────────────────────────────────────────────────
        _reviewSection('Admission Info', Icons.assignment_outlined, [
          _reviewRow('Form No.', _formNoCtrl),
          _reviewRow('Scholar No.', _scholarCtrl),
          _reviewRow('Admission No.', _admNoCtrl),
        ]),

        // ── Student Info ───────────────────────────────────────────────────
        _reviewSection('Student Details', Icons.person_outline, [
          _reviewRow('First Name', _firstCtrl),
          _reviewRow('Last Name', _lastCtrl),
          _dobRow(context, cs),
          _categoryRow(cs),
        ]),

        // ── Family ─────────────────────────────────────────────────────────
        _reviewSection('Family Details', Icons.family_restroom_outlined, [
          _reviewRow("Father's Name", _fatherCtrl),
          _reviewRow("Mother's Name", _motherCtrl),
          _reviewRow("Guardian's Name", _guardianCtrl),
          _reviewRow("Father's Occupation", _fatherOccCtrl),
          _reviewRow("Father's Qualification", _fatherQualCtrl),
          _reviewRow("Mother's Qualification", _motherQualCtrl),
        ]),

        // ── Contact & Address ──────────────────────────────────────────────
        _reviewSection('Contact & Address', Icons.phone_outlined, [
          _reviewRow('Mobile', _mobileCtrl),
          _reviewRow('Office Phone', _officeCtrl),
          _reviewRow('Address', _addressCtrl),
        ]),

        // ── Identity ───────────────────────────────────────────────────────
        _reviewSection('Identity Documents', Icons.badge_outlined, [
          _reviewRow('UDISE No.', _udiseCtrl),
          _reviewRow('Aadhar No.', _aadharCtrl),
        ]),

        // ── Bank ───────────────────────────────────────────────────────────
        _reviewSection('Bank Details', Icons.account_balance_outlined, [
          _reviewRow('Bank Account No.', _bankCtrl),
          _reviewRow('IFSC Code', _ifscCtrl),
        ]),

        // ── Previous Education ─────────────────────────────────────────────
        _reviewSection('Previous Education', Icons.school_outlined, [
          _reviewRow('Last Passed Class', _lpClassCtrl),
          _reviewRow('Year', _lpYearCtrl),
          _reviewRow('Percentage (%)', _lpPctCtrl),
          _reviewRow('Total Marks', _lpTotalCtrl),
        ]),

        const SizedBox(height: 20),

        FilledButton.icon(
          onPressed: _confirm,
          icon: const Icon(Icons.check),
          label: const Text('Apply to Form'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => setState(() => _step = _Step.pick),
          child: const Text('Scan Again'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _reviewSection(String title, IconData icon, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey)),
        ]),
        const SizedBox(height: 8),
        ...rows,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _reviewRow(String label, TextEditingController ctrl) {
    final hasFill = ctrl.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        style: TextStyle(
            color: hasFill ? Colors.indigo.shade700 : null,
            fontWeight: hasFill ? FontWeight.w500 : null),
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: hasFill
              ? Icon(Icons.auto_fix_high, size: 16, color: Colors.indigo.shade300)
              : null,
          enabledBorder: hasFill
              ? OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.indigo.shade200),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _dobRow(BuildContext context, ColorScheme cs) {
    final has = _dobValue != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          has ? _dobValue! : 'Date of Birth — not detected',
          style: TextStyle(
            color: has ? Colors.indigo.shade700 : Colors.grey,
            fontWeight: has ? FontWeight.w500 : null,
          ),
        ),
        subtitle: has ? null : const Text('Tap to set manually'),
        trailing: Icon(
          Icons.calendar_today,
          color: has ? Colors.indigo.shade300 : Colors.grey,
          size: 18,
        ),
        onTap: () async {
          final p = await showDatePicker(
            context: context,
            initialDate: _dobParsed ?? DateTime(2010),
            firstDate: DateTime(1990),
            lastDate: DateTime.now(),
          );
          if (p != null) {
            setState(() {
              _dobParsed = p;
              _dobValue =
                  '${p.day.toString().padLeft(2, '0')}/${p.month.toString().padLeft(2, '0')}/${p.year}';
            });
          }
        },
      ),
    );
  }

  Widget _categoryRow(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey(_category),
        initialValue: _category,
        decoration: InputDecoration(
          labelText: 'Category',
          enabledBorder: _category != null
              ? OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.indigo.shade200),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
        ),
        items: const [
          DropdownMenuItem(value: 'general', child: Text('General')),
          DropdownMenuItem(value: 'obc', child: Text('OBC')),
          DropdownMenuItem(value: 'sc', child: Text('SC')),
          DropdownMenuItem(value: 'st', child: Text('ST')),
        ],
        onChanged: (v) => setState(() => _category = v),
      ),
    );
  }

  // ── Step 4: Unsupported platform ───────────────────────────────────────────

  Widget _buildUnsupported(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.smartphone_outlined, size: 56, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('OCR not available on this platform',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          'Scan feature works on Android and iOS only.\nPlease enter the details manually.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Enter Manually'),
        ),
      ],
    );
  }
}

// ─── Source button widget ─────────────────────────────────────────────────────

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cs.onPrimaryContainer, size: 24),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13)),
          ]),
          const Spacer(),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ]),
      ),
    );
  }
}
