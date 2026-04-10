import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../shell_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().profile;
    _nameCtrl = TextEditingController(text: profile?.fullName);
    _phoneCtrl = TextEditingController(text: profile?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updates = <String, dynamic>{};
    final profile = context.read<AuthProvider>().profile;
    if (_nameCtrl.text.trim().isNotEmpty &&
        _nameCtrl.text.trim() != profile?.fullName) {
      updates['full_name'] = _nameCtrl.text.trim();
    }
    if (_phoneCtrl.text.trim() != (profile?.phone ?? '')) {
      updates['phone'] = _phoneCtrl.text.trim();
    }
    if (updates.isNotEmpty) {
      await context.read<AuthProvider>().updateProfile(updates);
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final isWide = MediaQuery.of(context).size.width >= 720;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    ShellScreen.scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Text('My Profile'),
        actions: [
          if (_editing)
            TextButton(onPressed: _save, child: const Text('Save'))
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: profile == null
          ? const LoadingWidget()
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Column(
                    children: [
                      AvatarWidget(
                        photoUrl: profile.avatarUrl,
                        initials: profile.initials,
                        radius: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.fullName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      RoleBadge(role: profile.role.name),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account Information',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Divider(height: 24),
                        InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: profile.email,
                        ),
                        const SizedBox(height: 8),
                        if (_editing) ...[
                          TextField(
                            controller: _nameCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Full Name'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Phone'),
                            keyboardType: TextInputType.phone,
                          ),
                        ] else ...[
                          InfoRow(
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            value: profile.fullName,
                          ),
                          InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: profile.phone ?? '—',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Security',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Divider(height: 24),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.lock_outlined),
                          title: const Text('Change Password'),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 14),
                          onTap: () async {
                            final confirm = await showConfirmDialog(
                              context,
                              title: 'Reset Password',
                              message:
                                  'A password reset link will be sent to ${profile.email}',
                              confirmText: 'Send Link',
                              isDestructive: false,
                            );
                            if (confirm == true && context.mounted) {
                              await context
                                  .read<AuthProvider>()
                                  .resetPassword(profile.email);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Password reset email sent')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
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
                  icon: Icon(Icons.logout, color: cs.error),
                  label: Text('Sign Out',
                      style: TextStyle(color: cs.error)),
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.error)),
                ),
              ],
            ),
    );
  }
}
