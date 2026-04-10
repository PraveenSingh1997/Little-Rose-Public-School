import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attendance_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String? _selectedClassId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadAll();
      context.read<StudentProvider>().loadAll();
    });
  }

  Future<void> _loadAttendance() async {
    if (_selectedClassId == null) return;
    await context.read<AttendanceProvider>().loadForClass(
          _selectedClassId!,
          _selectedDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    final classProvider = context.watch<ClassProvider>();
    final studentProvider = context.watch<StudentProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final isWide = MediaQuery.of(context).size.width >= 720;

    final classStudents = _selectedClassId == null
        ? <dynamic>[]
        : studentProvider.students
            .where((s) => s.classId == _selectedClassId)
            .toList();

    return Scaffold(
      appBar: AppBar(
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    ShellScreen.scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Text('Attendance'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_selectedClassId),
                    initialValue: _selectedClassId,
                    decoration:
                        const InputDecoration(labelText: 'Class'),
                    items: classProvider.classes
                        .map((c) => DropdownMenuItem(
                            value: c.id, child: Text(c.displayName)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _selectedClassId = v);
                      _loadAttendance();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _loadAttendance();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedClassId == null
                ? const EmptyState(
                    icon: Icons.fact_check_outlined,
                    title: 'Select a class to mark attendance',
                  )
                : attendanceProvider.loading
                    ? const LoadingWidget()
                    : classStudents.isEmpty
                        ? const EmptyState(
                            icon: Icons.people_outline,
                            title: 'No students in this class',
                          )
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: classStudents.length,
                                  itemBuilder: (ctx, i) {
                                    final s = classStudents[i];
                                    final existing = attendanceProvider.records
                                        .where((r) => r.studentId == s.id)
                                        .firstOrNull;
                                    final status = existing?.status ??
                                        AttendanceStatus.present;
                                    return Card(
                                      margin:
                                          const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: AvatarWidget(
                                          initials: s.initials,
                                          radius: 20,
                                        ),
                                        title: Text(s.fullName),
                                        subtitle:
                                            Text('Roll: ${s.rollNumber}'),
                                        trailing:
                                            SegmentedButton<AttendanceStatus>(
                                          segments: AttendanceStatus.values
                                              .map((st) => ButtonSegment(
                                                    value: st,
                                                    label: Text(st.label
                                                        .substring(0, 1)),
                                                    tooltip: st.label,
                                                  ))
                                              .toList(),
                                          selected: {status},
                                          onSelectionChanged: (sel) async {
                                            final newStatus = sel.first;
                                            await context
                                                .read<AttendanceProvider>()
                                                .markBulk([
                                              {
                                                'student_id': s.id,
                                                'class_id': _selectedClassId,
                                                'date': _selectedDate
                                                    .toIso8601String()
                                                    .split('T')[0],
                                                'status': newStatus.value,
                                              }
                                            ]);
                                            if (context.mounted) {
                                              _loadAttendance();
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
