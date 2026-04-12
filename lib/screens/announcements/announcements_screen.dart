import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
import '../../models/misc_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementProvider>().load();
    });
  }

  void _showForm() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    AnnouncementType selType = AnnouncementType.general;
    String selAudience = 'all';

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
                Text('New Announcement',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                    controller: titleCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Title *')),
                const SizedBox(height: 12),
                TextField(
                    controller: contentCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Content *'),
                    maxLines: 4),
                const SizedBox(height: 12),
                DropdownButtonFormField<AnnouncementType>(
                  key: ValueKey(selType),
                  initialValue: selType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: AnnouncementType.values
                      .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text('${t.icon} ${t.label}')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setS(() => selType = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(selAudience),
                  initialValue: selAudience,
                  decoration:
                      const InputDecoration(labelText: 'Target Audience'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Everyone')),
                    DropdownMenuItem(
                        value: 'students', child: Text('Students')),
                    DropdownMenuItem(
                        value: 'teachers', child: Text('Teachers')),
                    DropdownMenuItem(
                        value: 'parents', child: Text('Parents')),
                  ],
                  onChanged: (v) {
                    if (v != null) setS(() => selAudience = v);
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty ||
                        contentCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Title and content are required'),
                        behavior: SnackBarBehavior.floating,
                      ));
                      return;
                    }
                    final data = {
                      'title': titleCtrl.text.trim(),
                      'content': contentCtrl.text.trim(),
                      'type': selType.value,
                      'target_audience': selAudience,
                      'published_at': DateTime.now().toIso8601String(),
                    };
                    Navigator.pop(ctx);
                    try {
                      await context
                          .read<AnnouncementProvider>()
                          .create(data);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error posting announcement: $e'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    }
                  },
                  child: const Text('Post Announcement'),
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
    final provider = context.watch<AnnouncementProvider>();
    final role = context.watch<AuthProvider>().role;
    final isWide = MediaQuery.of(context).size.width >= 720;
    final canPost = role == UserRole.admin || role == UserRole.teacher;

    return Scaffold(
      appBar: AppBar(
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    ShellScreen.scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Text('Announcements'),
      ),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: _showForm,
              icon: const Icon(Icons.campaign),
              label: const Text('Post'),
            )
          : null,
      body: provider.loading
          ? const LoadingWidget()
          : provider.error != null
              ? AppErrorWidget(
                  message: 'Failed to load announcements.\n${provider.error}',
                  onRetry: () => context.read<AnnouncementProvider>().load(),
                )
              : provider.announcements.isEmpty
              ? EmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'No announcements',
                  onButton: canPost ? _showForm : null,
                  buttonLabel: 'Post Announcement',
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<AnnouncementProvider>().load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.announcements.length,
                    itemBuilder: (ctx, i) {
                      final a = provider.announcements[i];
                      final color = Color(a.type.colorValue);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        color.withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${a.type.icon} ${a.type.label}',
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDate(a.publishedAt),
                                  style: Theme.of(ctx)
                                      .textTheme
                                      .labelSmall,
                                ),
                                if (canPost)
                                  PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'delete') {
                                        final ok = await showConfirmDialog(
                                            context,
                                            title: 'Delete Announcement',
                                            message:
                                                'Delete "${a.title}"?');
                                        if (ok == true &&
                                            context.mounted) {
                                          await context
                                              .read<AnnouncementProvider>()
                                              .delete(a.id);
                                        }
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete')),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(a.title,
                                style: Theme.of(ctx)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(a.content,
                                style: Theme.of(ctx).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    );
                    },
                  ),
                ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
