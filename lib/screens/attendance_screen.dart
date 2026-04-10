import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  final _store = StorageService();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar.large(
            automaticallyImplyLeading: MediaQuery.of(context).size.width < 720,
            leading: MediaQuery.of(context).size.width < 720
                ? Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  )
                : null,
            title: const Text('Attendance'),
            bottom: TabBar(
              controller: _tabCtrl,
              tabs: const [
                Tab(text: 'Mark Attendance'),
                Tab(text: 'View Records'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _MarkAttendanceTab(store: _store, onSaved: () => setState(() {})),
            _ViewAttendanceTab(store: _store),
          ],
        ),
      ),
    );
  }
}

// ─── Mark Attendance Tab ──────────────────────────────────────────────────────

class _MarkAttendanceTab extends StatefulWidget {
  final StorageService store;
  final VoidCallback onSaved;
  const _MarkAttendanceTab({required this.store, required this.onSaved});

  @override
  State<_MarkAttendanceTab> createState() => _MarkAttendanceTabState();
}

class _MarkAttendanceTabState extends State<_MarkAttendanceTab> {
  String? _selectedClass;
  String? _selectedSubjectId;
  DateTime _date = DateTime.now();
  Map<String, AttendanceStatus> _statusMap = {};

  List<String> get _classes {
    return widget.store.students
        .map((s) => s.className)
        .toSet()
        .toList()
      ..sort();
  }

  List<Subject> get _subjectsForClass {
    if (_selectedClass == null) return [];
    return widget.store.subjects
        .where((s) => s.className == _selectedClass)
        .toList();
  }

  List<Student> get _studentsForClass {
    if (_selectedClass == null) return [];
    return widget.store.students
        .where((s) => s.className == _selectedClass && s.isActive)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _initStatusMap() {
    final day = DateTime(_date.year, _date.month, _date.day);
    final subjectId = _selectedSubjectId;
    _statusMap = {};
    for (final student in _studentsForClass) {
      final existing = widget.store.attendance
          .where((a) =>
              a.studentId == student.id &&
              a.subjectId == subjectId &&
              a.date.year == day.year &&
              a.date.month == day.month &&
              a.date.day == day.day)
          .firstOrNull;
      _statusMap[student.id] = existing?.status ?? AttendanceStatus.present;
    }
  }

  void _saveAttendance() {
    final day = DateTime(_date.year, _date.month, _date.day);
    final subjectId = _selectedSubjectId!;

    // Remove existing records for this date+subject
    widget.store.attendance.removeWhere((a) =>
        a.subjectId == subjectId &&
        a.date.year == day.year &&
        a.date.month == day.month &&
        a.date.day == day.day);

    // Add new records
    for (final entry in _statusMap.entries) {
      widget.store.attendance.add(AttendanceRecord(
        studentId: entry.key,
        subjectId: subjectId,
        date: day,
        status: entry.value,
      ));
    }
    widget.store.saveAttendance();
    widget.onSaved();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance saved successfully!')),
    );
  }

  void _markAll(AttendanceStatus status) {
    setState(() {
      for (final key in _statusMap.keys) {
        _statusMap[key] = status;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canMark = _selectedClass != null && _selectedSubjectId != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Class selector
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedClass),
          initialValue: _selectedClass,
          decoration: const InputDecoration(
            labelText: 'Select Class',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.class_outlined),
          ),
          items: _classes
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() {
            _selectedClass = v;
            _selectedSubjectId = null;
            _statusMap = {};
          }),
        ),
        const SizedBox(height: 16),

