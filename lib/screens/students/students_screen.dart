import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
import '../../models/student_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

// ─── Students List Screen ─────────────────────────────────────────────────────

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _search = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadAll();
      context.read<ClassProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value);
    });
  }

  void _openForm([Student? existing]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _StudentFormPage(existing: existing)),
    );
  }

  void _openProfile(Student s) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _StudentDetailPage(student: s)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final role = context.watch<AuthProvider>().role;
    final isWide = MediaQuery.of(context).size.width >= 720;
    final canEdit = role == UserRole.admin || role == UserRole.teacher;
    final list = _query.isEmpty ? provider.students : provider.search(_query);

    return Scaffold(
      appBar: AppBar(
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    ShellScreen.scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Text('Students'),
        actions: [
          if (role == UserRole.admin)
            IconButton(
              icon: const Icon(Icons.upgrade_rounded),
              tooltip: 'Session Promotion',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const _PromotionPage()),
              ),
            ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Student'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search by name or roll number…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: provider.loading
                ? const LoadingWidget()
                : provider.error != null
                    ? AppErrorWidget(
                        message: 'Failed to load students.\n${provider.error}',
                        onRetry: () =>
                            context.read<StudentProvider>().loadAll(),
                      )
                    : list.isEmpty
                        ? EmptyState(
                            icon: Icons.people_outline,
                            title: 'No students found',
                            onButton: canEdit ? () => _openForm() : null,
                            buttonLabel: 'Add Student',
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                context.read<StudentProvider>().loadAll(),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: list.length,
                              itemBuilder: (ctx, i) {
                                final s = list[i];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    onTap: () => _openProfile(s),
                                    leading: AvatarWidget(
                                      initials: s.initials,
                                      radius: 22,
                                    ),
                                    title: Text(s.fullName),
                                    subtitle: Text(
                                        'Roll: ${s.rollNumber}  •  Age: ${s.age}'
                                        '${s.gender != null ? '  •  ${s.gender}' : ''}'),
                                    trailing: canEdit
                                        ? PopupMenuButton<String>(
                                            onSelected: (v) async {
                                              if (v == 'edit') {
                                                _openForm(s);
                                              } else {
                                                final ok =
                                                    await showConfirmDialog(
                                                  context,
                                                  title: 'Delete Student',
                                                  message:
                                                      'Delete ${s.fullName}?',
                                                );
                                                if (ok == true &&
                                                    context.mounted) {
                                                  await context
                                                      .read<StudentProvider>()
                                                      .delete(s.id);
                                                }
                                              }
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                  value: 'edit',
                                                  child: Text('Edit')),
                                              PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Delete')),
                                            ],
                                          )
                                        : const Icon(Icons.chevron_right),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ─── Student Detail Page ──────────────────────────────────────────────────────

class _StudentDetailPage extends StatelessWidget {
  final Student student;
  const _StudentDetailPage({required this.student});

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;
    final canEdit = role == UserRole.admin || role == UserRole.teacher;
    final classes = context.watch<ClassProvider>().classes;
    final className = classes
        .where((c) => c.id == student.classId)
        .map((c) => c.displayName)
        .firstOrNull;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(student.fullName),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => _StudentFormPage(existing: student)),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  AvatarWidget(initials: student.initials, radius: 40),
                  const SizedBox(height: 12),
                  Text(student.fullName, style: tt.headlineSmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (className != null) Chip(label: Text(className)),
                      Chip(
                        label: Text(student.status.toUpperCase()),
                        backgroundColor: student.isActive
                            ? cs.primaryContainer
                            : cs.errorContainer,
                        labelStyle: TextStyle(
                          color: student.isActive
                              ? cs.onPrimaryContainer
                              : cs.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                      if (student.category != null)
                        Chip(
                          label: Text(student.category!.toUpperCase()),
                          backgroundColor: cs.secondaryContainer,
                          labelStyle: TextStyle(
                              color: cs.onSecondaryContainer, fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Admission Info ──────────────────────────────────────────────
            _sectionCard(
              title: 'Admission Info',
              icon: Icons.assignment_outlined,
              rows: [
                _row('Form No.', student.formNumber),
                _row('Scholar No.', student.scholarNumber),
                _row('Admission No.', student.admissionNumber),
                _row('Roll No.', student.rollNumber),
                _row('Admission Date', _fmt(student.admissionDate)),
                _row('Class', className),
              ],
            ),

            // ── Personal Details ────────────────────────────────────────────
            _sectionCard(
              title: 'Personal Details',
              icon: Icons.person_outline,
              rows: [
                _row('Full Name', student.fullName),
                _row('Date of Birth', _fmt(student.dateOfBirth)),
                _row('Age', '${student.age} years'),
                _row('Gender', student.gender),
                _row('Blood Group', student.bloodGroup),
              ],
            ),

            // ── Address ─────────────────────────────────────────────────────
            _sectionCard(
              title: 'Address',
              icon: Icons.home_outlined,
              rows: [
                _row('Address', student.address),
                _row('City', student.city),
                _row('State', student.state),
              ],
            ),

            // ── Family Details ──────────────────────────────────────────────
            _sectionCard(
              title: 'Family Details',
              icon: Icons.family_restroom_outlined,
              rows: [
                _row("Father's Name",
                    student.fatherName ?? student.parentName),
                _row("Mother's Name", student.motherName),
                _row("Guardian's Name", student.guardianName),
                _row("Father's Occupation", student.fatherOccupation),
                _row("Father's Qualification", student.fatherQualification),
                _row("Mother's Qualification", student.motherQualification),
              ],
            ),

            // ── Contact ─────────────────────────────────────────────────────
            _sectionCard(
              title: 'Contact',
              icon: Icons.phone_outlined,
              rows: [
                _row('Mobile', student.parentPhone),
                _row('Office Phone', student.officePhone),
                _row('Email', student.parentEmail),
              ],
            ),

            // ── Identity Documents ──────────────────────────────────────────
            _sectionCard(
              title: 'Identity Documents',
              icon: Icons.badge_outlined,
              rows: [
                _row('UDISE No.', student.udiseNumber),
                _row('Aadhar No.', student.aadharNumber),
              ],
            ),

            // ── Bank Details ────────────────────────────────────────────────
            _sectionCard(
              title: 'Bank Details',
              icon: Icons.account_balance_outlined,
              rows: [
                _row('Account No.', student.bankAccountNumber),
                _row('IFSC Code', student.ifscCode),
              ],
            ),

            // ── Previous Education ──────────────────────────────────────────
            _sectionCard(
              title: 'Previous Education',
              icon: Icons.school_outlined,
              rows: [
                _row('Last Passed Class', student.lastPassedClass),
                _row('Year', student.lastPassedYear),
                _row(
                    'Percentage',
                    student.lastPassedPercentage != null
                        ? '${student.lastPassedPercentage}%'
                        : null),
                _row('Total Marks', student.lastPassedTotal),
              ],
            ),

            // ── Transfer Certificate ────────────────────────────────────────
            if (student.tcNumber != null)
              _sectionCard(
                title: 'Transfer Certificate',
                icon: Icons.verified_outlined,
                rows: [
                  _row('TC Number', student.tcNumber),
                  _row(
                      'Issued Date',
                      student.tcIssuedDate != null
                          ? _fmt(student.tcIssuedDate!)
                          : null),
                  _row('Status', 'Alumni'),
                ],
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<_InfoRow?> rows,
  }) {
    final visible = rows.whereType<_InfoRow>().toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ]),
              const Divider(height: 20),
              ...visible.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 160,
                          child: Text(r.label,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        ),
                        Expanded(
                          child: Text(r.value,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  static _InfoRow? _row(String label, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _InfoRow(label, value.trim());
  }
}

class _InfoRow {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);
}

// ─── Student Form Page ────────────────────────────────────────────────────────

class _StudentFormPage extends StatefulWidget {
  final Student? existing;
  const _StudentFormPage({this.existing});

  @override
  State<_StudentFormPage> createState() => _StudentFormPageState();
}

class _StudentFormPageState extends State<_StudentFormPage> {
  // ── Section 1 — Admission Info ──────────────────────────────────────────────
  final _formNoCtrl = TextEditingController();
  final _scholarNoCtrl = TextEditingController();
  final _admNoCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  DateTime _admDate = DateTime.now();
  String? _selectedClass;
  String? _category;

  // ── Section 2 — Personal ────────────────────────────────────────────────────
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  DateTime _dob = DateTime(2010);
  String? _gender;
  final _bloodCtrl = TextEditingController();

  // ── Section 3 — Address ─────────────────────────────────────────────────────
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();

  // ── Section 4 — Family ──────────────────────────────────────────────────────
  final _fatherNameCtrl = TextEditingController();
  final _motherNameCtrl = TextEditingController();
  final _guardianCtrl = TextEditingController();
  final _fatherOccCtrl = TextEditingController();
  final _fatherQualCtrl = TextEditingController();
  final _motherQualCtrl = TextEditingController();

  // ── Section 5 — Contact ─────────────────────────────────────────────────────
  final _mobileCtrl = TextEditingController();
  final _officePhoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // ── Section 6 — Identity ────────────────────────────────────────────────────
  final _udiseCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();

  // ── Section 7 — Bank ────────────────────────────────────────────────────────
  final _bankAccCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  // ── Section 8 — Previous Education ─────────────────────────────────────────
  final _lastClassCtrl = TextEditingController();
  final _lastYearCtrl = TextEditingController();
  final _lastPctCtrl = TextEditingController();
  final _lastTotalCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    if (s == null) return;
    _formNoCtrl.text = s.formNumber ?? '';
    _scholarNoCtrl.text = s.scholarNumber ?? '';
    _admNoCtrl.text = s.admissionNumber ?? '';
    _rollCtrl.text = s.rollNumber;
    _admDate = s.admissionDate;
    _selectedClass = s.classId;
    _category = s.category;
    _firstCtrl.text = s.firstName;
    _lastCtrl.text = s.lastName;
    _dob = s.dateOfBirth;
    _gender = s.gender;
    _bloodCtrl.text = s.bloodGroup ?? '';
    _addressCtrl.text = s.address ?? '';
    _cityCtrl.text = s.city ?? '';
    _stateCtrl.text = s.state ?? '';
    _fatherNameCtrl.text = s.fatherName ?? s.parentName ?? '';
    _motherNameCtrl.text = s.motherName ?? '';
    _guardianCtrl.text = s.guardianName ?? '';
    _fatherOccCtrl.text = s.fatherOccupation ?? '';
    _fatherQualCtrl.text = s.fatherQualification ?? '';
    _motherQualCtrl.text = s.motherQualification ?? '';
    _mobileCtrl.text = s.parentPhone ?? '';
    _officePhoneCtrl.text = s.officePhone ?? '';
    _emailCtrl.text = s.parentEmail ?? '';
    _udiseCtrl.text = s.udiseNumber ?? '';
    _aadharCtrl.text = s.aadharNumber ?? '';
    _bankAccCtrl.text = s.bankAccountNumber ?? '';
    _ifscCtrl.text = s.ifscCode ?? '';
    _lastClassCtrl.text = s.lastPassedClass ?? '';
    _lastYearCtrl.text = s.lastPassedYear ?? '';
    _lastPctCtrl.text = s.lastPassedPercentage ?? '';
    _lastTotalCtrl.text = s.lastPassedTotal ?? '';
  }

  @override
  void dispose() {
    for (final c in [
      _formNoCtrl, _scholarNoCtrl, _admNoCtrl, _rollCtrl,
      _firstCtrl, _lastCtrl, _bloodCtrl,
      _addressCtrl, _cityCtrl, _stateCtrl,
      _fatherNameCtrl, _motherNameCtrl, _guardianCtrl,
      _fatherOccCtrl, _fatherQualCtrl, _motherQualCtrl,
      _mobileCtrl, _officePhoneCtrl, _emailCtrl,
      _udiseCtrl, _aadharCtrl,
      _bankAccCtrl, _ifscCtrl,
      _lastClassCtrl, _lastYearCtrl, _lastPctCtrl, _lastTotalCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_firstCtrl.text.trim().isEmpty ||
        _lastCtrl.text.trim().isEmpty ||
        _rollCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('First name, last name and roll number are required'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    final data = <String, dynamic>{
      'first_name': _firstCtrl.text.trim(),
      'last_name': _lastCtrl.text.trim(),
      'roll_number': _rollCtrl.text.trim(),
      'date_of_birth': _dob.toIso8601String().split('T')[0],
      'admission_date': _admDate.toIso8601String().split('T')[0],
      if (_formNoCtrl.text.isNotEmpty) 'form_number': _formNoCtrl.text.trim(),
      if (_scholarNoCtrl.text.isNotEmpty)
        'scholar_number': _scholarNoCtrl.text.trim(),
      if (_admNoCtrl.text.isNotEmpty)
        'admission_number': _admNoCtrl.text.trim(),
      if (_selectedClass != null) 'class_id': _selectedClass,
      if (_category != null) 'category': _category,
      if (_gender != null) 'gender': _gender,
      if (_bloodCtrl.text.isNotEmpty) 'blood_group': _bloodCtrl.text.trim(),
      if (_addressCtrl.text.isNotEmpty) 'address': _addressCtrl.text.trim(),
      if (_cityCtrl.text.isNotEmpty) 'city': _cityCtrl.text.trim(),
      if (_stateCtrl.text.isNotEmpty) 'state': _stateCtrl.text.trim(),
      if (_fatherNameCtrl.text.isNotEmpty)
        'father_name': _fatherNameCtrl.text.trim(),
      if (_motherNameCtrl.text.isNotEmpty)
        'mother_name': _motherNameCtrl.text.trim(),
      if (_guardianCtrl.text.isNotEmpty)
        'guardian_name': _guardianCtrl.text.trim(),
      if (_fatherOccCtrl.text.isNotEmpty)
        'father_occupation': _fatherOccCtrl.text.trim(),
      if (_fatherQualCtrl.text.isNotEmpty)
        'father_qualification': _fatherQualCtrl.text.trim(),
      if (_motherQualCtrl.text.isNotEmpty)
        'mother_qualification': _motherQualCtrl.text.trim(),
      if (_mobileCtrl.text.isNotEmpty) 'parent_phone': _mobileCtrl.text.trim(),
      if (_officePhoneCtrl.text.isNotEmpty)
        'office_phone': _officePhoneCtrl.text.trim(),
      if (_emailCtrl.text.isNotEmpty) 'parent_email': _emailCtrl.text.trim(),
      if (_udiseCtrl.text.isNotEmpty) 'udise_number': _udiseCtrl.text.trim(),
      if (_aadharCtrl.text.isNotEmpty) 'aadhar_number': _aadharCtrl.text.trim(),
      if (_bankAccCtrl.text.isNotEmpty)
        'bank_account_number': _bankAccCtrl.text.trim(),
      if (_ifscCtrl.text.isNotEmpty) 'ifsc_code': _ifscCtrl.text.trim(),
      if (_lastClassCtrl.text.isNotEmpty)
        'last_passed_class': _lastClassCtrl.text.trim(),
      if (_lastYearCtrl.text.isNotEmpty)
        'last_passed_year': _lastYearCtrl.text.trim(),
      if (_lastPctCtrl.text.isNotEmpty)
        'last_passed_percentage': _lastPctCtrl.text.trim(),
      if (_lastTotalCtrl.text.isNotEmpty)
        'last_passed_total': _lastTotalCtrl.text.trim(),
    };
    try {
      if (widget.existing == null) {
        await context.read<StudentProvider>().create(data);
      } else {
        await context
            .read<StudentProvider>()
            .update(widget.existing!.id, data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving student: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<ClassProvider>().classes;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.existing == null ? 'Add Student' : 'Edit Student'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Admission Info ────────────────────────────────────────────
            _FormSection(
              title: 'Admission Info',
              icon: Icons.assignment_outlined,
              children: [
                _twoCol(_tf(_formNoCtrl, 'Form No.'),
                    _tf(_scholarNoCtrl, 'Scholar No.')),
                const SizedBox(height: 12),
                _twoCol(_tf(_admNoCtrl, 'Admission No.'),
                    _tf(_rollCtrl, 'Roll Number *')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedClass),
                  initialValue: _selectedClass,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: classes
                      .map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.displayName)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedClass = v),
                ),
                const SizedBox(height: 12),
                _dateTile('Admission Date', _admDate, (p) {
                  setState(() => _admDate = p);
                }, firstDate: DateTime(2000)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_category),
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const [
                    DropdownMenuItem(
                        value: 'general', child: Text('General')),
                    DropdownMenuItem(value: 'obc', child: Text('OBC')),
                    DropdownMenuItem(value: 'sc', child: Text('SC')),
                    DropdownMenuItem(value: 'st', child: Text('ST')),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Personal Details ──────────────────────────────────────────
            _FormSection(
              title: 'Personal Details',
              icon: Icons.person_outline,
              children: [
                _twoCol(_tf(_firstCtrl, 'First Name *'),
                    _tf(_lastCtrl, 'Last Name *')),
                const SizedBox(height: 12),
                _dateTile('Date of Birth', _dob, (p) {
                  setState(() => _dob = p);
                }, firstDate: DateTime(1990)),
                const SizedBox(height: 12),
                _twoCol(
                  DropdownButtonFormField<String>(
                    key: ValueKey(_gender),
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(
                          value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _gender = v),
                  ),
                  _tf(_bloodCtrl, 'Blood Group'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Address ───────────────────────────────────────────────────
            _FormSection(
              title: 'Address',
              icon: Icons.home_outlined,
              children: [
                _tf(_addressCtrl, 'Address'),
                const SizedBox(height: 12),
                _twoCol(_tf(_cityCtrl, 'City'), _tf(_stateCtrl, 'State')),
              ],
            ),
            const SizedBox(height: 16),

            // ── Family Details ────────────────────────────────────────────
            _FormSection(
              title: 'Family Details',
              icon: Icons.family_restroom_outlined,
              children: [
                _twoCol(_tf(_fatherNameCtrl, "Father's Name"),
                    _tf(_motherNameCtrl, "Mother's Name")),
                const SizedBox(height: 12),
                _tf(_guardianCtrl, "Guardian's Name (if any)"),
                const SizedBox(height: 12),
                _tf(_fatherOccCtrl, "Father's Occupation"),
                const SizedBox(height: 12),
                _twoCol(_tf(_fatherQualCtrl, "Father's Qualification"),
                    _tf(_motherQualCtrl, "Mother's Qualification")),
              ],
            ),
            const SizedBox(height: 16),

            // ── Contact ───────────────────────────────────────────────────
            _FormSection(
              title: 'Contact',
              icon: Icons.phone_outlined,
              children: [
                _twoCol(
                  _tf(_mobileCtrl, 'Mobile',
                      type: TextInputType.phone),
                  _tf(_officePhoneCtrl, 'Office Phone',
                      type: TextInputType.phone),
                ),
                const SizedBox(height: 12),
                _tf(_emailCtrl, 'Email',
                    type: TextInputType.emailAddress),
              ],
            ),
            const SizedBox(height: 16),

            // ── Identity Documents ────────────────────────────────────────
            _FormSection(
              title: 'Identity Documents',
              icon: Icons.badge_outlined,
              children: [
                _twoCol(_tf(_udiseCtrl, 'UDISE No.'),
                    _tf(_aadharCtrl, 'Aadhar No.')),
              ],
            ),
            const SizedBox(height: 16),

            // ── Bank Details ──────────────────────────────────────────────
            _FormSection(
              title: 'Bank Details',
              icon: Icons.account_balance_outlined,
              children: [
                _tf(_bankAccCtrl, 'Bank Account No.',
                    type: TextInputType.number),
                const SizedBox(height: 12),
                _tf(_ifscCtrl, 'IFSC Code'),
              ],
            ),
            const SizedBox(height: 16),

            // ── Previous Education ────────────────────────────────────────
            _FormSection(
              title: 'Previous Education',
              icon: Icons.school_outlined,
              children: [
                _twoCol(
                  _tf(_lastClassCtrl, 'Last Passed Class'),
                  _tf(_lastYearCtrl, 'Year',
                      type: TextInputType.number),
                ),
                const SizedBox(height: 12),
                _twoCol(
                  _tf(_lastPctCtrl, 'Percentage (%)',
                      type: TextInputType.number),
                  _tf(_lastTotalCtrl, 'Total Marks',
                      type: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                  widget.existing == null ? 'Add Student' : 'Save Changes'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static Widget _twoCol(Widget a, Widget b) => Row(
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );

  static Widget _tf(
    TextEditingController ctrl,
    String label, {
    TextInputType type = TextInputType.text,
  }) =>
      TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
        keyboardType: type,
      );

  Widget _dateTile(
    String label,
    DateTime value,
    void Function(DateTime) onPicked, {
    DateTime? firstDate,
  }) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: Text(
            '${value.day.toString().padLeft(2, '0')}/'
            '${value.month.toString().padLeft(2, '0')}/${value.year}'),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final p = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: firstDate ?? DateTime(1990),
            lastDate: DateTime.now(),
          );
          if (p != null) onPicked(p);
        },
      );
}

// ─── Form Section Card ────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _FormSection(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ─── Session Promotion Page ───────────────────────────────────────────────────

class _PromotionPage extends StatefulWidget {
  const _PromotionPage();

  @override
  State<_PromotionPage> createState() => _PromotionPageState();
}

class _PromotionPageState extends State<_PromotionPage> {
  List<PromotionGroup>? _groups;
  bool _loading = true;
  bool _running = false;
  String? _error;

  // Default new academic year: if current is "2024-25" → "2025-26"
  late final TextEditingController _yearCtrl;

  @override
  void initState() {
    super.initState();
    _yearCtrl = TextEditingController(text: _nextYear());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    super.dispose();
  }

  static String _nextYear() {
    final now = DateTime.now();
    final y = now.month >= 4 ? now.year : now.year - 1;
    return '$y-${(y + 1).toString().substring(2)}';
  }

  Future<void> _loadPreview() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classes = context.read<ClassProvider>().classes;
      final groups =
          await context.read<StudentProvider>().previewPromotion(classes);
      if (mounted) setState(() => _groups = groups);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmAndRun() async {
    final groups = _groups;
    if (groups == null) return;

    final newYear = _yearCtrl.text.trim();
    if (newYear.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter the new academic year'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final totalStudents =
        groups.fold<int>(0, (s, g) => s + g.studentCount);
    final graduating =
        groups.where((g) => g.isGraduation).fold<int>(0, (s, g) => s + g.studentCount);
    final promoting = totalStudents - graduating;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Session Promotion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New academic year: $newYear'),
            const SizedBox(height: 12),
            _summaryRow(Icons.upgrade_rounded, Colors.green,
                '$promoting students promoted to next class'),
            const SizedBox(height: 8),
            _summaryRow(Icons.verified_outlined, Colors.indigo,
                '$graduating students will receive TC (Alumni)'),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone. Proceed?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.deepOrange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Run Promotion'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _running = true);
    try {
      final result = await context
          .read<StudentProvider>()
          .runPromotion(groups, newYear);
      if (!mounted) return;
      _showResult(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Promotion failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  void _showResult(PromotionResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Promotion Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow(Icons.upgrade_rounded, Colors.green,
                '${result.promoted} students promoted'),
            const SizedBox(height: 8),
            _summaryRow(Icons.verified_outlined, Colors.indigo,
                '${result.graduated} TCs issued (Alumni)'),
            if (result.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Warnings:',
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold)),
              ...result.warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $w',
                        style: const TextStyle(fontSize: 13)),
                  )),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // back to students list
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  static Widget _summaryRow(IconData icon, Color color, String text) =>
      Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ]);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final groups = _groups ?? [];
    final totalPromoted =
        groups.where((g) => !g.isGraduation && g.toClass != null).fold<int>(
            0, (s, g) => s + g.studentCount);
    final totalGrad = groups
        .where((g) => g.isGraduation)
        .fold<int>(0, (s, g) => s + g.studentCount);
    final totalWarn =
        groups.where((g) => !g.isGraduation && g.toClass == null).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Promotion'),
        actions: [
          if (!_loading && !_running)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reload preview',
              onPressed: _loadPreview,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _loadPreview,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Year picker ─────────────────────────────────────
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Academic Year',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _yearCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'New Academic Year',
                                  hintText: 'e.g. 2025-26',
                                  prefixIcon: Icon(Icons.calendar_month),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Summary chips ───────────────────────────────────
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chip(Icons.upgrade_rounded, Colors.green,
                                  '$totalPromoted to be promoted'),
                              _chip(Icons.verified_outlined, Colors.indigo,
                                  '$totalGrad to receive TC'),
                              if (totalWarn > 0)
                                _chip(Icons.warning_amber_rounded,
                                    Colors.orange,
                                    '$totalWarn class(es) unresolved'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Class-by-class preview ──────────────────────────
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Promotion Preview',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const Divider(height: 20),
                              if (groups.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text('No active students found.'),
                                )
                              else
                                ...groups.map((g) => _groupRow(g, cs)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Run button ──────────────────────────────────────
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed:
                            (_running || groups.isEmpty) ? null : _confirmAndRun,
                        icon: _running
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Icon(Icons.upgrade_rounded),
                        label: Text(_running
                            ? 'Running…'
                            : 'Run Session Promotion'),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  static Widget _chip(IconData icon, Color color, String label) => Chip(
        avatar: Icon(icon, color: color, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 13)),
      );

  static Widget _groupRow(PromotionGroup g, ColorScheme cs) {
    final Color rowColor;
    final String targetLabel;
    final IconData targetIcon;

    if (g.isGraduation) {
      rowColor = Colors.indigo;
      targetLabel = 'TC Issued (Alumni)';
      targetIcon = Icons.verified_outlined;
    } else if (g.toClass != null) {
      rowColor = Colors.green;
      targetLabel = g.toClass!.displayName;
      targetIcon = Icons.arrow_forward_rounded;
    } else {
      rowColor = Colors.orange;
      targetLabel = 'No Grade ${g.fromClass.gradeLevel + 1} class found';
      targetIcon = Icons.warning_amber_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.fromClass.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${g.studentCount} student(s)',
                    style:
                        TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(targetIcon, color: rowColor, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(targetLabel,
                style: TextStyle(
                    color: rowColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
