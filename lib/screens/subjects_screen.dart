import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _store = StorageService();
  String _search = '';
  String _classFilter = 'All';

  List<String> get _classes {
    final c = _store.subjects.map((s) => s.className).toSet().toList()..sort();
    return ['All', ...c];
  }

  List<Subject> get _filtered {
    return _store.subjects.where((s) {
      final matchSearch = _search.isEmpty ||
          s.name.toLowerCase().contains(_search.toLowerCase()) ||
          s.code.toLowerCase().contains(_search.toLowerCase());
      final matchClass = _classFilter == 'All' || s.className == _classFilter;
      return matchSearch && matchClass;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _openForm({Subject? subject}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SubjectForm(
        existing: subject,
        store: _store,
        onSave: (s) {
          setState(() {
            if (subject != null) {
              final i = _store.subjects.indexWhere((x) => x.id == s.id);
              if (i != -1) _store.subjects[i] = s;
            } else {
              _store.subjects.add(s);
            }
          });
          _store.saveSubjects();
        },
      ),
    );
  }

  void _delete(Subject s) {
    setState(() => _store.subjects.remove(s));
    _store.saveSubjects();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${s.name} deleted'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          setState(() => _store.subjects.add(s));
          _store.saveSubjects();
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
            title: const Text('Subjects'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    SearchBar(
                      hintText: 'Search by name or code…',
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
                          return FilterChip(
                            label: Text(c),
                            selected: _classFilter == c,
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
                    Icon(Icons.menu_book_outlined,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('No subjects found',
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
                  final teacher = _store.teachers
                      .where((t) => t.id == s.teacherId)
                      .firstOrNull;
                  return _SubjectCard(
                    subject: s,
                    teacherName: teacher?.name,
                    onEdit: () => _openForm(subject: s),
                    onDelete: () => _delete(s),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final String? teacherName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.subject,
    required this.teacherName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.tertiaryContainer,
          child: Icon(Icons.menu_book, color: cs.onTertiaryContainer, size: 20),
        ),
        title: Text(subject.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${subject.code} · ${subject.className} · ${subject.creditHours} hrs'
            '${teacherName != null ? '\n$teacherName' : ''}'),
        isThreeLine: teacherName != null,
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

// ─── Subject Form ─────────────────────────────────────────────────────────────

class _SubjectForm extends StatefulWidget {
  final Subject? existing;
  final StorageService store;
  final void Function(Subject) onSave;
  const _SubjectForm(
      {this.existing, required this.store, required this.onSave});

  @override
  State<_SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends State<_SubjectForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _code;
  late String _className;
  String? _teacherId;
  late int _creditHours;

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
    _code = TextEditingController(text: s?.code);
    _className = s?.className ?? 'Grade 10';
    _teacherId = s?.teacherId;
    _creditHours = s?.creditHours ?? 3;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(Subject(
      id: widget.existing?.id,
      name: _name.text.trim(),
      code: _code.text.trim(),
      className: _className,
      teacherId: _teacherId,
      creditHours: _creditHours,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final cs = Theme.of(context).colorScheme;
    final teachers = widget.store.teachers.where((t) => t.isActive).toList();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
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
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(isEdit ? 'Edit Subject' : 'New Subject',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Subject Code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              // Class
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_className),
                  initialValue: _classes.contains(_className) ? _className : _classes[9],
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  items: _classes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _className = v ?? _className),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              // Teacher
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_teacherId),
                  initialValue: _teacherId,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Teacher (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...teachers.map((t) => DropdownMenuItem(
                        value: t.id, child: Text(t.name))),
                  ],
                  onChanged: (v) => setState(() => _teacherId = v),
                ),
              ),
              // Credit hours
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    const Text('Credit Hours:'),
                    const SizedBox(width: 16),
                    ...List.generate(
                      5,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${i + 1}'),
                          selected: _creditHours == i + 1,
                          onSelected: (_) =>
                              setState(() => _creditHours = i + 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _submit,
                icon: Icon(isEdit ? Icons.save_outlined : Icons.add),
                label: Text(isEdit ? 'Save Changes' : 'Add Subject'),
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
