import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen>
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
            title: const Text('Grades'),
            bottom: TabBar(
              controller: _tabCtrl,
              tabs: const [
                Tab(text: 'Add Grade'),
                Tab(text: 'Grade Report'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _AddGradeTab(store: _store, onSaved: () => setState(() {})),
            _GradeReportTab(store: _store),
          ],
        ),
      ),
    );
  }
}

// ─── Add Grade Tab ────────────────────────────────────────────────────────────

class _AddGradeTab extends StatefulWidget {
  final StorageService store;
  final VoidCallback onSaved;
  const _AddGradeTab({required this.store, required this.onSaved});

  @override
  State<_AddGradeTab> createState() => _AddGradeTabState();
}

class _AddGradeTabState extends State<_AddGradeTab> {
  final _formKey = GlobalKey<FormState>();
  String? _studentId;
  String? _subjectId;
  ExamType _examType = ExamType.midterm;
  final _marksCtrl = TextEditingController();
  final _totalCtrl = TextEditingController(text: '100');
  final _remarksCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  List<Student> get _students =>
      widget.store.students.where((s) => s.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  List<Subject> get _subjects {
    if (_studentId == null) return widget.store.subjects;
    final student =
        widget.store.students.where((s) => s.id == _studentId).firstOrNull;
    if (student == null) return [];
    return widget.store.subjects
        .where((s) => s.className == student.className)
        .toList();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.store.grades.add(Grade(
      studentId: _studentId!,
      subjectId: _subjectId!,
      marks: double.parse(_marksCtrl.text),
      totalMarks: double.parse(_totalCtrl.text),
      examType: _examType,
      date: _date,
      remarks: _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
    ));
    widget.store.saveGrades();
    widget.onSaved();
    _marksCtrl.clear();
    _remarksCtrl.clear();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grade added successfully!')),
    );
  }

  @override
  void dispose() {
    _marksCtrl.dispose();
    _totalCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Student
            DropdownButtonFormField<String>(
              key: ValueKey(_studentId),
              initialValue: _studentId,
              decoration: const InputDecoration(
                labelText: 'Student',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: _students
                  .map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text('${s.name} (${s.rollNo})')))
                  .toList(),
              onChanged: (v) => setState(() {
                _studentId = v;
                _subjectId = null;
              }),
              validator: (v) => v == null ? 'Select a student' : null,
            ),
            const SizedBox(height: 16),

