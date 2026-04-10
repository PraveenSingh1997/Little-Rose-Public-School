import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _store = StorageService();
  String _search = '';
  String _classFilter = 'All';

  List<String> get _classes {
    final c = _store.students.map((s) => s.className).toSet().toList()..sort();
    return ['All', ...c];
  }

  List<Student> get _filtered {
    return _store.students.where((s) {
      final matchSearch = _search.isEmpty ||
          s.name.toLowerCase().contains(_search.toLowerCase()) ||
          s.rollNo.toLowerCase().contains(_search.toLowerCase());
      final matchClass = _classFilter == 'All' || s.className == _classFilter;
      return matchSearch && matchClass && s.isActive;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _openForm({Student? student}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _StudentForm(
        existing: student,
        onSave: (s) {
          setState(() {
            if (student != null) {
              final i = _store.students.indexWhere((x) => x.id == s.id);
              if (i != -1) _store.students[i] = s;
            } else {
              _store.students.add(s);
            }
          });
          _store.saveStudents();
        },
      ),
    );
  }

  void _delete(Student s) {
    setState(() => s.isActive = false);
    _store.saveStudents();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${s.name} removed'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          setState(() => s.isActive = true);
          _store.saveStudents();
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            automaticallyImplyLeading: MediaQuery.of(context).size.width < 720,
            leading: MediaQuery.of(context).size.width < 720
                ? Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  )
                : null,
            title: const Text('Students'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    SearchBar(
                      hintText: 'Search by name or roll no…',
                      leading: const Icon(Icons.search),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _classes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final c = _classes[i];
                          final selected = _classFilter == c;
                          return FilterChip(
                            label: Text(c),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _classFilter = c),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('No students found',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final s = _filtered[i];
                  return _StudentCard(
                    student: s,
                    onEdit: () => _openForm(student: s),
                    onDelete: () => _delete(s),
                    onTap: () => _showDetail(s),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Student'),
      ),
    );
  }

  void _showDetail(Student s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _StudentDetail(
        student: s,
        store: _store,
        onEdit: () {
          Navigator.pop(context);
          _openForm(student: s);
        },
      ),
    );
  }
}

// ─── Student Card ─────────────────────────────────────────────────────────────

class _StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = student.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Text(initials,
              style: TextStyle(
                  color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
        ),
        title: Text(student.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${student.rollNo} · ${student.className} - ${student.section}'),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
        ),
      ),
    );
  }
}

// ─── Student Detail ───────────────────────────────────────────────────────────

class _StudentDetail extends StatelessWidget {
  final Student student;
  final StorageService store;
  final VoidCallback onEdit;

  const _StudentDetail(
      {required this.student, required this.store, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final initials = student.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: cs.primaryContainer,
                  child: Text(initials,
                      style: TextStyle(
                          fontSize: 28,
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(student.name, style: tt.headlineSmall),
                Text(student.rollNo,
                    style:
                        tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Student'),
          ),
          const SizedBox(height: 20),
          _DetailRow(label: 'Class', value: '${student.className} - ${student.section}'),
          _DetailRow(label: 'Gender', value: student.gender.label),
          _DetailRow(label: 'Age', value: '${student.age} years'),
          _DetailRow(
              label: 'Date of Birth',
              value: DateFormat('MMMM d, y').format(student.dob)),
          _DetailRow(
              label: 'Enrolled',
              value: DateFormat('MMMM d, y').format(student.enrollmentDate)),
          if (student.parentName != null)
            _DetailRow(label: 'Parent / Guardian', value: student.parentName!),
          if (student.phone != null)
            _DetailRow(label: 'Phone', value: student.phone!),
          if (student.email != null)
            _DetailRow(label: 'Email', value: student.email!),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ─── Student Form ─────────────────────────────────────────────────────────────

class _StudentForm extends StatefulWidget {
  final Student? existing;
  final void Function(Student) onSave;

  const _StudentForm({this.existing, required this.onSave});

  @override
  State<_StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<_StudentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _roll, _class, _section,
      _parent, _phone, _email;
  late Gender _gender;
  late DateTime _dob;

  static const _classes = [
    'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5',
    'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10',
    'Grade 11', 'Grade 12',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name);
    _roll = TextEditingController(text: s?.rollNo);
    _class = TextEditingController(text: s?.className ?? 'Grade 10');
    _section = TextEditingController(text: s?.section ?? 'A');
    _parent = TextEditingController(text: s?.parentName);
    _phone = TextEditingController(text: s?.phone);
    _email = TextEditingController(text: s?.email);
    _gender = s?.gender ?? Gender.male;
    _dob = s?.dob ?? DateTime(2010, 1, 1);
  }

  @override
  void dispose() {
    for (final c in [_name, _roll, _class, _section, _parent, _phone, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(Student(
      id: widget.existing?.id,
      name: _name.text.trim(),
      rollNo: _roll.text.trim(),
      className: _class.text.trim(),
      section: _section.text.trim(),
      parentName: _parent.text.trim().isEmpty ? null : _parent.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      dob: _dob,
      gender: _gender,
      enrollmentDate: widget.existing?.enrollmentDate,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Form(
          key: _formKey,
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(isEdit ? 'Edit Student' : 'New Student',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              _field(_name, 'Full Name', Icons.person_outline,
                  required: true),
              _field(_roll, 'Roll Number', Icons.badge_outlined,
                  required: true),
              // Class dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  initialValue: _classes.contains(_class.text) ? _class.text : _classes[9],
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  items: _classes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => _class.text = v ?? _class.text,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              _field(_section, 'Section', Icons.grid_view_outlined),
              // Gender
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<Gender>(
                  key: ValueKey(_gender),
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  items: Gender.values
                      .map((g) => DropdownMenuItem(
                          value: g, child: Text(g.label)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _gender = v ?? Gender.male),
                ),
              ),
              // DOB
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _dob,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _dob = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    child: Text(DateFormat('MMM d, y').format(_dob)),
                  ),
                ),
              ),
              _field(_parent, 'Parent / Guardian Name', Icons.family_restroom),
              _field(_phone, 'Phone', Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              _field(_email, 'Email', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _submit,
                icon: Icon(isEdit ? Icons.save_outlined : Icons.add),
                label: Text(isEdit ? 'Save Changes' : 'Add Student'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        validator: required
            ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }
}
