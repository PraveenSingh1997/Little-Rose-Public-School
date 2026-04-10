import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _store = StorageService();
  AnnouncementType? _typeFilter;

  List<Announcement> get _filtered {
    final list = _store.announcements.where((a) {
      return _typeFilter == null || a.type == _typeFilter;
    }).toList()
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.date.compareTo(a.date);
      });
    return list;
  }

  void _openForm({Announcement? announcement}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AnnouncementForm(
        existing: announcement,
        onSave: (a) {
          setState(() {
            if (announcement != null) {
              final i =
                  _store.announcements.indexWhere((x) => x.id == a.id);
              if (i != -1) _store.announcements[i] = a;
            } else {
              _store.announcements.add(a);
            }
          });
          _store.saveAnnouncements();
        },
      ),
    );
  }

  void _delete(Announcement a) {
    setState(() => _store.announcements.remove(a));
    _store.saveAnnouncements();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Announcement deleted'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          setState(() => _store.announcements.add(a));
          _store.saveAnnouncements();
        },
      ),
    ));
  }

  void _togglePin(Announcement a) {
    setState(() => a.isPinned = !a.isPinned);
    _store.saveAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
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
            title: const Text('Announcements'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _typeFilter == null,
                        onSelected: (_) => setState(() => _typeFilter = null),
                      ),
                    ),
                    ...AnnouncementType.values.map((t) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Text(t.icon),
                            label: Text(t.label),
                            selected: _typeFilter == t,
                            onSelected: (_) => setState(() =>
                                _typeFilter = _typeFilter == t ? null : t),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
          if (_filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.campaign_outlined,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('No announcements yet',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _openForm(),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Announcement'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final a = _filtered[i];
                  return _AnnouncementCard(
                    announcement: a,
                    onEdit: () => _openForm(announcement: a),
                    onDelete: () => _delete(a),
                    onTogglePin: () => _togglePin(a),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('New Announcement'),
      ),
    );
  }
}

// ─── Announcement Card ────────────────────────────────────────────────────────

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const _AnnouncementCard({
    required this.announcement,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = Color(announcement.type.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color bar
            Container(height: 4, color: color),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(announcement.type.icon,
                                style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Text(announcement.type.label,
                                style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (announcement.isPinned)
                        Icon(Icons.push_pin, size: 16, color: cs.primary),
                      PopupMenuButton(
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'pin',
                            child: Text(announcement.isPinned
                                ? 'Unpin'
                                : 'Pin to top'),
                          ),
                          const PopupMenuItem(
                              value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(
                              value: 'delete', child: Text('Delete')),
                        ],
                        onSelected: (v) {
                          if (v == 'pin') onTogglePin();
                          if (v == 'edit') onEdit();
                          if (v == 'delete') onDelete();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(announcement.title,
                      style: tt.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(announcement.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(announcement.author,
                          style: tt.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant)),
                      const Spacer(),
                      Icon(Icons.schedule,
                          size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, y').format(announcement.date),
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final color = Color(announcement.type.colorValue);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${announcement.type.icon} ${announcement.type.label}',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                if (announcement.isPinned)
                  const Icon(Icons.push_pin, size: 18),
              ],
            ),
            const SizedBox(height: 16),
            Text(announcement.title,
                style:
                    tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(announcement.author,
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(announcement.date),
                  style:
                      tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(announcement.content, style: tt.bodyLarge),
          ],
        ),
      ),
    );
  }
}

// ─── Announcement Form ────────────────────────────────────────────────────────

class _AnnouncementForm extends StatefulWidget {
  final Announcement? existing;
  final void Function(Announcement) onSave;

  const _AnnouncementForm({this.existing, required this.onSave});

  @override
  State<_AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends State<_AnnouncementForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title, _content, _author;
  late AnnouncementType _type;
  late bool _pinned;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _title = TextEditingController(text: a?.title);
    _content = TextEditingController(text: a?.content);
    _author = TextEditingController(text: a?.author ?? 'Admin');
    _type = a?.type ?? AnnouncementType.general;
    _pinned = a?.isPinned ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _author.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(Announcement(
      id: widget.existing?.id,
      title: _title.text.trim(),
      content: _content.text.trim(),
      author: _author.text.trim(),
      type: _type,
      isPinned: _pinned,
      date: widget.existing?.date ?? DateTime.now(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, ctrl) => Form(
          key: _formKey,
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(isEdit ? 'Edit Announcement' : 'New Announcement',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _content,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _author,
                  decoration: const InputDecoration(
                    labelText: 'Author / Department',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ),
              // Type
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<AnnouncementType>(
                  key: ValueKey(_type),
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  items: AnnouncementType.values
                      .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text('${t.icon}  ${t.label}')))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? _type),
                ),
              ),
              // Pin switch
              Card(
                child: SwitchListTile(
                  title: const Text('Pin to top'),
                  subtitle: const Text('Pinned announcements always appear first'),
                  value: _pinned,
                  onChanged: (v) => setState(() => _pinned = v),
                  secondary: const Icon(Icons.push_pin_outlined),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submit,
                icon: Icon(isEdit ? Icons.save_outlined : Icons.send_outlined),
                label: Text(isEdit ? 'Save Changes' : 'Post Announcement'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
