import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
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
      context.read<FeeProvider>().loadPayments();
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
    final fees = context.watch<FeeProvider>();
    final isWide = MediaQuery.of(context).size.width >= 720;
    final cs = Theme.of(context).colorScheme;
    final isAdmin = auth.role == UserRole.admin;

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
            context.read<FeeProvider>().loadPayments(),
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

            // ── Fee Analytics (admin only) ─────────────────────────────────
            if (isAdmin) ...[
              const SectionHeader(title: 'Fee Collections'),
              const SizedBox(height: 12),
              if (fees.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: LoadingWidget(),
                )
              else
                Column(
                  children: [
                    // Today / Week / Month cards
                    Row(
                      children: [
                        Expanded(
                          child: _FeeCard(
                            label: 'Today',
                            amount: fees.todayTotal,
                            count: fees.todayCount,
                            color: const Color(0xFF1E88E5),
                            icon: Icons.today_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FeeCard(
                            label: 'This Week',
                            amount: fees.weekTotal,
                            count: fees.weekCount,
                            color: const Color(0xFF43A047),
                            icon: Icons.date_range_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FeeCard(
                            label: 'This Month',
                            amount: fees.monthTotal,
                            count: fees.monthCount,
                            color: const Color(0xFF8E24AA),
                            icon: Icons.calendar_month_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Unpaid students this month
                    _UnpaidStudentsCard(
                      allStudents: students.students,
                      paidIds: fees.studentsPaidThisMonth,
                      loading: students.loading || fees.loading,
                    ),
                  ],
                ),
              const SizedBox(height: 28),
            ],

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

// ─── Fee Collection Card ───────────────────────────────────────────────────────

class _FeeCard extends StatelessWidget {
  final String label;
  final double amount;
  final int count;
  final Color color;
  final IconData icon;

  const _FeeCard({
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count txn',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹${_fmt(amount)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Unpaid Students Card ──────────────────────────────────────────────────────

class _UnpaidStudentsCard extends StatelessWidget {
  final List<dynamic> allStudents;
  final Set<String> paidIds;
  final bool loading;

  const _UnpaidStudentsCard({
    required this.allStudents,
    required this.paidIds,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: LoadingWidget(),
      );
    }

    final unpaid = allStudents
        .where((s) => !paidIds.contains(s.id))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.warning_amber_rounded,
                      size: 18, color: cs.onErrorContainer),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fees Not Submitted',
                          style: tt.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text('Current month — ${unpaid.length} student(s)',
                          style: tt.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: unpaid.isEmpty
                        ? Colors.green.withValues(alpha: 0.12)
                        : cs.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    unpaid.isEmpty ? 'All Clear' : '${unpaid.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: unpaid.isEmpty
                          ? Colors.green
                          : cs.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          if (unpaid.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text('All students have paid this month!',
                      style: tt.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unpaid.length > 10 ? 10 : unpaid.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = unpaid[i];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        cs.errorContainer.withValues(alpha: 0.5),
                    child: Text(
                      (s.fullName as String).isNotEmpty
                          ? s.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onErrorContainer),
                    ),
                  ),
                  title: Text(s.fullName as String,
                      style: tt.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Roll: ${s.rollNumber}${s.className != null ? '  •  ${s.className}' : ''}',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Unpaid',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cs.onErrorContainer)),
                  ),
                );
              },
            ),

          if (unpaid.length > 10) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  '+${unpaid.length - 10} more students',
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
