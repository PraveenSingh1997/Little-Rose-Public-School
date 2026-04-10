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
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _showCollectForm() {
    final provider = context.read<FeeProvider>();
    final amountCtrl = TextEditingController();
    final studentCtrl = TextEditingController();
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
                TextField(
                    controller: studentCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Student ID *')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(selStructure),
                  initialValue: selStructure,
                  decoration:
                      const InputDecoration(labelText: 'Fee Type'),
                  items: provider.structures
                      .map((s) => DropdownMenuItem(
                          value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setS(() => selStructure = v),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: amountCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Amount *'),
                    keyboardType: TextInputType.number),
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
                  ],
                  onChanged: (v) {
                    if (v != null) setS(() => selMethod = v);
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (studentCtrl.text.trim().isEmpty ||
                        amountCtrl.text.trim().isEmpty) {
                      return;
                    }
                    final data = {
                      'student_id': studentCtrl.text.trim(),
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
                    await context.read<FeeProvider>().collectFee(data);
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
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showCollectForm,
              icon: const Icon(Icons.payments),
              label: const Text('Collect Fee'),
            )
          : null,
      body: TabBarView(
        controller: _tab,
        children: [
          // Structures tab
          provider.loading
              ? const LoadingWidget()
              : provider.structures.isEmpty
                  ? const EmptyState(
                      icon: Icons.payments_outlined,
                      title: 'No fee structures',
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
                                '${s.feeType.label}  •  ${s.academicYear}'),
                            trailing: Text(
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
          // Payments tab
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
