import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/misc_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadAll();
      context.read<TeacherProvider>().loadAll();
      context.read<AnnouncementProvider>().load();
      context.read<ClassProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final students = context.watch<StudentProvider>();
    final teachers = context.watch<TeacherProvider>();
    final announcements = context.watch<AnnouncementProvider>();
    final classes = context.watch<ClassProvider>();
    final isWide = MediaQuery.of(context).size.width >= 720;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    ShellScreen.scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Text('Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AvatarWidget(
              photoUrl: auth.profile?.avatarUrl,
              initials: auth.profile?.initials ?? 'U',
              radius: 18,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!context.mounted) return;
          await Future.wait([
            context.read<StudentProvider>().loadAll(),
            context.read<TeacherProvider>().loadAll(),
            context.read<AnnouncementProvider>().load(),
            context.read<ClassProvider>().loadAll(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Welcome back, ${auth.profile?.fullName ?? 'User'}!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Here\'s what\'s happening today.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  label: 'Total Students',
                  value: '${students.students.length}',
                  icon: Icons.people,
                  color: cs.primary,
                  subtitle:
                      '${students.students.where((s) => s.isActive).length} active',
                ),
                StatCard(
                  label: 'Total Teachers',
                  value: '${teachers.teachers.length}',
                  icon: Icons.school,
                  color: Colors.green,
                ),
                StatCard(
                  label: 'Announcements',
                  value: '${announcements.announcements.length}',
                  icon: Icons.campaign,
                  color: Colors.orange,
                ),
                StatCard(
                  label: 'Classes',
                  value: '${classes.classes.length}',
                  icon: Icons.class_,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Recent Announcements'),
            const SizedBox(height: 12),
            if (announcements.loading)
              const LoadingWidget()
            else if (announcements.announcements.isEmpty)
              const EmptyState(
                icon: Icons.campaign_outlined,
                title: 'No announcements yet',
              )
            else
              ...announcements.announcements.take(5).map((a) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Color(a.type.colorValue).withValues(alpha: 0.15),
                        child: Text(a.type.icon,
                            style: const TextStyle(fontSize: 18)),
                      ),
                      title: Text(a.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(a.content,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Text(
                        _formatDate(a.createdAt),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  )),
          ],
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
