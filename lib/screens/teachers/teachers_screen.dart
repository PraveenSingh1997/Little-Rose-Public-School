import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
import '../../models/teacher_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeacherProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showForm([Teacher? existing]) {
    final firstCtrl = TextEditingController(text: existing?.firstName);
    final lastCtrl = TextEditingController(text: existing?.lastName);
    final empCtrl = TextEditingController(text: existing?.employeeId);
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final qualCtrl = TextEditingController(text: existing?.qualification ?? '');
    final specCtrl = TextEditingController(text: existing?.specialization ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(existing == null ? 'Add Teacher' : 'Edit Teacher',
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
                  controller: empCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Employee ID *')),
              const SizedBox(height: 12),
              TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(
                  controller: qualCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Qualification')),
              const SizedBox(height: 12),
              TextField(
                  controller: specCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Specialization')),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  if (firstCtrl.text.trim().isEmpty ||
                      lastCtrl.text.trim().isEmpty ||
                      empCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('First name, last name and employee ID are required'),
                      behavior: SnackBarBehavior.floating,
                    ));
                    return;
                  }
                  final data = {
                    'first_name': firstCtrl.text.trim(),
                    'last_name': lastCtrl.text.trim(),
                    'employee_id': empCtrl.text.trim(),
                    'joining_date': existing?.joiningDate
                            .toIso8601String()
                            .split('T')[0] ??
                        DateTime.now().toIso8601String().split('T')[0],
                    if (emailCtrl.text.isNotEmpty)
                      'email': emailCtrl.text.trim(),
                    if (phoneCtrl.text.isNotEmpty)
                      'phone': phoneCtrl.text.trim(),
                    if (qualCtrl.text.isNotEmpty)
                      'qualification': qualCtrl.text.trim(),
                    if (specCtrl.text.isNotEmpty)
                      'specialization': specCtrl.text.trim(),
                  };
                  Navigator.pop(ctx);
                  try {
                    if (existing == null) {
                      await context.read<TeacherProvider>().create(data);
                    } else {
                      await context
                          .read<TeacherProvider>()
                          .update(existing.id, data);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error saving teacher: $e'),
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  }
                },
                child: Text(
                    existing == null ? 'Add Teacher' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeacherProvider>();
    final role = context.watch<AuthProvider>().role;
    final isWide = MediaQuery.of(context).size.width >= 720;
    final isAdmin = role == UserRole.admin;

    final list = _query.isEmpty
        ? provider.teachers
        : provider.teachers
            .where((t) =>
                t.fullName.toLowerCase().contains(_query.toLowerCase()) ||
                t.employeeId.toLowerCase().contains(_query.toLowerCase()))
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
        title: const Text('Teachers'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Teacher'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search by name or employee ID…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: provider.loading
                ? const LoadingWidget()
                : provider.error != null
                    ? AppErrorWidget(
                        message: 'Failed to load teachers.\n${provider.error}',
                        onRetry: () => context.read<TeacherProvider>().loadAll(),
                      )
                    : list.isEmpty
                    ? EmptyState(
                        icon: Icons.school_outlined,
                        title: 'No teachers found',
                        onButton: isAdmin ? () => _showForm() : null,
                        buttonLabel: 'Add Teacher',
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            context.read<TeacherProvider>().loadAll(),
                        child: ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final t = list[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: AvatarWidget(
                                initials: t.initials,
                                radius: 22,
                              ),
                              title: Text(t.fullName),
                              subtitle: Text(
                                  'ID: ${t.employeeId}${t.specialization != null ? '  •  ${t.specialization}' : ''}'),
                              trailing: isAdmin
                                  ? PopupMenuButton<String>(
                                      onSelected: (v) async {
                                        if (v == 'edit') {
                                          _showForm(t);
                                        } else {
                                          final ok = await showConfirmDialog(
                                              context,
                                              title: 'Delete Teacher',
                                              message:
                                                  'Delete ${t.fullName}?');
                                          if (ok == true &&
                                              context.mounted) {
                                            await context
                                                .read<TeacherProvider>()
                                                .delete(t.id);
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
          ),
        ],
      ),
    );
  }
}
