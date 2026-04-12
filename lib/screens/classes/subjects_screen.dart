import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
import '../../models/academic_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadAll();
    });
  }

  void _showForm([Subject? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final codeCtrl = TextEditingController(text: existing?.code);
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final hoursCtrl = TextEditingController(
        text: existing != null ? '${existing.creditHours}' : '3');

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
            Text(existing == null ? 'Add Subject' : 'Edit Subject',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Subject Name *')),
            const SizedBox(height: 12),
            TextField(
                controller: codeCtrl,
                decoration:
                    const InputDecoration(labelText: 'Subject Code *')),
            const SizedBox(height: 12),
            TextField(
                controller: descCtrl,
                decoration:
                    const InputDecoration(labelText: 'Description'),
                maxLines: 2),
            const SizedBox(height: 12),
            TextField(
                controller: hoursCtrl,
                decoration:
                    const InputDecoration(labelText: 'Credit Hours'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    codeCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Subject name and code are required'),
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                final data = {
                  'name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim(),
                  if (descCtrl.text.isNotEmpty)
                    'description': descCtrl.text.trim(),
                  'credit_hours':
                      int.tryParse(hoursCtrl.text.trim()) ?? 3,
                };
                Navigator.pop(ctx);
                try {
                  if (existing == null) {
                    await context.read<ClassProvider>().createSubject(data);
                  } else {
                    await context
                        .read<ClassProvider>()
                        .updateSubject(existing.id, data);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error saving subject: $e'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
              child: Text(
                  existing == null ? 'Add Subject' : 'Save Changes'),
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
        title: const Text('Subjects'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Subject'),
            )
          : null,
      body: provider.loading
          ? const LoadingWidget()
          : provider.subjects.isEmpty
              ? EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No subjects found',
                  onButton: isAdmin ? () => _showForm() : null,
                  buttonLabel: 'Add Subject',
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<ClassProvider>().loadAll(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.subjects.length,
                    itemBuilder: (ctx, i) {
                      final s = provider.subjects[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(s.code.substring(
                                0,
                                s.code.length > 2
                                    ? 2
                                    : s.code.length)),
                          ),
                          title: Text(s.name),
                          subtitle: Text(
                              'Code: ${s.code}  •  ${s.creditHours} credit hrs${s.description != null ? '\n${s.description}' : ''}'),
                          trailing: isAdmin
                              ? PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'edit') {
                                      _showForm(s);
                                    } else {
                                      final ok = await showConfirmDialog(
                                          context,
                                          title: 'Delete Subject',
                                          message: 'Delete ${s.name}?');
                                      if (ok == true && context.mounted) {
                                        await context
                                            .read<ClassProvider>()
                                            .deleteSubject(s.id);
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
