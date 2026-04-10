import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
import '../../models/academic_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeworkProvider>().load();
      context.read<ClassProvider>().loadAll();
    });
  }

  void _showForm([Homework? existing]) {
    final classProvider = context.read<ClassProvider>();
    final titleCtrl = TextEditingController(text: existing?.title);
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String? selClass = existing?.classId;
    String? selSubject = existing?.subjectId;
    DateTime dueDate = existing?.dueDate ?? DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(builder: (ctx, setS) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(existing == null ? 'Assign Homework' : 'Edit Homework',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title *')),
                const SizedBox(height: 12),
                TextField(
                    controller: descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Description'),
                    maxLines: 3),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(selClass),
                  initialValue: selClass,
                  decoration: const InputDecoration(labelText: 'Class *'),
                  items: classProvider.classes
                      .map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.displayName)))
                      .toList(),
                  onChanged: (v) => setS(() {
                    selClass = v;
                    selSubject = null;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(selSubject),
                  initialValue: selSubject,
                  decoration: const InputDecoration(labelText: 'Subject *'),
                  items: classProvider.subjects
                      .map((s) => DropdownMenuItem(
                          value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setS(() => selSubject = v),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due Date'),
                  subtitle: Text(
                      '${dueDate.day}/${dueDate.month}/${dueDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setS(() => dueDate = picked);
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty ||
                        selClass == null ||
                        selSubject == null) {
                      return;
                    }
                    final data = {
                      'title': titleCtrl.text.trim(),
                      if (descCtrl.text.isNotEmpty)
                        'description': descCtrl.text.trim(),
                      'class_id': selClass,
                      'subject_id': selSubject,
                      'assigned_date': DateTime.now()
                          .toIso8601String()
                          .split('T')[0],
                      'due_date':
                          dueDate.toIso8601String().split('T')[0],
                    };
                    Navigator.pop(ctx);
                    if (existing == null) {
                      await context.read<HomeworkProvider>().create(data);
                    } else {
                      await context
                          .read<HomeworkProvider>()
                          .update(existing.id, data);
                    }
                  },
                  child: Text(existing == null
                      ? 'Assign Homework'
                      : 'Save Changes'),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeworkProvider>();
    final classProvider = context.watch<ClassProvider>();
    final role = context.watch<AuthProvider>().role;
    final isWide = MediaQuery.of(context).size.width >= 720;
    final canEdit = role == UserRole.admin || role == UserRole.teacher;

    final list = _selectedClassId == null
        ? provider.homework
        : provider.homework
            .where((h) => h.classId == _selectedClassId)
            .toList();

    return Scaffold(
      appBar: AppBar(
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    ShellScreen.scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Text('Homework'),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add),
              label: const Text('Assign'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              key: ValueKey(_selectedClassId),
              initialValue: _selectedClassId,
              decoration:
                  const InputDecoration(labelText: 'Filter by Class'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('All Classes')),
                ...classProvider.classes.map((c) => DropdownMenuItem(
                    value: c.id, child: Text(c.displayName))),
              ],
              onChanged: (v) => setState(() => _selectedClassId = v),
            ),
          ),
          Expanded(
            child: provider.loading
                ? const LoadingWidget()
                : list.isEmpty
                    ? EmptyState(
                        icon: Icons.book_outlined,
                        title: 'No homework assigned',
                        onButton: canEdit ? () => _showForm() : null,
                        buttonLabel: 'Assign Homework',
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final h = list[i];
                          final subject =
                              classProvider.getSubjectById(h.subjectId);
                          final cls =
                              classProvider.getClassById(h.classId);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: h.isOverdue
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : Colors.blue.withValues(alpha: 0.15),
                                child: Icon(
                                  h.isOverdue
                                      ? Icons.warning
                                      : Icons.book,
                                  color: h.isOverdue
                                      ? Colors.red
                                      : Colors.blue,
                                ),
                              ),
                              title: Text(h.title),
                              subtitle: Text(
                                  '${subject?.name ?? 'Unknown'}  •  ${cls?.displayName ?? 'Unknown'}\nDue: ${h.dueDate.day}/${h.dueDate.month}/${h.dueDate.year}${h.isOverdue ? '  •  OVERDUE' : ''}'),
                              isThreeLine: true,
                              trailing: canEdit
                                  ? PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        if (v == 'edit') {
                                          _showForm(h);
                                        } else {
                                          final ok = await showConfirmDialog(
                                              context,
                                              title: 'Delete Homework',
                                              message:
                                                  'Delete "${h.title}"?');
                                          if (ok == true &&
                                              context.mounted) {
                                            await context
                                                .read<HomeworkProvider>()
                                                .delete(h.id);
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
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
