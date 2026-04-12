import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
import '../../models/academic_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadAll();
    });
  }

  void _showForm([SchoolClass? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final sectionCtrl =
        TextEditingController(text: existing?.section ?? 'A');
    final gradeCtrl = TextEditingController(
        text: existing != null ? '${existing.gradeLevel}' : '');
    final roomCtrl =
        TextEditingController(text: existing?.roomNumber ?? '');
    final yearCtrl = TextEditingController(
        text: existing?.academicYear ?? '2024-25');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(existing == null ? 'Add Class' : 'Edit Class',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Class Name *')),
            const SizedBox(height: 12),
            TextField(
                controller: sectionCtrl,
                decoration: const InputDecoration(labelText: 'Section *')),
            const SizedBox(height: 12),
            TextField(
                controller: gradeCtrl,
                decoration: const InputDecoration(labelText: 'Grade Level *'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(labelText: 'Room Number')),
            const SizedBox(height: 12),
            TextField(
                controller: yearCtrl,
                decoration:
                    const InputDecoration(labelText: 'Academic Year')),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    gradeCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Class name and grade level are required'),
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                final data = {
                  'name': nameCtrl.text.trim(),
                  'section': sectionCtrl.text.trim().isEmpty
                      ? 'A'
                      : sectionCtrl.text.trim(),
                  'grade_level':
                      int.tryParse(gradeCtrl.text.trim()) ?? 1,
                  if (roomCtrl.text.isNotEmpty)
                    'room_number': roomCtrl.text.trim(),
                  'academic_year': yearCtrl.text.trim().isEmpty
                      ? '2024-25'
                      : yearCtrl.text.trim(),
                };
                Navigator.pop(ctx);
                try {
                  if (existing == null) {
                    await context.read<ClassProvider>().createClass(data);
                  } else {
                    await context
                        .read<ClassProvider>()
                        .updateClass(existing.id, data);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error saving class: $e'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
              child:
                  Text(existing == null ? 'Add Class' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClassProvider>();
    final role = context.watch<AuthProvider>().role;
    final isWide = MediaQuery.of(context).size.width >= 720;
    final isAdmin = role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    ShellScreen.scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Text('Classes'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Class'),
            )
          : null,
      body: provider.loading
          ? const LoadingWidget()
          : provider.classes.isEmpty
              ? EmptyState(
                  icon: Icons.class_outlined,
                  title: 'No classes found',
                  onButton: isAdmin ? () => _showForm() : null,
                  buttonLabel: 'Add Class',
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<ClassProvider>().loadAll(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.classes.length,
                    itemBuilder: (ctx, i) {
                      final c = provider.classes[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${c.gradeLevel}'),
                          ),
                          title: Text(c.displayName),
                          subtitle: Text(
                              'Capacity: ${c.capacity}${c.roomNumber != null ? '  •  Room: ${c.roomNumber}' : ''}  •  ${c.academicYear}'),
                          trailing: isAdmin
                              ? PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'edit') {
                                      _showForm(c);
                                    } else {
                                      final ok = await showConfirmDialog(
                                          context,
                                          title: 'Delete Class',
                                          message:
                                              'Delete ${c.displayName}?');
                                      if (ok == true && context.mounted) {
                                        await context
                                            .read<ClassProvider>()
                                            .deleteClass(c.id);
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                        value: 'edit', child: Text('Edit')),
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
    );
  }
}
