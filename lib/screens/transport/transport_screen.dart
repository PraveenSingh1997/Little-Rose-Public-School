import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
import '../../models/misc_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransportProvider>().load();
    });
  }

  void _showForm([BusRoute? existing]) {
    final nameCtrl = TextEditingController(text: existing?.routeName);
    final numCtrl = TextEditingController(text: existing?.routeNumber);
    final driverCtrl = TextEditingController(text: existing?.driverName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.driverPhone ?? '');
    final vehicleCtrl =
        TextEditingController(text: existing?.vehicleNumber ?? '');
    final feeCtrl = TextEditingController(
        text: existing != null ? '${existing.monthlyFee}' : '0');

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
              Text(existing == null ? 'Add Route' : 'Edit Route',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Route Name *')),
              const SizedBox(height: 12),
              TextField(
                  controller: numCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Route Number *')),
              const SizedBox(height: 12),
              TextField(
                  controller: driverCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Driver Name')),
              const SizedBox(height: 12),
              TextField(
                  controller: phoneCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Driver Phone'),
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(
                  controller: vehicleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Vehicle Number')),
              const SizedBox(height: 12),
              TextField(
                  controller: feeCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Monthly Fee (₹)'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty ||
                      numCtrl.text.trim().isEmpty) {
                    return;
                  }
                  final data = {
                    'route_name': nameCtrl.text.trim(),
                    'route_number': numCtrl.text.trim(),
                    if (driverCtrl.text.isNotEmpty)
                      'driver_name': driverCtrl.text.trim(),
                    if (phoneCtrl.text.isNotEmpty)
                      'driver_phone': phoneCtrl.text.trim(),
                    if (vehicleCtrl.text.isNotEmpty)
                      'vehicle_number': vehicleCtrl.text.trim(),
                    'monthly_fee':
                        double.tryParse(feeCtrl.text.trim()) ?? 0,
                  };
                  Navigator.pop(ctx);
                  if (existing == null) {
                    await context.read<TransportProvider>().create(data);
                  } else {
                    await context
                        .read<TransportProvider>()
                        .update(existing.id, data);
                  }
                },
                child: Text(
                    existing == null ? 'Add Route' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransportProvider>();
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
        title: const Text('Transport'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Route'),
            )
          : null,
      body: provider.loading
          ? const LoadingWidget()
          : provider.routes.isEmpty
              ? EmptyState(
                  icon: Icons.directions_bus_outlined,
                  title: 'No bus routes',
                  onButton: isAdmin ? () => _showForm() : null,
                  buttonLabel: 'Add Route',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.routes.length,
                  itemBuilder: (ctx, i) {
                    final r = provider.routes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(r.routeNumber),
                        ),
                        title: Text(r.routeName),
                        subtitle: Text(
                            '${r.driverName ?? 'No driver'}${r.vehicleNumber != null ? '  •  ${r.vehicleNumber}' : ''}'
                            '\nCapacity: ${r.capacity}  •  ₹${r.monthlyFee.toStringAsFixed(0)}/mo'),
                        isThreeLine: true,
                        trailing: isAdmin
                            ? PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'edit') {
                                    _showForm(r);
                                  } else {
                                    final ok = await showConfirmDialog(
                                        context,
                                        title: 'Delete Route',
                                        message:
                                            'Delete ${r.routeName}?');
                                    if (ok == true && context.mounted) {
                                      await context
                                          .read<TransportProvider>()
                                          .delete(r.id);
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
    );
  }
}
