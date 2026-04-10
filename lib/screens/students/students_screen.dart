import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
import '../../models/student_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _search = TextEditingController();
  String _query = '';

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
    _search.dispose();
    super.dispose();
  }

  void _showForm([Student? existing]) {
    final classes = context.read<ClassProvider>().classes;
    final firstCtrl = TextEditingController(text: existing?.firstName);
    final lastCtrl = TextEditingController(text: existing?.lastName);
    final rollCtrl = TextEditingController(text: existing?.rollNumber);
    final parentNameCtrl = TextEditingController(text: existing?.parentName ?? '');
    final parentPhoneCtrl = TextEditingController(text: existing?.parentPhone ?? '');
    String? selectedClass = existing?.classId;
    DateTime dob = existing?.dateOfBirth ?? DateTime(2010);

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
                Text(existing == null ? 'Add Student' : 'Edit Student',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                    controller: firstCtrl,
                    decoration:
                        const InputDecoration(labelText: 'First Name *')),
                const SizedBox(height: 12),
                TextField(
                    controller: lastCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Last Name *')),
                const SizedBox(height: 12),
                TextField(
                    controller: rollCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Roll Number *')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(selectedClass),
                  initialValue: selectedClass,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: classes
                      .map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.displayName)))
                      .toList(),
                  onChanged: (v) => setS(() => selectedClass = v),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date of Birth'),
                  subtitle: Text(
                      '${dob.day}/${dob.month}/${dob.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dob,
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setS(() => dob = picked);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: parentNameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Parent Name')),
                const SizedBox(height: 12),
                TextField(
                    controller: parentPhoneCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Parent Phone'),
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (firstCtrl.text.trim().isEmpty ||
                        lastCtrl.text.trim().isEmpty ||
                        rollCtrl.text.trim().isEmpty) {
                      return;
                    }
                    final data = {
                      'first_name': firstCtrl.text.trim(),
                      'last_name': lastCtrl.text.trim(),
                      'roll_number': rollCtrl.text.trim(),
                      'date_of_birth':
                          dob.toIso8601String().split('T')[0],
                      'admission_date': existing?.admissionDate
                              .toIso8601String()
                              .split('T')[0] ??
                          DateTime.now().toIso8601String().split('T')[0],
                      if (selectedClass != null) 'class_id': selectedClass,
                      if (parentNameCtrl.text.isNotEmpty)
                        'parent_name': parentNameCtrl.text.trim(),
                      if (parentPhoneCtrl.text.isNotEmpty)
                        'parent_phone': parentPhoneCtrl.text.trim(),
                    };
                    Navigator.pop(ctx);
                    if (existing == null) {
                      await context.read<StudentProvider>().create(data);
                    } else {
                      await context
                          .read<StudentProvider>()
                          .update(existing.id, data);
                    }
                  },
                  child: Text(
                      existing == null ? 'Add Student' : 'Save Changes'),
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
    final provider = context.watch<StudentProvider>();
    final role = context.watch<AuthProvider>().role;
    final isWide = MediaQuery.of(context).size.width >= 720;
    final canEdit = role == UserRole.admin || role == UserRole.teacher;

    final list =
        _query.isEmpty ? provider.students : provider.search(_query);

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
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(),
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
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: provider.loading
                ? const LoadingWidget()
                : list.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outline,
                        title: 'No students found',
                        onButton: canEdit ? () => _showForm() : null,
                        buttonLabel: 'Add Student',
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final s = list[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: AvatarWidget(
                                initials: s.initials,
                                radius: 22,
                              ),
                              title: Text(s.fullName),
                              subtitle: Text(
                                  'Roll: ${s.rollNumber}  •  Age: ${s.age}${s.gender != null ? '  •  ${s.gender}' : ''}'),
                              trailing: canEdit
                                  ? PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        if (v == 'edit') {
                                          _showForm(s);
                                        } else {
                                          final ok = await showConfirmDialog(
                                              context,
                                              title: 'Delete Student',
                                              message:
                                                  'Delete ${s.fullName}?');
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
