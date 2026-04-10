import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/auth_models.dart';
import '../../models/misc_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().loadBooks();
      context.read<LibraryProvider>().loadActiveIssues();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _search.dispose();
    super.dispose();
  }

  // ── Add / Edit Book ──────────────────────────────────────────────────────────
  void _showAddBook([Book? existing]) {
    final titleCtrl = TextEditingController(text: existing?.title);
    final authorCtrl = TextEditingController(text: existing?.author);
    final isbnCtrl = TextEditingController(text: existing?.isbn ?? '');
    final catCtrl = TextEditingController(text: existing?.category ?? '');
    final copiesCtrl = TextEditingController(
        text: existing != null ? '${existing.totalCopies}' : '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(existing == null ? 'Add Book' : 'Edit Book',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title *')),
              const SizedBox(height: 12),
              TextField(
                  controller: authorCtrl,
                  decoration: const InputDecoration(labelText: 'Author *')),
              const SizedBox(height: 12),
              TextField(
                  controller: isbnCtrl,
                  decoration: const InputDecoration(labelText: 'ISBN')),
              const SizedBox(height: 12),
              TextField(
                  controller: catCtrl,
                  decoration: const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 12),
              TextField(
                  controller: copiesCtrl,
                  decoration: const InputDecoration(labelText: 'Total Copies'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty ||
                      authorCtrl.text.trim().isEmpty) return;
                  final copies = int.tryParse(copiesCtrl.text.trim()) ?? 1;
                  final data = {
                    'title': titleCtrl.text.trim(),
                    'author': authorCtrl.text.trim(),
                    if (isbnCtrl.text.isNotEmpty) 'isbn': isbnCtrl.text.trim(),
                    if (catCtrl.text.isNotEmpty)
                      'category': catCtrl.text.trim(),
                    'total_copies': copies,
                    'available_copies': existing?.availableCopies ?? copies,
                  };
                  Navigator.pop(ctx);
                  if (existing == null) {
                    await context.read<LibraryProvider>().addBook(data);
                  } else {
                    await context
                        .read<LibraryProvider>()
                        .updateBook(existing.id, data);
                  }
                },
                child: Text(existing == null ? 'Add Book' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Issue Book ────────────────────────────────────────────────────────────────
  void _showIssueBook([Book? preSelected]) {
    final provider = context.read<LibraryProvider>();
    final availableBooks =
        provider.books.where((b) => b.isAvailable).toList();
    final auth = context.read<AuthProvider>();

    String? selBookId = preSelected?.id;
    final borrowerNameCtrl = TextEditingController();
    String selBorrowerType = 'student';
    DateTime dueDate = DateTime.now().add(const Duration(days: 14));

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
                Text('Issue Book',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(selBookId),
                  initialValue: selBookId,
                  decoration: const InputDecoration(labelText: 'Book *'),
                  items: availableBooks
                      .map((b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(
                              '${b.title} (${b.availableCopies} left)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setS(() => selBookId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: borrowerNameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Borrower Name *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(selBorrowerType),
                  initialValue: selBorrowerType,
                  decoration:
                      const InputDecoration(labelText: 'Borrower Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'student', child: Text('Student')),
                    DropdownMenuItem(
                        value: 'teacher', child: Text('Teacher')),
                  ],
                  onChanged: (v) {
                    if (v != null) setS(() => selBorrowerType = v);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Due Date'),
                  subtitle: Text(
                      '${dueDate.day}/${dueDate.month}/${dueDate.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365)),
                    );
                    if (picked != null) setS(() => dueDate = picked);
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (selBookId == null ||
                        borrowerNameCtrl.text.trim().isEmpty) return;
                    final data = {
                      'book_id': selBookId,
                      'borrower_id': auth.profile?.id,
                      'borrower_name': borrowerNameCtrl.text.trim(),
                      'borrower_type': selBorrowerType,
                      'issue_date': DateTime.now()
                          .toIso8601String()
                          .split('T')[0],
                      'due_date':
                          dueDate.toIso8601String().split('T')[0],
                      'issued_by': auth.profile?.id,
                    };
                    Navigator.pop(ctx);
                    try {
                      await context
                          .read<LibraryProvider>()
                          .issueBook(data);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Book issued successfully'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error issuing book: $e'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    }
                  },
                  child: const Text('Issue Book'),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
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
        title: const Text('Library'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Books'), Tab(text: 'Issued')],
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: _tab.index == 0
                  ? () => _showAddBook()
                  : () => _showIssueBook(),
              icon: Icon(_tab.index == 0 ? Icons.add : Icons.book_online),
              label: Text(_tab.index == 0 ? 'Add Book' : 'Issue Book'),
            )
          : null,
      body: TabBarView(
        controller: _tab,
        children: [
          // ── Books tab ───────────────────────────────────────────────────────
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search books…',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) =>
                      context.read<LibraryProvider>().loadBooks(search: v),
                ),
              ),
              Expanded(
                child: provider.loading
                    ? const LoadingWidget()
                    : provider.error != null
                        ? AppErrorWidget(
                            message:
                                'Failed to load books.\n${provider.error}',
                            onRetry: () =>
                                context.read<LibraryProvider>().loadBooks(),
                          )
                        : provider.books.isEmpty
                            ? EmptyState(
                                icon: Icons.local_library_outlined,
                                title: 'No books found',
                                onButton: canEdit ? () => _showAddBook() : null,
                                buttonLabel: 'Add Book',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                itemCount: provider.books.length,
                                itemBuilder: (ctx, i) {
                                  final b = provider.books[i];
                                  return Card(
                                    margin:
                                        const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: b.isAvailable
                                            ? Colors.green
                                                .withValues(alpha: 0.15)
                                            : Colors.red
                                                .withValues(alpha: 0.15),
                                        child: Icon(
                                          b.isAvailable
                                              ? Icons.book
                                              : Icons.book_outlined,
                                          color: b.isAvailable
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      title: Text(b.title),
                                      subtitle: Text(
                                          '${b.author}${b.category != null ? '  •  ${b.category}' : ''}\nAvailable: ${b.availableCopies}/${b.totalCopies}'),
                                      trailing: canEdit
                                          ? PopupMenuButton<String>(
                                              onSelected: (v) async {
                                                if (v == 'edit') {
                                                  _showAddBook(b);
                                                } else if (v == 'issue') {
                                                  _showIssueBook(b);
                                                } else {
                                                  final ok =
                                                      await showConfirmDialog(
                                                          context,
                                                          title: 'Delete Book',
                                                          message:
                                                              'Delete "${b.title}"?');
                                                  if (ok == true &&
                                                      context.mounted) {
                                                    await context
                                                        .read<LibraryProvider>()
                                                        .deleteBook(b.id);
                                                  }
                                                }
                                              },
                                              itemBuilder: (_) => [
                                                const PopupMenuItem(
                                                    value: 'edit',
                                                    child: Text('Edit')),
                                                if (b.isAvailable)
                                                  const PopupMenuItem(
                                                      value: 'issue',
                                                      child:
                                                          Text('Issue Book')),
                                                const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text('Delete')),
                                              ],
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),

          // ── Issued tab ──────────────────────────────────────────────────────
          provider.activeIssues.isEmpty
              ? EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No active issues',
                  onButton: canEdit ? () => _showIssueBook() : null,
                  buttonLabel: 'Issue Book',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.activeIssues.length,
                  itemBuilder: (ctx, i) {
                    final issue = provider.activeIssues[i];
                    final book = provider.books
                        .where((b) => b.id == issue.bookId)
                        .firstOrNull;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: issue.isOverdue
                              ? Colors.red.withValues(alpha: 0.15)
                              : Colors.green.withValues(alpha: 0.15),
                          child: Icon(
                            issue.isOverdue ? Icons.warning : Icons.book,
                            color:
                                issue.isOverdue ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(book?.title ?? 'Unknown Book'),
                        subtitle: Text(
                            '${issue.borrowerName ?? 'Unknown'}  •  Due: ${issue.dueDate.day}/${issue.dueDate.month}/${issue.dueDate.year}'
                            '${issue.isOverdue ? '\nOverdue! Fine: ₹${issue.calculatedFine.toStringAsFixed(0)}' : ''}'),
                        trailing: canEdit
                            ? TextButton(
                                onPressed: () async {
                                  try {
                                    await context
                                        .read<LibraryProvider>()
                                        .returnBook(
                                            issue.id, issue.calculatedFine);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content:
                                            Text('Book returned successfully'),
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content:
                                            Text('Error returning book: $e'),
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    }
                                  }
                                },
                                child: const Text('Return'),
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
