import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/application.dart';
import '../../shared/theme/app_colors.dart';
import 'applications_provider.dart';

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(applicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (state.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${state.items.length} applied',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      ),
      body: _Body(state: state),
    );
  }
}

class _Body extends ConsumerWidget {
  final ApplicationsState state;
  const _Body({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoadingMore && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 56, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                'Could not load applications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref.read(applicationsProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(applicationsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == state.items.length) {
            // Load-more trigger
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(applicationsProvider.notifier).loadMore();
            });
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ApplicationCard(application: state.items[i]),
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Application application;
  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final job = application.job;

    return Card(
      child: InkWell(
        onTap: job != null
            ? () => context.push('/jobs/${job.id}')
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _JobLogo(url: job?.image1Url),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job?.title ?? 'Job no longer available',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (job != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 13, color: AppColors.textHint),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  [job.location, job.country]
                                      .whereType<String>()
                                      .join(', '),
                                  style: const TextStyle(
                                      color: AppColors.textHint, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (job.salaryRange != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.attach_money,
                                    size: 13, color: AppColors.secondary),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    job.salaryRange!,
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _StatusTimeline(status: application.status),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(
                    'Applied ${_formatDate(application.appliedAt)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  if (job != null)
                    const Row(
                      children: [
                        Text('View job',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500)),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 11, color: AppColors.primary),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(String iso) {
    try {
      final dt  = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'today';
      if (diff.inDays == 1) return 'yesterday';
      if (diff.inDays < 7)  return '${diff.inDays} days ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
      return '${(diff.inDays / 365).floor()} years ago';
    } catch (_) {
      return iso;
    }
  }
}

class _JobLogo extends StatelessWidget {
  final String? url;
  const _JobLogo({this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url!,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(),
              errorWidget: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 52,
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.business, color: AppColors.textHint),
      );
}

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    // step indices: 0=Applied, 1=Under Review, 2=Decision
    final stepReached = switch (status) {
      'reviewed'    => 1,
      'shortlisted' => 2,
      'rejected'    => 2,
      _             => 0, // pending
    };
    final isRejected    = status == 'rejected';
    final isShortlisted = status == 'shortlisted';

    return Row(
      children: [
        const _StepNode(
          label: 'Applied',
          state: _NodeState.done,
        ),
        _StepLine(active: stepReached >= 1),
        _StepNode(
          label: 'In Review',
          state: stepReached >= 1 ? _NodeState.done : _NodeState.idle,
        ),
        _StepLine(active: stepReached >= 2),
        _StepNode(
          label: isShortlisted
              ? 'Shortlisted'
              : isRejected
                  ? 'Rejected'
                  : 'Decision',
          state: stepReached >= 2
              ? (isRejected ? _NodeState.rejected : _NodeState.done)
              : _NodeState.idle,
        ),
      ],
    );
  }
}

enum _NodeState { idle, done, rejected }

class _StepNode extends StatelessWidget {
  final String label;
  final _NodeState state;
  const _StepNode({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final Color color = switch (state) {
      _NodeState.done     => AppColors.statusShortlisted,
      _NodeState.rejected => AppColors.statusRejected,
      _NodeState.idle     => AppColors.textHint,
    };
    final IconData icon = switch (state) {
      _NodeState.done     => Icons.check_circle_rounded,
      _NodeState.rejected => Icons.cancel_rounded,
      _NodeState.idle     => Icons.radio_button_unchecked,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: state == _NodeState.idle
                ? FontWeight.w400
                : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({required this.active});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 18),
          color: active
              ? AppColors.statusShortlisted.withValues(alpha: 0.5)
              : AppColors.divider,
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_outlined,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('No Applications Yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            const Text(
              'Jobs you apply for will appear here.\nStart browsing and apply to get noticed by employers.',
              style: TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
