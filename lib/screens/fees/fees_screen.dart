import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
import '../../models/finance_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeeProvider>().loadStructures();
      context.read<FeeProvider>().loadPayments();
      context.read<StudentProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Add / Edit Fee Structure ─────────────────────────────────────────────────
  void _showStructureForm([FeeStructure? existing]) {
    final classProvider = context.read<ClassProvider>();
    if (classProvider.classes.isEmpty) classProvider.loadAll();

    final nameCtrl = TextEditingController(text: existing?.name);
    final amountCtrl = TextEditingController(
        text: existing != null ? existing.amount.toStringAsFixed(0) : '');
    final yearCtrl = TextEditingController(
        text: existing?.academicYear ?? '2024-25');
    FeeType selType = existing?.feeType ?? FeeType.tuition;
    String selFreq = existing?.frequency ?? 'monthly';
    String? selClass = existing?.classId;

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
                Text(
                  existing == null ? 'Add Fee Structure' : 'Edit Fee Structure',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Structure Name *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FeeType>(
                  key: ValueKey(selType),
                  initialValue: selType,
                  decoration: const InputDecoration(labelText: 'Fee Type *'),
                  items: FeeType.values
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setS(() => selType = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: 'Amount (₹) *'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(selFreq),
                  initialValue: selFreq,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: const [
                    DropdownMenuItem(
                        value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(
                        value: 'quarterly', child: Text('Quarterly')),
                    DropdownMenuItem(
                        value: 'annually', child: Text('Annually')),
                    DropdownMenuItem(
                        value: 'one_time', child: Text('One Time')),
                  ],
                  onChanged: (v) {
                    if (v != null) setS(() => selFreq = v);
                  },
                ),
                const SizedBox(height: 12),
                Consumer<ClassProvider>(builder: (_, cp, __) {
                  return DropdownButtonFormField<String>(
                    key: ValueKey(selClass),
                    initialValue: selClass,
                    decoration: const InputDecoration(
                        labelText: 'Class (leave blank for all)'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Classes')),
                      ...cp.classes.map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.displayName))),
                    ],
                    onChanged: (v) => setS(() => selClass = v),
                  );
                }),
                const SizedBox(height: 12),
                TextField(
                  controller: yearCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Academic Year'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty ||
                        amountCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Structure name and amount are required'),
                        behavior: SnackBarBehavior.floating,
                      ));
                      return;
                    }
                    final data = {
                      'name': nameCtrl.text.trim(),
                      'fee_type': selType.value,
                      'amount':
                          double.tryParse(amountCtrl.text.trim()) ?? 0,
                      'frequency': selFreq,
                      'academic_year': yearCtrl.text.trim().isEmpty
                          ? '2024-25'
                          : yearCtrl.text.trim(),
                      if (selClass != null) 'class_id': selClass,
                    };
                    Navigator.pop(ctx);
                    try {
                      if (existing == null) {
                        await context.read<FeeProvider>().createStructure(data);
                      } else {
                        await context
                            .read<FeeProvider>()
                            .updateStructure(existing.id, data);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error saving fee structure: $e'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    }
                  },
                  child: Text(existing == null
                      ? 'Add Structure'
                      : 'Save Changes'),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Collect Fee ───────────────────────────────────────────────────────────────
  void _showCollectForm() {
    final feeProvider = context.read<FeeProvider>();
    final students = context.read<StudentProvider>().students;

    final amountCtrl = TextEditingController();
    String? selStudent;
    String? selStructure;
    String selMethod = 'cash';

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
                Text('Collect Fee',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                // Student picker
                DropdownButtonFormField<String>(
                  key: ValueKey(selStudent),
                  initialValue: selStudent,
                  decoration:
                      const InputDecoration(labelText: 'Student *'),
                  items: students
                      .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                              '${s.fullName} (${s.rollNumber})')))
                      .toList(),
                  onChanged: (v) => setS(() => selStudent = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(selStructure),
                  initialValue: selStructure,
                  decoration:
                      const InputDecoration(labelText: 'Fee Type'),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('— Select fee type —')),
                    ...feeProvider.structures.map((s) => DropdownMenuItem(
                        value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (v) {
                    setS(() => selStructure = v);
                    if (v != null) {
                      final struct = feeProvider.structures
                          .where((s) => s.id == v)
                          .firstOrNull;
                      if (struct != null) {
                        amountCtrl.text =
                            struct.amount.toStringAsFixed(0);
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Amount (₹) *'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(selMethod),
                  initialValue: selMethod,
                  decoration:
                      const InputDecoration(labelText: 'Payment Method'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(
                        value: 'online', child: Text('Online')),
                    DropdownMenuItem(
                        value: 'cheque', child: Text('Cheque')),
                    DropdownMenuItem(
                        value: 'card', child: Text('Card')),
                  ],
                  onChanged: (v) {
                    if (v != null) setS(() => selMethod = v);
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (selStudent == null ||
                        amountCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Student and amount are required'),
                        behavior: SnackBarBehavior.floating,
                      ));
                      return;
                    }
                    final data = {
                      'student_id': selStudent,
                      if (selStructure != null)
                        'fee_structure_id': selStructure,
                      'amount_paid':
                          double.tryParse(amountCtrl.text.trim()) ?? 0,
                      'payment_method': selMethod,
                      'payment_date': DateTime.now()
                          .toIso8601String()
                          .split('T')[0],
                      'status': 'paid',
                    };
                    Navigator.pop(ctx);
                    try {
                      await context.read<FeeProvider>().collectFee(data);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error collecting fee: $e'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    }
                  },
                  child: const Text('Collect Payment'),
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
    final provider = context.watch<FeeProvider>();
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
        title: const Text('Fee Management'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Structures'), Tab(text: 'Payments')],
        ),
        actions: [
          if (isAdmin)
            TextButton.icon(
              onPressed: _showCollectForm,
              icon: const Icon(Icons.payments),
              label: const Text('Collect'),
            ),
        ],
      ),
      floatingActionButton: isAdmin && _tab.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showStructureForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Structure'),
            )
          : null,
      body: TabBarView(
        controller: _tab,
        children: [
          // ── Structures tab ──────────────────────────────────────────────────
          provider.loading
              ? const LoadingWidget()
              : provider.error != null
                  ? AppErrorWidget(
                      message:
                          'Failed to load structures.\n${provider.error}',
                      onRetry: () =>
                          context.read<FeeProvider>().loadStructures(),
                    )
                  : provider.structures.isEmpty
                      ? EmptyState(
                          icon: Icons.payments_outlined,
                          title: 'No fee structures',
                          onButton:
                              isAdmin ? () => _showStructureForm() : null,
                          buttonLabel: 'Add Structure',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.structures.length,
                          itemBuilder: (ctx, i) {
                            final s = provider.structures[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                    child: Icon(Icons.payments)),
                                title: Text(s.name),
                                subtitle: Text(
                                    '${s.feeType.label}  •  ${s.frequency}  •  ${s.academicYear}'),
                                trailing: isAdmin
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '₹${s.amount.toStringAsFixed(0)}',
                                            style: Theme.of(ctx)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold),
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (v) async {
                                              if (v == 'edit') {
                                                _showStructureForm(s);
                                              } else {
                                                final ok =
                                                    await showConfirmDialog(
                                                        context,
                                                        title:
                                                            'Delete Structure',
                                                        message:
                                                            'Delete "${s.name}"?');
                                                if (ok == true &&
                                                    context.mounted) {
                                                  await context
                                                      .read<FeeProvider>()
                                                      .deleteStructure(
                                                          s.id);
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
                                          ),
                                        ],
                                      )
                                    : Text(
                                        '₹${s.amount.toStringAsFixed(0)}',
                                        style: Theme.of(ctx)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                              ),
                            );
                          },
                        ),

          // ── Payments tab ────────────────────────────────────────────────────
          provider.loading
              ? const LoadingWidget()
              : provider.payments.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_outlined,
                      title: 'No payments recorded',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.payments.length,
                      itemBuilder: (ctx, i) {
                        final p = provider.payments[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: p.status == 'paid'
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.red.withValues(alpha: 0.15),
                              child: Icon(
                                p.status == 'paid'
                                    ? Icons.check
                                    : Icons.pending,
                                color: p.status == 'paid'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            title: Text(
                                'Receipt #${p.receiptNumber ?? p.id.substring(0, 8)}'),
                            subtitle: Text(
                                '${p.paymentDate.day}/${p.paymentDate.month}/${p.paymentDate.year}  •  ${p.paymentMethod.label}'),
                            trailing: Text(
                              '₹${p.amountPaid.toStringAsFixed(0)}',
                              style: Theme.of(ctx)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
