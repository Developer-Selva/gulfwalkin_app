import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/error_handler.dart';
import '../../core/models/job_alert.dart';
import '../../shared/theme/app_colors.dart';
import 'job_alerts_provider.dart';

class JobAlertsScreen extends ConsumerWidget {
  const JobAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(jobAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Job Alerts', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Alert'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text(e.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(jobAlertsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(jobAlertsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              // ── "Notify all new jobs" master toggle ──────────────────────
              _NotifyAllCard(
                enabled: data.notifyAllNewJobs,
                hasCustomAlerts: data.alerts.isNotEmpty,
                onToggle: (val) async {
                  try {
                    await ref.read(jobAlertsProvider.notifier).toggleNotifyAll(val);
                  } on DioException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(handleDioError(e)),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  }
                },
              ),
              const SizedBox(height: 20),

              // ── Custom alerts section ─────────────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 2, bottom: 10),
                child: Text(
                  'Custom Alerts',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              if (data.alerts.isEmpty)
                _NoCustomAlerts(onAdd: () => _showCreateSheet(context, ref))
              else
                for (final alert in data.alerts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AlertCard(
                      alert: alert,
                      onDelete: () => _delete(context, ref, alert),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateAlertSheet(ref: ref),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, JobAlert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Alert'),
        content: const Text('This alert will no longer send you notifications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(jobAlertsProvider.notifier).delete(alert.id);
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(handleDioError(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

// ─── Notify All toggle card ───────────────────────────────────────────────────

class _NotifyAllCard extends StatelessWidget {
  final bool enabled;
  final bool hasCustomAlerts;
  final ValueChanged<bool> onToggle;

  const _NotifyAllCard({
    required this.enabled,
    required this.hasCustomAlerts,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (enabled ? AppColors.primary : AppColors.textHint)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: enabled ? AppColors.primary : AppColors.textHint,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notify all new jobs',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    enabled
                        ? 'You\'ll be notified when any new job is posted'
                        : hasCustomAlerts
                            ? 'Turned off — only your custom alerts below are active'
                            : 'Enable to get notified for every new job',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: onToggle,
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── No custom alerts placeholder ────────────────────────────────────────────

class _NoCustomAlerts extends StatelessWidget {
  final VoidCallback onAdd;
  const _NoCustomAlerts({required this.onAdd});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'No custom alerts yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create an alert for specific keywords,\ncategory or location.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create My First Alert'),
            ),
          ],
        ),
      );
}

// ─── Alert Card ───────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final JobAlert alert;
  final VoidCallback onDelete;
  const _AlertCard({required this.alert, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final tags = <String>[
      if (alert.keywords != null) alert.keywords!,
      if (alert.category != null) alert.category!,
      if (alert.location != null) alert.location!,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active_outlined,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags.map((t) => _Tag(label: t)).toList(),
                  ),
                  if (tags.isEmpty)
                    const Text('All new jobs',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 6),
                  const Text(
                    'You\'ll be notified when matching jobs are posted',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.textHint, size: 20),
              tooltip: 'Delete alert',
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary)),
      );
}

// ─── Create Alert Sheet ───────────────────────────────────────────────────────

class _CreateAlertSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _CreateAlertSheet({required this.ref});

  @override
  ConsumerState<_CreateAlertSheet> createState() => _CreateAlertSheetState();
}

class _CreateAlertSheetState extends ConsumerState<_CreateAlertSheet> {
  final _keywordsCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _keywordsCtrl.dispose();
    _locationCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final kw  = _keywordsCtrl.text.trim();
    final loc = _locationCtrl.text.trim();
    final cat = _categoryCtrl.text.trim();

    if (kw.isEmpty && loc.isEmpty && cat.isEmpty) {
      setState(() => _error = 'Fill in at least one field.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(jobAlertsProvider.notifier).create(
        keywords: kw.isEmpty ? null : kw,
        location: loc.isEmpty ? null : loc,
        category: cat.isEmpty ? null : cat,
      );
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      setState(() { _error = handleDioError(e); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('New Job Alert',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'We\'ll send you a push notification when a matching job is posted.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _keywordsCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Keywords',
              hintText: 'e.g. Driver, Chef, Electrician',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _categoryCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Category',
              hintText: 'e.g. Driving, Hospitality, Construction',
              prefixIcon: Icon(Icons.category_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationCtrl,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              labelText: 'Location',
              hintText: 'e.g. Dubai, UAE',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Create Alert',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
