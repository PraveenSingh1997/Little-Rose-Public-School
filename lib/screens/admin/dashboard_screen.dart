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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
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
                icon: const Icon(Icons.menu_rounded),
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
            // ── Greeting Banner ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary,
                    cs.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()},',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.profile?.fullName.split(' ').first ??
                              'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatToday(),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Stats ──────────────────────────────────────────────────────
            const SectionHeader(title: 'Overview'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.25,
              children: [
                StatCard(
                  label: 'Total Students',
                  value: students.loading
                      ? '—'
                      : '${students.students.length}',
                  icon: Icons.people_rounded,
                  color: cs.primary,
                  subtitle: students.loading
                      ? null
                      : '${students.students.where((s) => s.isActive).length} active',
                ),
                StatCard(
                  label: 'Total Teachers',
                  value: teachers.loading
                      ? '—'
                      : '${teachers.teachers.length}',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF388E3C),
                ),
                StatCard(
                  label: 'Announcements',
                  value: announcements.loading
                      ? '—'
                      : '${announcements.announcements.length}',
                  icon: Icons.campaign_rounded,
                  color: const Color(0xFFF57C00),
                ),
                StatCard(
                  label: 'Classes',
                  value:
                      classes.loading ? '—' : '${classes.classes.length}',
                  icon: Icons.class_rounded,
                  color: const Color(0xFF7B1FA2),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Recent Announcements ───────────────────────────────────────
            const SectionHeader(title: 'Recent Announcements'),
            const SizedBox(height: 12),

            if (announcements.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: LoadingWidget(),
              )
            else if (announcements.announcements.isEmpty)
              const EmptyState(
                icon: Icons.campaign_outlined,
                title: 'No announcements yet',
                subtitle: 'Announcements will appear here',
              )
            else
              ...announcements.announcements.take(5).map(
                    (a) => _AnnouncementCard(announcement: a),
                  ),
          ],
        ),
      ),
    );
  }

  String _formatToday() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final dayName = days[now.weekday - 1];
    return '$dayName, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

// ─── Announcement Card ─────────────────────────────────────────────────────────

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final a = announcement;
    final color = Color(a.type.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Color accent strip
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          a.type.icon,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    a.title,
                                    style: tt.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    a.type.label,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.content,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(a.publishedAt),
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
