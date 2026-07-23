import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/job.dart';

class JobFilter {
  final String search;
  final String? category;
  final String? state;
  final String sort;

  const JobFilter({
    this.search = '',
    this.category,
    this.state,
    this.sort = 'latest',
  });

  JobFilter copyWith({
    String? search,
    String? category,
    String? state,
    String? sort,
    bool clearCategory = false,
    bool clearState = false,
  }) =>
      JobFilter(
        search:   search   ?? this.search,
        category: clearCategory ? null : (category ?? this.category),
        state:    clearState    ? null : (state    ?? this.state),
        sort:     sort     ?? this.sort,
      );

  Map<String, dynamic> toQuery(int page) => {
        'page': page,
        if (search.isNotEmpty) 'search': search,
        if (category != null)  'category': category,
        if (state != null)     'state': state,
        'sort': sort,
      };

  bool get hasActiveFilters => category != null || state != null || sort != 'latest';

  int get activeFilterCount =>
      (category != null ? 1 : 0) +
      (state != null ? 1 : 0) +
      (sort != 'latest' ? 1 : 0);
}

final jobFilterProvider = StateProvider<JobFilter>((ref) => const JobFilter());

// ─── Pagination state ─────────────────────────────────────────────────────────

class JobListState {
  final List<Job> jobs;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? error;

  const JobListState({
    this.jobs = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.error,
  });

  JobListState copyWith({
    List<Job>? jobs,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? error,
  }) =>
      JobListState(
        jobs:          jobs          ?? this.jobs,
        currentPage:   currentPage   ?? this.currentPage,
        hasMore:       hasMore       ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error:         error,
      );
}

class JobListNotifier extends AutoDisposeNotifier<JobListState> {
  @override
  JobListState build() {
    ref.listen(jobFilterProvider, (_, __) => _reset());
    // Schedule after build() returns so `state` is valid when _fetchPage reads it
    Future.microtask(() => _fetchPage(1));
    return const JobListState(isLoadingMore: true);
  }

  void _reset() {
    state = const JobListState(isLoadingMore: true);
    _fetchPage(1);
  }

  Future<void> _fetchPage(int page) async {
    try {
      final filter = ref.read(jobFilterProvider);
      final res    = await ref.read(dioProvider).get(
            '/jobs',
            queryParameters: filter.toQuery(page),
          );

      final data     = res.data['data'] as List;
      // API returns last_page at root level, not inside meta
      final lastPage = res.data['last_page'] as int? ?? 1;

      final fetched = data
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        jobs:          page == 1 ? fetched : [...state.jobs, ...fetched],
        currentPage:   page,
        hasMore:       page < lastPage,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void loadMore() {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    _fetchPage(state.currentPage + 1);
  }

  void refresh() => _reset();

  void toggleBookmark(int jobId, bool bookmarked) {
    state = state.copyWith(
      jobs: state.jobs
          .map((j) => j.id == jobId ? j.copyWith(isBookmarked: bookmarked) : j)
          .toList(),
    );
  }

  void markApplied(int jobId) {
    state = state.copyWith(
      jobs: state.jobs
          .map((j) => j.id == jobId ? j.copyWith(hasApplied: true) : j)
          .toList(),
    );
  }
}

final jobListProvider =
    AutoDisposeNotifierProvider<JobListNotifier, JobListState>(JobListNotifier.new);
