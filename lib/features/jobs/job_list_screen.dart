import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/api/api_client.dart';
import '../../core/api/error_handler.dart';
import '../../core/models/job.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/job_card.dart';
import '../../shared/widgets/loading_skeleton.dart';
import 'job_filter_sheet.dart';
import 'job_list_provider.dart';

class JobListScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const JobListScreen({super.key, this.initialCategory});

  @override
  ConsumerState<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends ConsumerState<JobListScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final current = ref.read(jobFilterProvider);
        if (current.category != widget.initialCategory) {
          ref.read(jobFilterProvider.notifier).state =
              const JobFilter().copyWith(category: widget.initialCategory);
        }
      });
    }
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(JobListScreen old) {
    super.didUpdateWidget(old);
    // StatefulShellRoute keeps this widget alive across tab switches.
    // When the home screen navigates to /jobs?category=X, GoRouter rebuilds
    // this widget with a new initialCategory but initState() never re-runs —
    // so we apply the new category filter here instead.
    if (old.initialCategory != widget.initialCategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.initialCategory != null) {
          ref.read(jobFilterProvider.notifier).state =
              const JobFilter().copyWith(category: widget.initialCategory);
        } else {
          ref.read(jobFilterProvider.notifier).state = const JobFilter();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(jobListProvider.notifier).loadMore();
    }
  }

  void _submitSearch(String value) {
    ref.read(jobFilterProvider.notifier).state =
        ref.read(jobFilterProvider).copyWith(search: value);
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const JobFilterSheet(),
    );
  }

  void _clearCategory() {
    ref.read(jobFilterProvider.notifier).state =
        ref.read(jobFilterProvider).copyWith(clearCategory: true);
  }

  void _clearState() {
    ref.read(jobFilterProvider.notifier).state =
        ref.read(jobFilterProvider).copyWith(clearState: true);
  }

  void _clearSort() {
    ref.read(jobFilterProvider.notifier).state =
        ref.read(jobFilterProvider).copyWith(sort: 'latest');
  }

  void _clearAll() {
    _searchCtrl.clear();
    ref.read(jobFilterProvider.notifier).state = const JobFilter();
  }

  void _share(Job job) {
    final company = job.employer?.companyName ?? job.company;
    final text = StringBuffer();
    text.write(job.title);
    if (company != null) text.write(' at $company');
    text.write('\n${job.location}, ${job.country}');
    if (job.salaryRange != null) text.write('\n\$ ${job.salaryRange}');
    text.write('\n\nApply on Gulfwalkin: https://gulfwalkin.com/jobs/${job.id}');
    SharePlus.instance.share(ShareParams(text: text.toString()));
  }

  Future<void> _quickApply(Job job) async {
    try {
      await ref.read(dioProvider).post('/jobs/${job.id}/apply');
      ref.read(jobListProvider.notifier).markApplied(job.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Application submitted!'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(handleDioError(e)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter    = ref.watch(jobFilterProvider);
    final listState = ref.watch(jobListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // Show back arrow only when this screen is pushed on top of something
        automaticallyImplyLeading: true,
        title: const Text('Browse Jobs',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (filter.hasActiveFilters)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear all',
                  style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
          IconButton(
            icon: Badge(
              isLabelVisible: filter.hasActiveFilters,
              label: Text('${filter.activeFilterCount}'),
              child: const Icon(Icons.tune_rounded),
            ),
            onPressed: _openFilters,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            52 + (filter.hasActiveFilters ? 44 : 0),
          ),
          child: Column(
            children: [
              // ── Search bar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _submitSearch,
                  decoration: InputDecoration(
                    hintText: 'Search jobs, companies...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _submitSearch('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                ),
              ),

              // ── Active filter chips ────────────────────────────────────────
              if (filter.hasActiveFilters)
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    children: [
                      if (filter.category != null)
                        _ActiveChip(
                          label: filter.category!,
                          icon: Icons.category_outlined,
                          onRemove: _clearCategory,
                        ),
                      if (filter.state != null)
                        _ActiveChip(
                          label: filter.state!,
                          icon: Icons.location_on_outlined,
                          onRemove: _clearState,
                        ),
                      if (filter.sort != 'latest')
                        _ActiveChip(
                          label: 'Highest Salary',
                          icon: Icons.trending_up,
                          onRemove: _clearSort,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      body: _buildBody(listState, filter),
    );
  }

  Widget _buildBody(JobListState state, JobFilter filter) {
    if (state.jobs.isEmpty && state.isLoadingMore) {
      return const JobListSkeleton();
    }

    if (state.jobs.isEmpty && state.error != null) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(jobListProvider.notifier).refresh(),
      );
    }

    if (state.jobs.isEmpty) {
      return EmptyState(
        title:      filter.hasActiveFilters ? 'No matching jobs' : 'No jobs yet',
        subtitle:   filter.hasActiveFilters
            ? 'Try adjusting your search or filters'
            : 'Check back later for new opportunities',
        icon:       Icons.work_off_outlined,
        actionLabel: filter.hasActiveFilters ? 'Clear Filters' : null,
        onAction:   filter.hasActiveFilters ? _clearAll : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.read(jobListProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding:    const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount:  state.jobs.length + (state.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == state.jobs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final job = state.jobs[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: JobCard(
              job:    job,
              onTap:  () => context.push('/jobs/${job.id}'),
              onBookmark: () {
                ref.read(jobListProvider.notifier)
                    .toggleBookmark(job.id, !job.isBookmarked);
              },
              onShare:       () => _share(job),
              onQuickApply:  job.hasApplied ? null : () => _quickApply(job),
            ),
          );
        },
      ),
    );
  }
}

// ── Active filter chip ────────────────────────────────────────────────────────

class _ActiveChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onRemove;

  const _ActiveChip({
    required this.label,
    required this.icon,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close_rounded, size: 13, color: AppColors.primary),
              ),
            ],
          ),
        ),
      );
}