        // Subject selector
        DropdownButtonFormField<String>(
          key: ValueKey('$_selectedClass-$_selectedSubjectId'),
          initialValue: _selectedSubjectId,
          decoration: const InputDecoration(
            labelText: 'Select Subject',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.menu_book_outlined),
          ),
          items: _subjectsForClass
              .map((s) =>
                  DropdownMenuItem(value: s.id, child: Text(s.name)))
              .toList(),
          onChanged: _selectedClass == null
              ? null
              : (v) => setState(() {
                    _selectedSubjectId = v;
                    _initStatusMap();
                  }),
        ),
        const SizedBox(height: 16),

        // Date picker
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime.now().subtract(const Duration(days: 90)),
              lastDate: DateTime.now(),
            );
            if (d != null) {
              setState(() {
                _date = d;
                _initStatusMap();
              });
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            child: Text(DateFormat('EEEE, MMMM d, y').format(_date)),
          ),
        ),
        const SizedBox(height: 20),

        if (canMark && _studentsForClass.isNotEmpty) ...[
          // Quick mark all
          Row(
            children: [
              Text('Mark all as:',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 12),
              _StatusChip(
                  label: 'Present',
                  status: AttendanceStatus.present,
                  onTap: () => _markAll(AttendanceStatus.present)),
              const SizedBox(width: 8),
              _StatusChip(
                  label: 'Absent',
                  status: AttendanceStatus.absent,
                  onTap: () => _markAll(AttendanceStatus.absent)),
            ],
          ),
          const SizedBox(height: 12),

          // Student list
          ..._studentsForClass.map((student) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          student.name[0],
                          style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(student.rollNo,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      SegmentedButton<AttendanceStatus>(
                        segments: const [
                          ButtonSegment(
                              value: AttendanceStatus.present,
                              label: Text('P'),
                              tooltip: 'Present'),
                          ButtonSegment(
                              value: AttendanceStatus.absent,
                              label: Text('A'),
                              tooltip: 'Absent'),
                          ButtonSegment(
                              value: AttendanceStatus.late,
                              label: Text('L'),
                              tooltip: 'Late'),
                        ],
                        selected: {
                          _statusMap[student.id] ?? AttendanceStatus.present
                        },
                        onSelectionChanged: (s) => setState(
                            () => _statusMap[student.id] = s.first),
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          textStyle: WidgetStateProperty.all(
                              const TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saveAttendance,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Attendance'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
          ),
        ] else if (canMark && _studentsForClass.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No students in $_selectedClass',
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.fact_check_outlined,
                      size: 64,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('Select a class and subject to mark attendance',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final AttendanceStatus status;
  final VoidCallback onTap;
  const _StatusChip(
      {required this.label, required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(status.colorValue);
    return ActionChip(
      label: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      side: BorderSide(color: color),
      backgroundColor: color.withValues(alpha: 0.1),
      onPressed: onTap,
    );
  }
}

// ─── View Attendance Tab ──────────────────────────────────────────────────────

class _ViewAttendanceTab extends StatefulWidget {
  final StorageService store;
  const _ViewAttendanceTab({required this.store});

  @override
  State<_ViewAttendanceTab> createState() => _ViewAttendanceTabState();
}

class _ViewAttendanceTabState extends State<_ViewAttendanceTab> {
  String? _studentId;

  List<Student> get _students =>
      widget.store.students.where((s) => s.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  List<AttendanceRecord> get _records {
    if (_studentId == null) return [];
    return widget.store.attendance
        .where((a) => a.studentId == _studentId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final records = _records;
    final total = records.length;
    final present =
        records.where((r) => r.status == AttendanceStatus.present).length;
    final pct = total > 0 ? (present / total * 100).toStringAsFixed(1) : '—';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(_studentId),
          initialValue: _studentId,
          decoration: const InputDecoration(
            labelText: 'Select Student',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person_outline),
          ),
          items: _students
              .map((s) => DropdownMenuItem(
                  value: s.id, child: Text('${s.name} (${s.rollNo})')))
              .toList(),
          onChanged: (v) => setState(() => _studentId = v),
        ),
        const SizedBox(height: 16),
        if (_studentId != null && records.isNotEmpty) ...[
          // Summary card
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AttStat('Total', '$total', cs.onPrimaryContainer),
                  _AttStat('Present', '$present',
                      const Color(0xFF4CAF50)),
                  _AttStat('Absent',
                      '${records.where((r) => r.status == AttendanceStatus.absent).length}',
                      const Color(0xFFF44336)),
                  _AttStat('Rate', '$pct%', cs.onPrimaryContainer),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...records.map((r) {
            final subject = widget.store.subjects
                .where((s) => s.id == r.subjectId)
                .firstOrNull;
            final color = Color(r.status.colorValue);
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(r.status.label[0],
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
                title: Text(subject?.name ?? 'Unknown Subject'),
                subtitle: Text(DateFormat('EEE, MMM d, y').format(r.date)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(r.status.label,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            );
          }),
        ] else if (_studentId != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No attendance records found.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ),
          )
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.bar_chart_outlined,
                      size: 64,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('Select a student to view their attendance',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AttStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AttStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
