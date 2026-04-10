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
                  decoration:
                      const InputDecoration(labelText: 'Title *')),
              const SizedBox(height: 12),
              TextField(
                  controller: authorCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Author *')),
              const SizedBox(height: 12),
              TextField(
                  controller: isbnCtrl,
                  decoration: const InputDecoration(labelText: 'ISBN')),
              const SizedBox(height: 12),
              TextField(
                  controller: catCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 12),
              TextField(
                  controller: copiesCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Total Copies'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty ||
                      authorCtrl.text.trim().isEmpty) {
                    return;
                  }
                  final copies =
                      int.tryParse(copiesCtrl.text.trim()) ?? 1;
                  final data = {
                    'title': titleCtrl.text.trim(),
                    'author': authorCtrl.text.trim(),
                    if (isbnCtrl.text.isNotEmpty)
                      'isbn': isbnCtrl.text.trim(),
                    if (catCtrl.text.isNotEmpty)
                      'category': catCtrl.text.trim(),
                    'total_copies': copies,
                    'available_copies':
                        existing?.availableCopies ?? copies,
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
                child:
                    Text(existing == null ? 'Add Book' : 'Save Changes'),
              ),
            ],
          ),
        ),
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
              onPressed: () => _showAddBook(),
              icon: const Icon(Icons.add),
              label: const Text('Add Book'),
            )
          : null,
      body: TabBarView(
        controller: _tab,
        children: [
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
                    : provider.books.isEmpty
                        ? EmptyState(
                            icon: Icons.local_library_outlined,
                            title: 'No books found',
                            onButton:
                                canEdit ? () => _showAddBook() : null,
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
                                    child: Icon(
                                      b.isAvailable
                                          ? Icons.book
                                          : Icons.book_outlined,
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
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit')),
                                            PopupMenuItem(
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
          provider.activeIssues.isEmpty
              ? const EmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No active issues',
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
                            issue.isOverdue
                                ? Icons.warning
                                : Icons.book,
                            color: issue.isOverdue
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        title: Text(book?.title ?? 'Unknown Book'),
                        subtitle: Text(
                            '${issue.borrowerName ?? 'Unknown'}  •  Due: ${issue.dueDate.day}/${issue.dueDate.month}/${issue.dueDate.year}'
                            '${issue.isOverdue ? '\nOverdue! Fine: ₹${issue.calculatedFine.toStringAsFixed(0)}' : ''}'),
                        trailing: canEdit
                            ? TextButton(
                                onPressed: () async {
                                  await context
                                      .read<LibraryProvider>()
                                      .returnBook(issue.id,
                                          issue.calculatedFine);
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
