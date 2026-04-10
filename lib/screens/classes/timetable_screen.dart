import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/academic_models.dart';
import '../../models/auth_models.dart';
import '../../providers/app_provider.dart';
import '../../repositories/repositories.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _repo = TimetableRepository();
  List<TimetableEntry> _entries = [];
  bool _loading = false;
  String? _error;
  String? _selectedClassId;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadAll();
    });
  }

  Future<void> _loadTimetable(String classId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _entries = await _repo.getForClass(classId);
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _loading = false);
  }

  void _showForm([TimetableEntry? existing]) {
    final classProvider = context.read<ClassProvider>();
    String? selClass = existing?.classId ?? _selectedClassId;
    String? selSubject = existing?.subjectId;
    int selDay = existing?.dayOfWeek ?? 1;
    int selPeriod = existing?.periodNumber ?? 1;
    TimeOfDay startTime = existing != null
        ? _parseTime(existing.startTime)
        : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = existing != null
        ? _parseTime(existing.endTime)
        : const TimeOfDay(hour: 9, minute: 0);
    final roomCtrl = TextEditingController(text: existing?.roomNumber ?? '');

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
                Text(
                  existing == null ? 'Add Period' : 'Edit Period',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(selClass),
                  initialValue: selClass,
                  decoration: const InputDecoration(labelText: 'Class *'),
                  items: classProvider.classes
                      .map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.displayName)))
                      .toList(),
                  onChanged: (v) => setS(() {
                    selClass = v;
                    selSubject = null;
                    if (v != null) {
                      context.read<ClassProvider>().loadSubjectsForClass(v);
                    }
                  }),
                ),
                const SizedBox(height: 12),
                Consumer<ClassProvider>(
                  builder: (_, cp, __) {
                    final subs = cp.classSubjects.isEmpty ? cp.subjects : cp.classSubjects;
                    return DropdownButtonFormField<String>(
                      key: ValueKey('$selClass-$selSubject'),
                      initialValue: selSubject,
                      decoration: const InputDecoration(labelText: 'Subject *'),
                      items: subs
                          .map((s) => DropdownMenuItem(
                              value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: (v) => setS(() => selSubject = v),
                    );
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey(selDay),
                  initialValue: selDay,
                  decoration: const InputDecoration(labelText: 'Day *'),
                  items: List.generate(
                    6,
                    (i) => DropdownMenuItem(
                        value: i + 1, child: Text(_days[i])),
                  ),
                  onChanged: (v) {
                    if (v != null) setS(() => selDay = v);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        key: ValueKey(selPeriod),
                        initialValue: selPeriod,
                        decoration:
                            const InputDecoration(labelText: 'Period #'),
                        items: List.generate(
                          10,
                          (i) => DropdownMenuItem(
                              value: i + 1, child: Text('Period ${i + 1}')),
                        ),
                        onChanged: (v) {
                          if (v != null) setS(() => selPeriod = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start'),
                        subtitle: Text(startTime.format(ctx)),
                        trailing: const Icon(Icons.access_time, size: 18),
                        onTap: () async {
                          final t = await showTimePicker(
                              context: ctx, initialTime: startTime);
                          if (t != null) setS(() => startTime = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('End'),
                        subtitle: Text(endTime.format(ctx)),
                        trailing: const Icon(Icons.access_time, size: 18),
                        onTap: () async {
                          final t = await showTimePicker(
                              context: ctx, initialTime: endTime);
                          if (t != null) setS(() => endTime = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(labelText: 'Room Number'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (selClass == null || selSubject == null) return;
                    final data = {
                      'class_id': selClass,
                      'subject_id': selSubject,
                      'day_of_week': selDay,
                      'period_number': selPeriod,
                      'start_time': _formatTime(startTime),
                      'end_time': _formatTime(endTime),
                      if (roomCtrl.text.isNotEmpty)
                        'room_number': roomCtrl.text.trim(),
                      if (existing != null) 'id': existing.id,
                    };
                    Navigator.pop(ctx);
                    try {
                      await _repo.upsert(data);
                      if (mounted && _selectedClassId != null) {
                        _loadTimetable(_selectedClassId!);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error saving: $e'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    }
                  },
                  child: Text(existing == null ? 'Add Period' : 'Save Changes'),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1]) ?? 0);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _deleteEntry(TimetableEntry entry) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Period',
      message: 'Remove Period ${entry.periodNumber} on ${entry.dayName}?',
    );
    if (ok == true && mounted) {
      try {
        await _repo.delete(entry.id);
        setState(() => _entries.removeWhere((e) => e.id == entry.id));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error deleting: $e'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classProvider = context.watch<ClassProvider>();
    final role = context.watch<AuthProvider>().role;
    final isWide = MediaQuery.of(context).size.width >= 720;
    final canEdit = role == UserRole.admin || role == UserRole.teacher;

    return Scaffold(
      appBar: AppBar(
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    ShellScreen.scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Text('Timetable'),
      ),
      floatingActionButton: canEdit && _selectedClassId != null
          ? FloatingActionButton.extended(
              onPressed: _showForm,
              icon: const Icon(Icons.add),
              label: const Text('Add Period'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              key: ValueKey(_selectedClassId),
              initialValue: _selectedClassId,
              decoration: const InputDecoration(labelText: 'Select Class'),
              items: classProvider.classes
                  .map((c) => DropdownMenuItem(
                      value: c.id, child: Text(c.displayName)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedClassId = v);
                  _loadTimetable(v);
                  context.read<ClassProvider>().loadSubjectsForClass(v);
                }
              },
            ),
          ),
          Expanded(
            child: _selectedClassId == null
                ? const EmptyState(
                    icon: Icons.schedule_outlined,
                    title: 'Select a class to view timetable',
                  )
                : _loading
                    ? const LoadingWidget()
                    : _error != null
                        ? AppErrorWidget(
                            message: 'Failed to load timetable.\n$_error',
                            onRetry: () => _loadTimetable(_selectedClassId!),
                          )
                        : _entries.isEmpty
                            ? EmptyState(
                                icon: Icons.schedule_outlined,
                                title: 'No timetable entries',
                                onButton: canEdit ? _showForm : null,
                                buttonLabel: 'Add Period',
                              )
                            : _buildTimetableView(classProvider, canEdit),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableView(ClassProvider classProvider, bool canEdit) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _days.asMap().entries.map((e) {
        final dayIdx = e.key + 1;
        final dayName = e.value;
        final dayEntries = _entries
            .where((en) => en.dayOfWeek == dayIdx)
            .toList()
          ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));
        if (dayEntries.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(dayName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            ...dayEntries.map((en) {
              final subject = classProvider.getSubjectById(en.subjectId);
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: CircleAvatar(child: Text('P${en.periodNumber}')),
                  title: Text(subject?.name ?? 'Unknown Subject'),
                  subtitle: Text('${en.startTime} – ${en.endTime}'
                      '${en.roomNumber != null ? '  •  Room ${en.roomNumber}' : ''}'),
                  trailing: canEdit
                      ? PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') {
                              _showForm(en);
                            } else {
                              _deleteEntry(en);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        )
                      : null,
                ),
              );
            }),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }
}
