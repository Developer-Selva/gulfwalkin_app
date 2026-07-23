import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/theme/app_colors.dart';
import 'bookmarks_provider.dart';

class SavedJobsScreen extends ConsumerWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookmarksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Jobs',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (state.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${state.items.length} saved',
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
  final BookmarksState state;
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
                'Could not load saved jobs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref.read(bookmarksProvider.notifier).refresh(),
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
      onRefresh: () async => ref.read(bookmarksProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == state.items.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(bookmarksProvider.notifier).loadMore();
            });
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = state.items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DismissibleCard(
              key: ValueKey(item.bookmarkId),
              item: item,
              onDismissed: () =>
                  ref.read(bookmarksProvider.notifier).removeBookmark(item.job.id),
            ),
          );
        },
      ),
    );
  }
}

class _DismissibleCard extends StatelessWidget {
  final BookmarkItem item;
  final VoidCallback onDismissed;

  const _DismissibleCard({
    super.key,
    required this.item,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.bookmarkId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_remove_outlined,
                color: AppColors.error, size: 28),
            SizedBox(height: 4),
            Text('Remove',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onDismissed: (_) {
        onDismissed();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${item.job.title}"'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: _SavedJobCard(item: item),
    );
  }
}

class _SavedJobCard extends StatelessWidget {
  final BookmarkItem item;
  const _SavedJobCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final job = item.job;

    return Card(
      child: InkWell(
        onTap: () => context.push('/jobs/${job.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _JobLogo(url: job.employer?.logoUrl ?? job.image1Url),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (job.employer != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        job.employer!.companyName,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${job.location}, ${job.country}',
                            style: const TextStyle(
                                color: AppColors.textHint, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (job.salaryRange != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.attach_money,
                              size: 13, color: AppColors.secondary),
                          const SizedBox(width: 2),
                          Text(
                            job.salaryRange!,
                            style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.bookmark_added_outlined,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          'Saved ${_formatDate(item.savedAt)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint),
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
      return '${(diff.inDays / 30).floor()} months ago';
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
                color: AppColors.warning.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_border_rounded,
                  size: 48, color: AppColors.warning),
            ),
            const SizedBox(height: 24),
            const Text('No Saved Jobs',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            const Text(
              'Tap the bookmark icon on any job listing to save it here for later.',
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