            // Subject
            DropdownButtonFormField<String>(
              key: ValueKey('$_studentId-$_subjectId'),
              initialValue: _subjectId,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.menu_book_outlined),
              ),
              items: _subjects
                  .map((s) =>
                      DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: _studentId == null
                  ? null
                  : (v) => setState(() => _subjectId = v),
              validator: (v) => v == null ? 'Select a subject' : null,
            ),
            const SizedBox(height: 16),

            // Exam type
            DropdownButtonFormField<ExamType>(
              key: ValueKey(_examType),
              initialValue: _examType,
              decoration: const InputDecoration(
                labelText: 'Exam Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.quiz_outlined),
              ),
              items: ExamType.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                  .toList(),
              onChanged: (v) => setState(() => _examType = v ?? _examType),
            ),
            const SizedBox(height: 16),

            // Marks row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _marksCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Marks Obtained',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.score_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = double.tryParse(v);
                      if (n == null) return 'Invalid';
                      final total = double.tryParse(_totalCtrl.text) ?? 100;
                      if (n < 0 || n > total) return '0–$total';
                      return null;
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('/', style: TextStyle(fontSize: 24)),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _totalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total Marks',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _date = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Exam Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(DateFormat('MMM d, y').format(_date)),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _remarksCtrl,
              decoration: const InputDecoration(
                labelText: 'Remarks (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.comment_outlined),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add),
              label: const Text('Add Grade'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 24),

            // Recent grades
            Text('Recent Grades',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...widget.store.grades.reversed.take(5).map((g) {
              final student = widget.store.students
                  .where((s) => s.id == g.studentId)
                  .firstOrNull;
              final subject = widget.store.subjects
                  .where((s) => s.id == g.subjectId)
                  .firstOrNull;
              return _GradeListTile(
                  grade: g,
                  studentName: student?.name ?? 'Unknown',
                  subjectName: subject?.name ?? 'Unknown',
                  onDelete: () {
                    setState(() => widget.store.grades.remove(g));
                    widget.store.saveGrades();
                  });
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Grade Report Tab ─────────────────────────────────────────────────────────

class _GradeReportTab extends StatefulWidget {
  final StorageService store;
  const _GradeReportTab({required this.store});

  @override
  State<_GradeReportTab> createState() => _GradeReportTabState();
}

class _GradeReportTabState extends State<_GradeReportTab> {
  String? _studentId;

  List<Student> get _students =>
      widget.store.students.where((s) => s.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  List<Grade> get _studentGrades {
    if (_studentId == null) return [];
    return widget.store.grades
        .where((g) => g.studentId == _studentId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, List<Grade>> get _bySubject {
    final map = <String, List<Grade>>{};
    for (final g in _studentGrades) {
      map.putIfAbsent(g.subjectId, () => []).add(g);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final grades = _studentGrades;
    final avg = grades.isEmpty
        ? 0.0
        : grades.map((g) => g.percentage).reduce((a, b) => a + b) /
            grades.length;

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
        if (_studentId != null && grades.isNotEmpty) ...[
          // Average card
          Card(
            color: Color(Grade(
                    studentId: '',
                    subjectId: '',
                    marks: avg,
                    totalMarks: 100,
                    examType: ExamType.finalExam)
                .gradeColor)
                .withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('${avg.toStringAsFixed(1)}%',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Overall Average',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  Column(
                    children: [
                      Text('${grades.length}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Assessments',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        Grade(
                                studentId: '',
                                subjectId: '',
                                marks: avg,
                                totalMarks: 100,
                                examType: ExamType.finalExam)
                            .letterGrade,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text('Grade',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // By subject
          ..._bySubject.entries.map((entry) {
            final subject = widget.store.subjects
                .where((s) => s.id == entry.key)
                .firstOrNull;
            final subGrades = entry.value;
            final subAvg = subGrades
                    .map((g) => g.percentage)
                    .reduce((a, b) => a + b) /
                subGrades.length;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Color(Grade(
                              studentId: '',
                              subjectId: '',
                              marks: subAvg,
                              totalMarks: 100,
                              examType: ExamType.finalExam)
                          .gradeColor)
                          .withValues(alpha: 0.2),
                  child: Text(
                    Grade(
                            studentId: '',
                            subjectId: '',
                            marks: subAvg,
                            totalMarks: 100,
                            examType: ExamType.finalExam)
                        .letterGrade,
                    style: TextStyle(
                        color: Color(Grade(
                                studentId: '',
                                subjectId: '',
                                marks: subAvg,
                                totalMarks: 100,
                                examType: ExamType.finalExam)
                            .gradeColor),
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                title: Text(subject?.name ?? 'Unknown Subject',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${subAvg.toStringAsFixed(1)}% avg · ${subGrades.length} assessment(s)'),
                children: subGrades
                    .map((g) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                          child: Row(
                            children: [
                              Expanded(child: Text(g.examType.label)),
                              Text(
                                  '${g.marks.toInt()}/${g.totalMarks.toInt()}'),
                              const SizedBox(width: 12),
                              Text(
                                '${g.percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                    color: Color(g.gradeColor),
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            );
          }),
        ] else if (_studentId != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No grades recorded for this student.',
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
                  Icon(Icons.grade_outlined,
                      size: 64,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('Select a student to view their grade report',
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

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _GradeListTile extends StatelessWidget {
  final Grade grade;
  final String studentName;
  final String subjectName;
  final VoidCallback onDelete;

  const _GradeListTile({
    required this.grade,
    required this.studentName,
    required this.subjectName,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(grade.gradeColor);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(grade.letterGrade,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
        title: Text(studentName),
        subtitle: Text('$subjectName · ${grade.examType.label}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${grade.marks.toInt()}/${grade.totalMarks.toInt()}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}
