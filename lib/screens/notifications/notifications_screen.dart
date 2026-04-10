import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().profile?.id;
      if (userId != null) {
        context.read<NotificationProvider>().load(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      appBar: AppBar(
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    ShellScreen.scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () {
                final userId = auth.profile?.id;
                if (userId != null) {
                  context.read<NotificationProvider>().markAllRead(userId);
                }
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: provider.notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_outlined,
              title: 'No notifications',
              subtitle: 'You\'re all caught up!',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              itemBuilder: (ctx, i) {
                final n = provider.notifications[i];
                final color = Color(n.colorValue);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: n.isRead
                      ? null
                      : Theme.of(ctx)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(_iconForType(n.type), color: color, size: 20),
                    ),
                    title: Text(
                      n.title,
                      style: TextStyle(
                          fontWeight: n.isRead
                              ? FontWeight.normal
                              : FontWeight.bold),
                    ),
                    subtitle: Text(n.message,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Text(
                      _formatDate(n.createdAt),
                      style: Theme.of(ctx).textTheme.labelSmall,
                    ),
                    onTap: n.isRead
                        ? null
                        : () => context
                            .read<NotificationProvider>()
                            .markRead(n.id),
                  ),
                );
              },
            ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'attendance':
        return Icons.fact_check;
      case 'fee':
        return Icons.payments;
      case 'exam':
        return Icons.assignment;
      case 'announcement':
        return Icons.campaign;
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }
}
