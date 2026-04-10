import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/models.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _store = StorageService();

  int get _totalStudents => _store.students.where((s) => s.isActive).length;
  int get _totalTeachers => _store.teachers.where((t) => t.isActive).length;
  int get _totalSubjects => _store.subjects.length;

  double get _todayAttendancePct {
    final today = DateTime.now();
    final recs = _store.attendance.where((a) =>
        a.date.year == today.year &&
        a.date.month == today.month &&
        a.date.day == today.day);
    if (recs.isEmpty) return 0;
    final present =
        recs.where((a) => a.status == AttendanceStatus.present).length;
    return (present / recs.length) * 100;
  }

  List<Announcement> get _recentAnnouncements {
    final sorted = List<Announcement>.from(_store.announcements)
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.date.compareTo(a.date);
      });
    return sorted.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final today = DateTime.now();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            automaticallyImplyLeading:
                MediaQuery.of(context).size.width < 720,
            leading: MediaQuery.of(context).size.width < 720
                ? Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  )
                : null,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good ${_greeting()},'),
                Text('Admin',
                    style: tt.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Text('A',
                      style: TextStyle(color: cs.onPrimaryContainer)),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Date chip
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(today),
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                // Stats grid
                _SectionHeader(title: 'Overview', onTap: null),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      label: 'Students',
                      value: '$_totalStudents',
                      icon: Icons.people_alt_outlined,
                      color: const Color(0xFF1565C0),
                      onTap: () => widget.onNavigate?.call(1),
                    ),
                    _StatCard(
                      label: 'Teachers',
                      value: '$_totalTeachers',
                      icon: Icons.school_outlined,
                      color: const Color(0xFF6A1B9A),
                      onTap: () => widget.onNavigate?.call(2),
                    ),
                    _StatCard(
                      label: 'Subjects',
                      value: '$_totalSubjects',
                      icon: Icons.menu_book_outlined,
                      color: const Color(0xFF00695C),
                      onTap: () => widget.onNavigate?.call(3),
                    ),
                    _StatCard(
                      label: "Today's Attendance",
                      value: _todayAttendancePct == 0
                          ? 'N/A'
                          : '${_todayAttendancePct.toStringAsFixed(0)}%',
                      icon: Icons.fact_check_outlined,
                      color: const Color(0xFFE65100),
                      onTap: () => widget.onNavigate?.call(4),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Quick actions
                _SectionHeader(title: 'Quick Actions', onTap: null),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickAction(
                        icon: Icons.person_add_outlined,
                        label: 'Add Student',
                        onTap: () => widget.onNavigate?.call(1),
                      ),
                      _QuickAction(
                        icon: Icons.fact_check_outlined,
                        label: 'Attendance',
                        onTap: () => widget.onNavigate?.call(4),
                      ),
                      _QuickAction(
                        icon: Icons.grade_outlined,
                        label: 'Grades',
                        onTap: () => widget.onNavigate?.call(5),
                      ),
                      _QuickAction(
                        icon: Icons.campaign_outlined,
                        label: 'Announce',
                        onTap: () => widget.onNavigate?.call(6),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Recent announcements
                _SectionHeader(
                  title: 'Recent Announcements',
                  onTap: () => widget.onNavigate?.call(6),
                ),
                const SizedBox(height: 12),
                if (_recentAnnouncements.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No announcements yet.',
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant)),
                    ),
                  )
                else
                  ..._recentAnnouncements
                      .map((a) => _AnnouncementTile(announcement: a)),

                const SizedBox(height: 28),

                // Recent grades
                _SectionHeader(
                  title: 'Recent Grades',
                  onTap: () => widget.onNavigate?.call(5),
                ),
                const SizedBox(height: 12),
                ..._store.grades
                    .take(4)
                    .map((g) => _GradeTile(grade: g, store: _store)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const _SectionHeader({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        if (onTap != null)
          TextButton(onPressed: onTap, child: const Text('See all')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: tt.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(label,
                      style: tt.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 90,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: cs.onPrimaryContainer),
              const SizedBox(height: 8),
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  final Announcement announcement;
  const _AnnouncementTile({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = Color(announcement.type.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(announcement.type.icon,
              style: const TextStyle(fontSize: 18)),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(announcement.title,
                  style: tt.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (announcement.isPinned)
              Icon(Icons.push_pin, size: 14, color: cs.primary),
          ],
        ),
        subtitle: Text(announcement.content,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(
          DateFormat('MMM d').format(announcement.date),
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _GradeTile extends StatelessWidget {
  final Grade grade;
  final StorageService store;
  const _GradeTile({required this.grade, required this.store});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final student =
        store.students.where((s) => s.id == grade.studentId).firstOrNull;
    final subject =
        store.subjects.where((s) => s.id == grade.subjectId).firstOrNull;
    final gradeColor = Color(grade.gradeColor);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: gradeColor.withValues(alpha: 0.15),
          child: Text(grade.letterGrade,
              style: TextStyle(
                  color: gradeColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        title: Text(student?.name ?? 'Unknown',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${subject?.name ?? 'Unknown'} · ${grade.examType.label}'),
        trailing: Text(
          '${grade.marks.toInt()}/${grade.totalMarks.toInt()}',
          style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}
