import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final _store = StorageService();
  String _search = '';

  List<Teacher> get _filtered {
    return _store.teachers.where((t) {
      return t.isActive &&
          (_search.isEmpty ||
              t.name.toLowerCase().contains(_search.toLowerCase()) ||
              t.subjectSpecialization
                  .toLowerCase()
                  .contains(_search.toLowerCase()));
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _openForm({Teacher? teacher}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TeacherForm(
        existing: teacher,
        onSave: (t) {
          setState(() {
            if (teacher != null) {
              final i = _store.teachers.indexWhere((x) => x.id == t.id);
              if (i != -1) _store.teachers[i] = t;
            } else {
              _store.teachers.add(t);
            }
          });
          _store.saveTeachers();
        },
      ),
    );
  }

  void _delete(Teacher t) {
    setState(() => t.isActive = false);
    _store.saveTeachers();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${t.name} removed'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          setState(() => t.isActive = true);
          _store.saveTeachers();
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
            title: const Text('Teachers'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SearchBar(
                  hintText: 'Search by name or subject…',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => _search = v),
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
                    Icon(Icons.school_outlined,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('No teachers found',
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
                  final t = _filtered[i];
                  return _TeacherCard(
                    teacher: t,
                    store: _store,
                    onEdit: () => _openForm(teacher: t),
                    onDelete: () => _delete(t),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Teacher'),
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final StorageService store;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeacherCard({
    required this.teacher,
    required this.store,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = teacher.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join();
    final subjectCount = store.subjects
        .where((s) => s.teacherId == teacher.id)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: cs.secondaryContainer,
          child: Text(initials,
              style: TextStyle(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.bold)),
        ),
        title: Text(teacher.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(teacher.subjectSpecialization),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _Row(Icons.email_outlined, teacher.email),
                _Row(Icons.phone_outlined, teacher.phone),
                _Row(Icons.school_outlined, teacher.qualification),
                _Row(Icons.calendar_today_outlined,
                    'Joined ${DateFormat('MMM y').format(teacher.joiningDate)}'),
                _Row(Icons.menu_book_outlined,
                    '$subjectCount subject(s) assigned'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Row(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

// ─── Teacher Form ─────────────────────────────────────────────────────────────

class _TeacherForm extends StatefulWidget {
  final Teacher? existing;
  final void Function(Teacher) onSave;
  const _TeacherForm({this.existing, required this.onSave});

  @override
  State<_TeacherForm> createState() => _TeacherFormState();
}

class _TeacherFormState extends State<_TeacherForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _email, _phone, _qual, _spec;
  late DateTime _joining;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _name = TextEditingController(text: t?.name);
    _email = TextEditingController(text: t?.email);
    _phone = TextEditingController(text: t?.phone);
    _qual = TextEditingController(text: t?.qualification);
    _spec = TextEditingController(text: t?.subjectSpecialization);
    _joining = t?.joiningDate ?? DateTime.now();
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _qual, _spec]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(Teacher(
      id: widget.existing?.id,
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      qualification: _qual.text.trim(),
      subjectSpecialization: _spec.text.trim(),
      joiningDate: _joining,
    ));
    Navigator.pop(context);
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {bool required = false,
      TextInputType keyboardType = TextInputType.text}) {
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
        validator:
            required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Form(
          key: _formKey,
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
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
              Text(isEdit ? 'Edit Teacher' : 'New Teacher',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              _field(_name, 'Full Name', Icons.person_outline, required: true),
              _field(_email, 'Email', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              _field(_phone, 'Phone', Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              _field(_qual, 'Qualification', Icons.workspace_premium_outlined,
                  required: true),
              _field(_spec, 'Subject Specialization', Icons.menu_book_outlined,
                  required: true),
              // Joining date
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _joining,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _joining = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Joining Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(DateFormat('MMM d, y').format(_joining)),
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _submit,
                icon: Icon(isEdit ? Icons.save_outlined : Icons.add),
                label: Text(isEdit ? 'Save Changes' : 'Add Teacher'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
