import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
import '../../models/misc_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class HostelScreen extends StatefulWidget {
  const HostelScreen({super.key});

  @override
  State<HostelScreen> createState() => _HostelScreenState();
}

class _HostelScreenState extends State<HostelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HostelProvider>().load();
    });
  }

  void _showForm([HostelRoom? existing]) {
    final roomCtrl = TextEditingController(text: existing?.roomNumber);
    final floorCtrl = TextEditingController(
        text: existing != null ? '${existing.floor}' : '1');
    final capCtrl = TextEditingController(
        text: existing != null ? '${existing.capacity}' : '2');
    final feeCtrl = TextEditingController(
        text: existing != null ? '${existing.monthlyFee}' : '0');
    String selType = existing?.roomType ?? 'shared';

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
                Text(existing == null ? 'Add Room' : 'Edit Room',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                    controller: roomCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Room Number *')),
                const SizedBox(height: 12),
                TextField(
                    controller: floorCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Floor'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(
                    controller: capCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Capacity'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(selType),
                  initialValue: selType,
                  decoration:
                      const InputDecoration(labelText: 'Room Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'shared', child: Text('Shared')),
                    DropdownMenuItem(
                        value: 'single', child: Text('Single')),
                    DropdownMenuItem(
                        value: 'double', child: Text('Double')),
                  ],
                  onChanged: (v) {
                    if (v != null) setS(() => selType = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: feeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Monthly Fee (₹)'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (roomCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Room number is required'),
                        behavior: SnackBarBehavior.floating,
                      ));
                      return;
                    }
                    final data = {
                      'room_number': roomCtrl.text.trim(),
                      'floor': int.tryParse(floorCtrl.text.trim()) ?? 1,
                      'capacity':
                          int.tryParse(capCtrl.text.trim()) ?? 2,
                      'room_type': selType,
                      'monthly_fee':
                          double.tryParse(feeCtrl.text.trim()) ?? 0,
                    };
                    Navigator.pop(ctx);
                    try {
                      if (existing == null) {
                        await context.read<HostelProvider>().create(data);
                      } else {
                        await context
                            .read<HostelProvider>()
                            .update(existing.id, data);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error saving room: $e'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    }
                  },
                  child: Text(
                      existing == null ? 'Add Room' : 'Save Changes'),
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
    final provider = context.watch<HostelProvider>();
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
        title: const Text('Hostel'),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Room'),
            )
          : null,
      body: provider.loading
          ? const LoadingWidget()
          : provider.error != null
              ? AppErrorWidget(
                  message: 'Failed to load hostel rooms.\n${provider.error}',
                  onRetry: () => context.read<HostelProvider>().load(),
                )
              : provider.rooms.isEmpty
              ? EmptyState(
                  icon: Icons.hotel_outlined,
                  title: 'No hostel rooms',
                  onButton: isAdmin ? () => _showForm() : null,
                  buttonLabel: 'Add Room',
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<HostelProvider>().load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.rooms.length,
                    itemBuilder: (ctx, i) {
                      final r = provider.rooms[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: r.isFull
                                ? Colors.red.withValues(alpha: 0.15)
                                : Colors.green.withValues(alpha: 0.15),
                            child: Icon(
                              r.isFull ? Icons.hotel : Icons.hotel_outlined,
                              color: r.isFull ? Colors.red : Colors.green,
                            ),
                          ),
                          title: Text('Room ${r.roomNumber}'),
                          subtitle: Text(
                              'Floor ${r.floor}  •  ${r.roomType}  •  ${r.occupied}/${r.capacity} occupied\n₹${r.monthlyFee.toStringAsFixed(0)}/month'),
                          isThreeLine: true,
                          trailing: isAdmin
                              ? PopupMenuButton<String>(
                                  onSelected: (v) async {
                                    if (v == 'edit') {
                                      _showForm(r);
                                    } else {
                                      final ok = await showConfirmDialog(
                                          context,
                                          title: 'Delete Room',
                                          message:
                                              'Delete Room ${r.roomNumber}? This cannot be undone.');
                                      if (ok == true && context.mounted) {
                                        await context
                                            .read<HostelProvider>()
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
                ),
    );
  }
}
