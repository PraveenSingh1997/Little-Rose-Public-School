import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
import '../../models/academic_models.dart';
import '../../models/misc_models.dart';
import '../../models/student_models.dart';
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
      if (!mounted) return;
      final role = context.read<AuthProvider>().role;
      context.read<AnnouncementProvider>().load();
      if (role == UserRole.student) {
        final profileId = context.read<AuthProvider>().profile?.id;
        if (profileId != null) {
          context.read<StudentProvider>().loadByProfile(profileId);
        }
        context.read<ClassProvider>().loadAll();
      } else if (role == UserRole.parent) {
        final profileId = context.read<AuthProvider>().profile?.id;
        if (profileId != null) {
          context.read<StudentProvider>().loadByParent(profileId);
        }
      } else {
        context.read<StudentProvider>().loadAll();
        context.read<TeacherProvider>().loadAll();
        context.read<ClassProvider>().loadAll();
        context.read<FeeProvider>().loadPayments();
      }
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

    // ── Student role: show tile dashboard ─────────────────────────────────────
    if (auth.role == UserRole.student) {
      final className = classes.classes
          .where((c) => c.id == students.selectedStudent?.classId)
          .map((c) => c.displayName)
          .firstOrNull ?? '';
      return _StudentDashboard(
        auth: auth,
        student: students.selectedStudent,
        className: className,
        loading: students.loading,
        announcements: announcements.announcements,
      );
    }

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
                      classes: context.read<ClassProvider>().classes,
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
  final List<SchoolClass> classes;
  final bool loading;

  const _UnpaidStudentsCard({
    required this.allStudents,
    required this.paidIds,
    required this.classes,
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
                    'Roll: ${s.rollNumber}${s.classId != null ? '  •  ${classes.where((c) => c.id == s.classId).map((c) => c.displayName).firstOrNull ?? ''}' : ''}',
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
                  '+${unpaid.length - 10} more',
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

// ═══════════════════════════════════════════════════════════════════════════════
// STUDENT TILE DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _StudentDashboard extends StatelessWidget {
  final AuthProvider auth;
  final Student? student;
  final String className;
  final bool loading;
  final List<Announcement> announcements;

  const _StudentDashboard({
    required this.auth,
    required this.student,
    required this.className,
    required this.loading,
    required this.announcements,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    final shell = ShellScreen.of(context);
    final s = student;
    final year = DateTime.now().year.toString();

    final tiles = <_TileData>[
      _TileData(
        title: 'About Me',
        icon: Icons.person_rounded,
        value: 'Click!',
        color: const Color(0xFF1565C0),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                _StudentAboutPage(student: s, className: className),
          ),
        ),
      ),
      _TileData(
        title: 'Timetable',
        icon: Icons.schedule_rounded,
        value: 'Click!',
        color: const Color(0xFF00695C),
        onTap: () => shell?.navigateTo(5),
      ),
      _TileData(
        title: 'Attendance',
        icon: Icons.fact_check_rounded,
        value: 'Click!',
        color: const Color(0xFFE65100),
        onTap: () => shell?.navigateTo(6),
      ),
      _TileData(
        title: 'Exams',
        icon: Icons.assignment_rounded,
        value: 'Click!',
        color: const Color(0xFF6A1B9A),
        onTap: () => shell?.navigateTo(7),
      ),
      _TileData(
        title: 'Fee Management',
        icon: Icons.payments_rounded,
        value: 'Click!',
        color: const Color(0xFF0277BD),
        onTap: () => shell?.navigateTo(8),
      ),
      _TileData(
        title: 'Library',
        icon: Icons.local_library_rounded,
        value: 'Click!',
        color: const Color(0xFF00838F),
        onTap: () => shell?.navigateTo(9),
      ),
      _TileData(
        title: 'Transport',
        icon: Icons.directions_bus_rounded,
        value: 'Click!',
        color: const Color(0xFF1B5E20),
        onTap: () => shell?.navigateTo(10),
      ),
      _TileData(
        title: 'Hostel',
        icon: Icons.hotel_rounded,
        value: 'Click!',
        color: const Color(0xFF4527A0),
        onTap: () => shell?.navigateTo(11),
      ),
      _TileData(
        title: 'Homework',
        icon: Icons.book_rounded,
        value: 'Click!',
        color: const Color(0xFFBF360C),
        onTap: () => shell?.navigateTo(12),
      ),
      _TileData(
        title: 'Announcements',
        icon: Icons.campaign_rounded,
        value: announcements.isNotEmpty
            ? '${announcements.length} new'
            : 'Click!',
        color: const Color(0xFFF57C00),
        onTap: () => shell?.navigateTo(13),
      ),
      _TileData(
        title: 'Notifications',
        icon: Icons.notifications_rounded,
        value: 'Click!',
        color: const Color(0xFF2E7D32),
        onTap: () => shell?.navigateTo(14),
      ),
      _TileData(
        title: 'My Profile',
        icon: Icons.manage_accounts_rounded,
        value: 'Click!',
        color: const Color(0xFF37474F),
        onTap: () => shell?.navigateTo(15),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: _StudentAppBar(
        auth: auth,
        student: s,
        className: className,
        year: year,
        isWide: isWide,
      ),
      body: loading
          ? const Center(child: LoadingWidget())
          : ListView(
              children: [
                _StudentHeaderCard(student: s, className: className),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 5 : 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: tiles.length,
                    itemBuilder: (_, i) => _DashTile(data: tiles[i]),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Student AppBar ───────────────────────────────────────────────────────────

class _StudentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AuthProvider auth;
  final Student? student;
  final String className;
  final String year;
  final bool isWide;

  const _StudentAppBar({
    required this.auth,
    required this.student,
    required this.className,
    required this.year,
    required this.isWide,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      leading: isWide
          ? null
          : IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () =>
                  ShellScreen.scaffoldKey.currentState?.openDrawer(),
            ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.profile?.fullName.toUpperCase() ?? 'STUDENT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (className.isNotEmpty)
                  Text(
                    '$className · $year',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: AvatarWidget(
            photoUrl: auth.profile?.avatarUrl,
            initials: auth.profile?.initials ?? 'S',
            radius: 17,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}

// ─── Student Header Card ──────────────────────────────────────────────────────

class _StudentHeaderCard extends StatelessWidget {
  final Student? student;
  final String className;
  const _StudentHeaderCard(
      {required this.student, required this.className});

  @override
  Widget build(BuildContext context) {
    final s = student;
    if (s == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Center(
              child: Text(
                s.firstName.isNotEmpty
                    ? s.firstName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    _HChip(Icons.badge_rounded, s.rollNumber),
                    if (className.isNotEmpty)
                      _HChip(Icons.class_rounded, className),
                    if (s.category != null)
                      _HChip(Icons.label_rounded,
                          s.category!.toUpperCase()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white70),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────

class _TileData {
  final String title;
  final IconData icon;
  final String value;
  final Color color;
  final VoidCallback onTap;
  const _TileData({
    required this.title,
    required this.icon,
    required this.value,
    required this.color,
    required this.onTap,
  });
}

class _DashTile extends StatelessWidget {
  final _TileData data;
  const _DashTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final d = data;
    final hasBadge = d.value != 'Click!' && d.value.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: d.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                d.color,
                Color.lerp(d.color, Colors.black, 0.18)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: d.color.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative bubble top-right
              Positioned(
                top: -12,
                right: -12,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              // Decorative bubble bottom-left
              Positioned(
                bottom: -8,
                left: -8,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon in rounded container
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(d.icon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        d.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      // Badge (only for items with a count)
                      if (hasBadge) ...[
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            d.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// ABOUT ME PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class _StudentAboutPage extends StatelessWidget {
  final Student? student;
  final String className;
  const _StudentAboutPage(
      {required this.student, required this.className});

  @override
  Widget build(BuildContext context) {
    final s = student;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('About Me')),
        body: const Center(child: Text('No student record linked.')),
      );
    }

    String fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text('About Me',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ── Profile hero ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  child: Text(
                    s.firstName.isNotEmpty
                        ? s.firstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 10),
                Text(s.fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                if (className.isNotEmpty)
                  Text(className,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _AbtChip('Roll: ${s.rollNumber}'),
                    if (s.gender != null) _AbtChip(s.gender!),
                    if (s.bloodGroup != null) _AbtChip(s.bloodGroup!),
                    if (s.category != null)
                      _AbtChip(s.category!.toUpperCase()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _AbtSection(
            icon: Icons.school_rounded,
            title: 'Admission Info',
            rows: [
              _r('Roll Number', s.rollNumber),
              _r('Admission No.', s.admissionNumber),
              _r('Form No.', s.formNumber),
              _r('Scholar No.', s.scholarNumber),
              _r('Admission Date', fmt(s.admissionDate)),
              _r('Class', className.isNotEmpty ? className : null),
              _r('Category', s.category?.toUpperCase()),
            ],
          ),

          _AbtSection(
            icon: Icons.person_rounded,
            title: 'Personal',
            rows: [
              _r('Date of Birth', fmt(s.dateOfBirth)),
              _r('Age', '${s.age} years'),
              _r('Gender', s.gender),
              _r('Blood Group', s.bloodGroup),
            ],
          ),

          _AbtSection(
            icon: Icons.home_rounded,
            title: 'Address',
            rows: [
              _r('Address', s.address),
              _r('City', s.city),
              _r('State', s.state),
            ],
          ),

          _AbtSection(
            icon: Icons.family_restroom_rounded,
            title: 'Family',
            rows: [
              _r("Father's Name", s.fatherName ?? s.parentName),
              _r("Mother's Name", s.motherName),
              _r('Guardian', s.guardianName),
              _r("Father's Occupation", s.fatherOccupation),
              _r("Father's Qualification", s.fatherQualification),
              _r("Mother's Qualification", s.motherQualification),
            ],
          ),

          _AbtSection(
            icon: Icons.phone_rounded,
            title: 'Contact',
            rows: [
              _r('Mobile', s.parentPhone),
              _r('Office Phone', s.officePhone),
              _r('Email', s.parentEmail),
            ],
          ),

          _AbtSection(
            icon: Icons.fingerprint_rounded,
            title: 'Identity',
            rows: [
              _r('Aadhar Number', s.aadharNumber),
              _r('UDISE Number', s.udiseNumber),
            ],
          ),

          _AbtSection(
            icon: Icons.account_balance_rounded,
            title: 'Bank Details',
            rows: [
              _r('Account Number', s.bankAccountNumber),
              _r('IFSC Code', s.ifscCode),
            ],
          ),

          _AbtSection(
            icon: Icons.history_edu_rounded,
            title: 'Previous Education',
            rows: [
              _r('Last Class Passed', s.lastPassedClass),
              _r('Year', s.lastPassedYear),
              _r('Percentage',
                  s.lastPassedPercentage != null
                      ? '${s.lastPassedPercentage}%'
                      : null),
              _r('Total Marks', s.lastPassedTotal),
            ],
          ),

          if (s.tcNumber != null)
            _AbtSection(
              icon: Icons.card_membership_rounded,
              title: 'Transfer Certificate',
              rows: [
                _r('TC Number', s.tcNumber),
                _r('Issued Date',
                    s.tcIssuedDate != null ? fmt(s.tcIssuedDate!) : null),
              ],
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static _AR? _r(String label, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return _AR(label, value.trim());
  }
}

class _AR {
  final String label;
  final String value;
  const _AR(this.label, this.value);
}

class _AbtChip extends StatelessWidget {
  final String label;
  const _AbtChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _AbtSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_AR?> rows;
  const _AbtSection(
      {required this.icon, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final visible = rows.whereType<_AR>().toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon,
                      size: 16, color: const Color(0xFF1565C0)),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1565C0))),
              ],
            ),
          ),
          const Divider(height: 1),
          ...visible.map(
            (r) => Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 155,
                    child: Text(r.label,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13)),
                  ),
                  Expanded(
                    child: Text(r.value,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
