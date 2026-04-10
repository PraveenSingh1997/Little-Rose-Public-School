import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/academic_models.dart';
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
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassProvider>().loadAll();
    });
  }

  Future<void> _loadTimetable(String classId) async {
    setState(() => _loading = true);
    _entries = await _repo.getForClass(classId);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final classProvider = context.watch<ClassProvider>();
    final isWide = MediaQuery.of(context).size.width >= 720;

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
                    : _entries.isEmpty
                        ? const EmptyState(
                            icon: Icons.schedule_outlined,
                            title: 'No timetable entries',
                          )
                        : _buildTimetableView(classProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableView(ClassProvider classProvider) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: days.asMap().entries.map((e) {
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
