import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/auth_models.dart';
import '../widgets/common_widgets.dart';

// Feature screens
import 'admin/dashboard_screen.dart';
import 'students/students_screen.dart';
import 'teachers/teachers_screen.dart';
import 'classes/classes_screen.dart';
import 'classes/subjects_screen.dart';
import 'classes/timetable_screen.dart';
import 'attendance/attendance_screen.dart';
import 'exams/exams_screen.dart';
import 'fees/fees_screen.dart';
import 'library/library_screen.dart';
import 'transport/transport_screen.dart';
import 'hostel/hostel_screen.dart';
import 'homework/homework_screen.dart';
import 'announcements/announcements_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';

class _NavItem {
  final int index;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Set<UserRole> roles;

  const _NavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.roles,
  });
}

const _allRoles = {
  UserRole.admin,
  UserRole.teacher,
  UserRole.student,
  UserRole.parent
};

final _navItems = [
  const _NavItem(index: 0, label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard_rounded, roles: _allRoles),
  const _NavItem(index: 1, label: 'Students', icon: Icons.people_outline_rounded, selectedIcon: Icons.people_rounded, roles: {UserRole.admin, UserRole.teacher}),
  const _NavItem(index: 2, label: 'Teachers', icon: Icons.school_outlined, selectedIcon: Icons.school_rounded, roles: {UserRole.admin}),
  const _NavItem(index: 3, label: 'Classes', icon: Icons.class_outlined, selectedIcon: Icons.class_rounded, roles: {UserRole.admin, UserRole.teacher}),
  const _NavItem(index: 4, label: 'Subjects', icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book_rounded, roles: {UserRole.admin, UserRole.teacher}),
  const _NavItem(index: 5, label: 'Timetable', icon: Icons.schedule_outlined, selectedIcon: Icons.schedule_rounded, roles: {UserRole.admin, UserRole.teacher, UserRole.student}),
  const _NavItem(index: 6, label: 'Attendance', icon: Icons.fact_check_outlined, selectedIcon: Icons.fact_check_rounded, roles: _allRoles),
  const _NavItem(index: 7, label: 'Exams', icon: Icons.assignment_outlined, selectedIcon: Icons.assignment_rounded, roles: _allRoles),
  const _NavItem(index: 8, label: 'Fee Management', icon: Icons.payments_outlined, selectedIcon: Icons.payments_rounded, roles: {UserRole.admin, UserRole.student, UserRole.parent}),
  const _NavItem(index: 9, label: 'Library', icon: Icons.local_library_outlined, selectedIcon: Icons.local_library_rounded, roles: {UserRole.admin, UserRole.teacher, UserRole.student}),
  const _NavItem(index: 10, label: 'Transport', icon: Icons.directions_bus_outlined, selectedIcon: Icons.directions_bus_rounded, roles: {UserRole.admin, UserRole.student, UserRole.parent}),
  const _NavItem(index: 11, label: 'Hostel', icon: Icons.hotel_outlined, selectedIcon: Icons.hotel_rounded, roles: {UserRole.admin, UserRole.student}),
  const _NavItem(index: 12, label: 'Homework', icon: Icons.book_outlined, selectedIcon: Icons.book_rounded, roles: {UserRole.admin, UserRole.teacher, UserRole.student}),
  const _NavItem(index: 13, label: 'Announcements', icon: Icons.campaign_outlined, selectedIcon: Icons.campaign_rounded, roles: _allRoles),
  const _NavItem(index: 14, label: 'Notifications', icon: Icons.notifications_outlined, selectedIcon: Icons.notifications_rounded, roles: _allRoles),
  const _NavItem(index: 15, label: 'My Profile', icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, roles: _allRoles),
];

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  // Static key so inner screens can open the drawer
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  /// Navigate to a shell index from any descendant widget.
  static ShellScreenState? of(BuildContext ctx) =>
      ctx.findAncestorStateOfType<ShellScreenState>();

  @override
  State<ShellScreen> createState() => ShellScreenState();
}

class ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;
  final Set<int> _visited = {0};

  void navigateTo(int index) => _navigate(index);

  Widget _screenForIndex(int index) {
    switch (index) {
      case 0:  return const DashboardScreen();
      case 1:  return const StudentsScreen();
      case 2:  return const TeachersScreen();
      case 3:  return const ClassesScreen();
      case 4:  return const SubjectsScreen();
      case 5:  return const TimetableScreen();
      case 6:  return const AttendanceScreen();
      case 7:  return const ExamsScreen();
      case 8:  return const FeesScreen();
      case 9:  return const LibraryScreen();
      case 10: return const TransportScreen();
      case 11: return const HostelScreen();
      case 12: return const HomeworkScreen();
      case 13: return const AnnouncementsScreen();
      case 14: return const NotificationsScreen();
      case 15: return const ProfileScreen();
      default: return const DashboardScreen();
    }
  }

  void _navigate(int index) {
    setState(() {
      _selectedIndex = index;
      _visited.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.role;
    final unread = context.watch<NotificationProvider>().unreadCount;
    final profile = auth.profile;

    final visibleItems =
        _navItems.where((i) => i.roles.contains(role)).toList();

    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 720;

    final drawer = _buildDrawer(
      context,
      cs: cs,
      profile: profile,
      role: role,
      visibleItems: visibleItems,
      unread: unread,
      isWide: isWide,
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            drawer,
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: List.generate(
                  16,
                  (i) => _visited.contains(i)
                      ? _screenForIndex(i)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: ShellScreen.scaffoldKey,
      drawer: drawer,
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(
          16,
          (i) => _visited.contains(i)
              ? _screenForIndex(i)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context, {
    required ColorScheme cs,
    required dynamic profile,
    required UserRole role,
    required List<_NavItem> visibleItems,
    required int unread,
    required bool isWide,
  }) {
    return NavigationDrawer(
      selectedIndex:
          visibleItems.indexWhere((i) => i.index == _selectedIndex),
      onDestinationSelected: (i) {
        _navigate(visibleItems[i].index);
        if (!isWide) Navigator.pop(context);
      },
      children: [
        // ── School Branding Header ──────────────────────────────────────────
        _DrawerHeader(profile: profile, role: role, cs: cs),

        const SizedBox(height: 8),

        // ── Nav Items ──────────────────────────────────────────────────────
        ...visibleItems.map((item) {
          if (item.index == 14) {
            return NavigationDrawerDestination(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: Icon(item.icon),
              ),
              selectedIcon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: Icon(item.selectedIcon),
              ),
              label: Text(item.label),
            );
          }
          return NavigationDrawerDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: Text(item.label),
          );
        }),

        // ── Sign Out ────────────────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Divider(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout_rounded, color: cs.error, size: 18),
            ),
            title: Text(
              'Sign Out',
              style: TextStyle(
                color: cs.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onTap: () async {
              final confirm = await showConfirmDialog(
                context,
                title: 'Sign Out',
                message: 'Are you sure you want to sign out?',
                confirmText: 'Sign Out',
              );
              if (confirm == true && context.mounted) {
                context.read<AuthProvider>().signOut();
              }
            },
          ),
        ),
      ],
    );
  }
}

// ─── Drawer Header ────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final dynamic profile;
  final UserRole role;
  final ColorScheme cs;

  const _DrawerHeader({
    required this.profile,
    required this.role,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary,
            cs.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // School branding
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Little Rose',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // User info
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: AvatarWidget(
                  photoUrl: profile?.avatarUrl,
                  initials: profile?.initials ?? 'U',
                  radius: 22,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.fullName ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile?.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _WhiteRoleBadge(role: role.name),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhiteRoleBadge extends StatelessWidget {
  final String role;
  const _WhiteRoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.isNotEmpty
            ? role[0].toUpperCase() + role.substring(1)
            : 'Unknown',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
