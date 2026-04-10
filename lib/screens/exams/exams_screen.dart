import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
import '../../models/exam_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadAll();
      context.read<ExamProvider>().loadExams();
    });
  }

  void _showForm([Exam? existing]) {
    final classProvider = context.read<ClassProvider>();
    final nameCtrl = TextEditingController(text: existing?.name);
    final marksCtrl = TextEditingController(
        text: existing != null ? '${existing.totalMarks}' : '100');
    String? selClass = existing?.classId;
    String? selSubject = existing?.subjectId;
    ExamType selType = existing?.examType ?? ExamType.quiz;
    DateTime examDate = existing?.examDate ?? DateTime.now();

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
                Text(existing == null ? 'Schedule Exam' : 'Edit Exam',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Exam Name *')),
                const SizedBox(height: 12),
                DropdownButtonFormField<ExamType>(
                  key: ValueKey(selType),
                  initialValue: selType,
                  decoration: const InputDecoration(labelText: 'Exam Type'),
                  items: ExamType.values
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setS(() => selType = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(selClass),
                  initialValue: selClass,
                  decoration: const InputDecoration(labelText: 'Class *'),
                  items: classProvider.classes
                      .map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.displayName)))
                      .toList(),
                  onChanged: (v) {
                    setS(() {
                      selClass = v;
                      selSubject = null;
                    });
                    if (v != null) {
                      context.read<ClassProvider>().loadSubjectsForClass(v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Consumer<ClassProvider>(builder: (_, cp, __) {
                  final subs = selClass != null && cp.classSubjects.isNotEmpty
                      ? cp.classSubjects
                      : cp.subjects;
                  return DropdownButtonFormField<String>(
                    key: ValueKey('$selClass-$selSubject'),
                    initialValue: selSubject,
                    decoration: const InputDecoration(labelText: 'Subject *'),
                    items: subs
                        .map((s) => DropdownMenuItem(
                            value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) => setS(() => selSubject = v),
                  );
                }),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Exam Date'),
                  subtitle: Text(
                      '${examDate.day}/${examDate.month}/${examDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: examDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setS(() => examDate = picked);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: marksCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Total Marks'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty ||
                        selClass == null ||
                        selSubject == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Exam name, class and subject are required'),
                        behavior: SnackBarBehavior.floating,
                      ));
                      return;
                    }
                    final data = {
                      'name': nameCtrl.text.trim(),
                      'exam_type': selType.value,
                      'class_id': selClass,
                      'subject_id': selSubject,
                      'exam_date':
                          examDate.toIso8601String().split('T')[0],
                      'total_marks':
                          double.tryParse(marksCtrl.text.trim()) ?? 100,
                    };
                    Navigator.pop(ctx);
                    try {
                      if (existing == null) {
                        await context.read<ExamProvider>().createExam(data);
                      } else {
                        await context
                            .read<ExamProvider>()
                            .updateExam(existing.id, data);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error saving exam: $e'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    }
                  },
                  child: Text(
                      existing == null ? 'Schedule Exam' : 'Save Changes'),
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
    final provider = context.watch<ExamProvider>();
    final classProvider = context.watch<ClassProvider>();
    final role = context.watch<AuthProvider>().role;
    final isWide = MediaQuery.of(context).size.width >= 720;
    final canEdit = role == UserRole.admin || role == UserRole.teacher;

    final list = _selectedClassId == null
        ? provider.exams
        : provider.exams
            .where((e) => e.classId == _selectedClassId)
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
        title: const Text('Exams'),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add),
              label: const Text('Schedule Exam'),
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
                const DropdownMenuItem(value: null, child: Text('All Classes')),
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
                        icon: Icons.assignment_outlined,
                        title: 'No exams scheduled',
                        onButton: canEdit ? () => _showForm() : null,
                        buttonLabel: 'Schedule Exam',
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final e = list[i];
                          final subject =
                              classProvider.getSubjectById(e.subjectId);
                          final cls =
                              classProvider.getClassById(e.classId);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(e.examType.label
                                    .substring(0, 1)),
                              ),
                              title: Text(e.name),
                              subtitle: Text(
                                  '${subject?.name ?? 'Unknown'}  •  ${cls?.displayName ?? 'Unknown'}\n${e.examDate.day}/${e.examDate.month}/${e.examDate.year}  •  ${e.totalMarks} marks'),
                              trailing: canEdit
                                  ? PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        if (v == 'edit') {
                                          _showForm(e);
                                        } else {
                                          final ok = await showConfirmDialog(
                                              context,
                                              title: 'Delete Exam',
                                              message:
                                                  'Delete ${e.name}?');
                                          if (ok == true &&
                                              context.mounted) {
                                            await context
                                                .read<ExamProvider>()
                                                .deleteExam(e.id);
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
