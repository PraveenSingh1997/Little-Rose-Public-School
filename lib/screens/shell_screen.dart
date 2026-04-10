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
  const _NavItem(index: 0, label: 'Dashboard', icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, roles: _allRoles),
  const _NavItem(index: 1, label: 'Students', icon: Icons.people_outline, selectedIcon: Icons.people, roles: {UserRole.admin, UserRole.teacher}),
  const _NavItem(index: 2, label: 'Teachers', icon: Icons.school_outlined, selectedIcon: Icons.school, roles: {UserRole.admin}),
  const _NavItem(index: 3, label: 'Classes', icon: Icons.class_outlined, selectedIcon: Icons.class_, roles: {UserRole.admin, UserRole.teacher}),
  const _NavItem(index: 4, label: 'Subjects', icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, roles: {UserRole.admin, UserRole.teacher}),
  const _NavItem(index: 5, label: 'Timetable', icon: Icons.schedule_outlined, selectedIcon: Icons.schedule, roles: {UserRole.admin, UserRole.teacher, UserRole.student}),
  const _NavItem(index: 6, label: 'Attendance', icon: Icons.fact_check_outlined, selectedIcon: Icons.fact_check, roles: _allRoles),
  const _NavItem(index: 7, label: 'Exams', icon: Icons.assignment_outlined, selectedIcon: Icons.assignment, roles: _allRoles),
  const _NavItem(index: 8, label: 'Fee Management', icon: Icons.payments_outlined, selectedIcon: Icons.payments, roles: {UserRole.admin, UserRole.student, UserRole.parent}),
  const _NavItem(index: 9, label: 'Library', icon: Icons.local_library_outlined, selectedIcon: Icons.local_library, roles: {UserRole.admin, UserRole.teacher, UserRole.student}),
  const _NavItem(index: 10, label: 'Transport', icon: Icons.directions_bus_outlined, selectedIcon: Icons.directions_bus, roles: {UserRole.admin, UserRole.student, UserRole.parent}),
  const _NavItem(index: 11, label: 'Hostel', icon: Icons.hotel_outlined, selectedIcon: Icons.hotel, roles: {UserRole.admin, UserRole.student}),
  const _NavItem(index: 12, label: 'Homework', icon: Icons.book_outlined, selectedIcon: Icons.book, roles: {UserRole.admin, UserRole.teacher, UserRole.student}),
  const _NavItem(index: 13, label: 'Announcements', icon: Icons.campaign_outlined, selectedIcon: Icons.campaign, roles: _allRoles),
  const _NavItem(index: 14, label: 'Notifications', icon: Icons.notifications_outlined, selectedIcon: Icons.notifications, roles: _allRoles),
  const _NavItem(index: 15, label: 'My Profile', icon: Icons.person_outline, selectedIcon: Icons.person, roles: _allRoles),
];

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  // Static key so inner screens can open the drawer
  static final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;
  // Tracks which screen indices have been visited so we only build them lazily
  final Set<int> _visited = {0};

  Widget _screenForIndex(int index) {
    switch (index) {
      case 0: return const DashboardScreen();
      case 1: return const StudentsScreen();
      case 2: return const TeachersScreen();
      case 3: return const ClassesScreen();
      case 4: return const SubjectsScreen();
      case 5: return const TimetableScreen();
      case 6: return const AttendanceScreen();
      case 7: return const ExamsScreen();
      case 8: return const FeesScreen();
      case 9: return const LibraryScreen();
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

    final visibleItems = _navItems.where((i) => i.roles.contains(role)).toList();

    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 720;

    Widget drawer = NavigationDrawer(
      selectedIndex: visibleItems.indexWhere((i) => i.index == _selectedIndex),
      onDestinationSelected: (i) {
        _navigate(visibleItems[i].index);
        if (!isWide) Navigator.pop(context);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 16, 10),
          child: Row(
            children: [
              AvatarWidget(
                photoUrl: profile?.avatarUrl,
                initials: profile?.initials ?? 'U',
                radius: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.fullName ?? 'User',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    RoleBadge(role: role.name),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
          child: Text(
            profile?.email ?? '',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Divider(indent: 16, endIndent: 16),
        ...visibleItems.map((item) {
          if (item.index == 14) {
            // Notifications with badge
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
        const Divider(indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: ListTile(
            leading: Icon(Icons.logout, color: cs.error),
            title: Text('Sign Out', style: TextStyle(color: cs.error)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}
