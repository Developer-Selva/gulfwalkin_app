import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/models/job.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/loading_skeleton.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class _EmployerJobsState {
  final List<Job>    jobs;
  final bool         isLoading;
  final bool         isLoadingMore;
  final String?      error;
  final int          currentPage;
  final int          lastPage;

  const _EmployerJobsState({
    this.jobs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.lastPage = 1,
  });

  bool get hasMore => currentPage < lastPage;

  _EmployerJobsState copyWith({
    List<Job>? jobs,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? lastPage,
  }) => _EmployerJobsState(
        jobs: jobs ?? this.jobs,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
        currentPage: currentPage ?? this.currentPage,
        lastPage: lastPage ?? this.lastPage,
      );
}

class _EmployerJobsNotifier extends StateNotifier<_EmployerJobsState> {
  final Ref _ref;

  _EmployerJobsNotifier(this._ref) : super(const _EmployerJobsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _ref.read(dioProvider).get('/employer/jobs');
      final data = res.data as Map<String, dynamic>;
      final items = (data['data'] as List)
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        isLoading: false,
        jobs: items,
        currentPage: data['current_page'] as int,
        lastPage: data['last_page'] as int,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final res = await _ref
          .read(dioProvider)
          .get('/employer/jobs', queryParameters: {'page': state.currentPage + 1});
      final data = res.data as Map<String, dynamic>;
      final newItems = (data['data'] as List)
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        isLoadingMore: false,
        jobs: [...state.jobs, ...newItems],
        currentPage: data['current_page'] as int,
        lastPage: data['last_page'] as int,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final _employerJobsProvider =
    StateNotifierProvider.autoDispose<_EmployerJobsNotifier, _EmployerJobsState>(
  (ref) => _EmployerJobsNotifier(ref),
);

// ─── Screen ───────────────────────────────────────────────────────────────────

class EmployerMyJobsScreen extends ConsumerStatefulWidget {
  const EmployerMyJobsScreen({super.key});

  @override
  ConsumerState<EmployerMyJobsScreen> createState() => _EmployerMyJobsScreenState();
}

class _EmployerMyJobsScreenState extends ConsumerState<EmployerMyJobsScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(_employerJobsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_employerJobsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Job Listings',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(_EmployerJobsState state) {
    if (state.isLoading) {
      return const JobListSkeleton();
    }

    if (state.error != null && state.jobs.isEmpty) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(_employerJobsProvider.notifier).load(),
      );
    }

    if (state.jobs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_off_outlined,
                size: 64, color: AppColors.textHint),
            SizedBox(height: 16),
            Text('No job listings yet',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
            SizedBox(height: 6),
            Text('Post jobs from the web dashboard.',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textHint)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(_employerJobsProvider.notifier).load(),
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: state.jobs.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i >= state.jobs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final job = state.jobs[i];
          return _EmployerJobCard(
            job: job,
            onTap: () => context.push('/jobs/${job.id}?employer=1'),
          );
        },
      ),
    );
  }
}

// ─── Employer job card ────────────────────────────────────────────────────────

class _EmployerJobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const _EmployerJobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo / placeholder
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.work_outline_rounded,
                          color: AppColors.primary, size: 24),
                    ),
                  ),
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: AppColors.textHint),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${job.location}, ${job.country}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textHint),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: job.status ?? 'active'),
                ],
              ),
              if (job.salaryRange != null || job.vacancies > 0) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (job.salaryRange != null) ...[
                      const Icon(Icons.attach_money,
                          size: 13, color: AppColors.secondary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          job.salaryRange!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.people_outline,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(
                      '${job.vacancies} vacancies',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textHint),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active'   => ('Active', const Color(0xFF2E7D32)),
      'inactive' => ('Inactive', AppColors.textHint),
      'draft'    => ('Draft', AppColors.warning),
      'expired'  => ('Expired', AppColors.error),
      _          => (status, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
