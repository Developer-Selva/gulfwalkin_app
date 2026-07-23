import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/error_handler.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/current_user_provider.dart';
import '../../shared/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Profile header ───────────────────────────────────────────────
          userAsync.whenOrNull(
            data: (user) => user != null
                ? _ProfileHeader(
                    name:  user.fullName,
                    email: user.email,
                    photoUrl: user.photoUrl,
                    score: user.profileScore,
                  )
                : const SizedBox.shrink(),
          ) ?? const SizedBox.shrink(),

          const SizedBox(height: 20),

          // ── Account ──────────────────────────────────────────────────────
          _SectionGroup(
            label: 'Account',
            tiles: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                iconColor: AppColors.primary,
                title: 'My Profile',
                subtitle: 'Edit your personal and career info',
                onTap: () => context.go('/profile'),
              ),
              _SettingsTile(
                icon: Icons.notifications_active_outlined,
                iconColor: const Color(0xFFF57C00),
                title: 'Job Alerts',
                subtitle: 'Get notified when matching jobs are posted',
                onTap: () => context.push('/job-alerts'),
              ),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                iconColor: const Color(0xFF00897B),
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const _ChangePasswordSheet(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Support ──────────────────────────────────────────────────────
          _SectionGroup(
            label: 'Support',
            tiles: [
              _SettingsTile(
                icon: Icons.mail_outline_rounded,
                iconColor: AppColors.secondary,
                title: 'Contact Us',
                subtitle: 'Get help or send us a message',
                onTap: () => context.push('/contact'),
              ),
              _SettingsTile(
                icon: Icons.star_outline_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Rate & Feedback',
                subtitle: 'Share your experience with us',
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useRootNavigator: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const AppFeedbackSheet(),
                ),
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'About Us',
                subtitle: 'Learn more about Gulfwalkin',
                onTap: () => context.push('/cms/about'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Legal ────────────────────────────────────────────────────────
          _SectionGroup(
            label: 'Legal',
            tiles: [
              _SettingsTile(
                icon: Icons.description_outlined,
                iconColor: AppColors.warning,
                title: 'Terms & Conditions',
                onTap: () => context.push('/cms/terms'),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: const Color(0xFF7B1FA2),
                title: 'Privacy Policy',
                onTap: () => context.push('/cms/privacy'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Danger zone ──────────────────────────────────────────────────
          _SectionGroup(
            label: 'Session',
            tiles: [
              _SettingsTile(
                icon: Icons.logout_rounded,
                iconColor: AppColors.error,
                title: 'Sign Out',
                titleColor: AppColors.error,
                onTap: () => _confirmLogout(context, ref),
              ),
              _SettingsTile(
                icon: Icons.delete_forever_outlined,
                iconColor: AppColors.error,
                title: 'Delete Account',
                titleColor: AppColors.error,
                subtitle: 'Permanently remove your data',
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── App version ───────────────────────────────────────────────────
          const Center(
            child: Column(
              children: [
                Text('Gulfwalkin',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                SizedBox(height: 2),
                Text('Version 1.0.0',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'To permanently delete your account and all data, please contact our support team at support@gulfwalkin.com.\n\nWe will process your request within 7 business days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.push('/contact');
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      // Use dialogContext (not the outer context) for Navigator.pop so we
      // pop the dialog's own route, not the shell's navigator.
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // logout() clears tokens and sets auth state to unauthenticated.
      // The router's refreshListenable re-runs redirect and navigates to
      // /login automatically — no manual context.go needed.
      await ref.read(authProvider.notifier).logout();
    }
  }
}

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final int score;

  const _ProfileHeader({
    required this.name,
    required this.email,
    this.photoUrl,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage: photoUrl != null
                ? NetworkImage(photoUrl!)
                : null,
            child: photoUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 5,
                          backgroundColor: AppColors.surfaceVariant,
                          color: _scoreColor(score),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$score%',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _scoreColor(score)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ],
      ),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 70) return AppColors.success;
    if (s >= 50) return const Color(0xFF3B82F6);
    if (s >= 30) return AppColors.warning;
    return AppColors.error;
  }
}

// ── Section group ─────────────────────────────────────────────────────────────

class _SectionGroup extends StatelessWidget {
  final String label;
  final List<_SettingsTile> tiles;

  const _SectionGroup({required this.label, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.8),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i < tiles.length - 1)
                  const Divider(height: 1, indent: 56, endIndent: 0),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Change password sheet ─────────────────────────────────────────────────────

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew     = true;
  bool _obscureConfirm = true;
  bool _loading        = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await ref.read(dioProvider).put('/employee/profile', data: {
        'current_password':      _currentCtrl.text,
        'password':              _newCtrl.text,
        'password_confirmation': _confirmCtrl.text,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['message'] as String? ?? 'Failed to update password.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Change Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _currentCtrl,
              obscureText: _obscureCurrent,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _newCtrl,
              obscureText: _obscureNew,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 8) return 'Minimum 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v != _newCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Update Password',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single tile ───────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppColors.textPrimary),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: titleColor?.withValues(alpha: 0.6) ?? AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App Feedback sheet ───────────────────────────────────────────────────────

class AppFeedbackSheet extends ConsumerStatefulWidget {
  const AppFeedbackSheet({super.key});

  @override
  ConsumerState<AppFeedbackSheet> createState() => _AppFeedbackSheetState();
}

class _AppFeedbackSheetState extends ConsumerState<AppFeedbackSheet> {
  int _rating = 0;
  final _msgCtrl = TextEditingController();
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(dioProvider).post('/app-feedback', data: {
        'rating': _rating,
        if (_msgCtrl.text.trim().isNotEmpty) 'message': _msgCtrl.text.trim(),
        'app_version': '1.0.0',
      });
      setState(() { _loading = false; _submitted = true; });
    } on DioException catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(handleDioError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: _submitted ? _buildThanks() : _buildForm(),
    );
  }

  Widget _buildThanks() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 52),
        const SizedBox(height: 12),
        const Text('Thank You!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Your feedback helps us improve Gulfwalkin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Rate the App',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('How was your experience with Gulfwalkin?',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 18),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    _rating >= star ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 42,
                  ),
                ),
              );
            }),
          ),
        ),
        if (_rating > 0) ...[
          const SizedBox(height: 4),
          Center(
            child: Text(
              ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_rating],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _msgCtrl,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Tell us more (optional)',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit Feedback',
                    style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
