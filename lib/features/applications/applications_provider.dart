import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/application.dart';

class ApplicationsState {
  final List<Application> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? error;

  const ApplicationsState({
    this.items = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.error,
  });

  ApplicationsState copyWith({
    List<Application>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? error,
  }) =>
      ApplicationsState(
        items:         items         ?? this.items,
        currentPage:   currentPage   ?? this.currentPage,
        hasMore:       hasMore       ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error:         error,
      );
}

class ApplicationsNotifier extends AutoDisposeNotifier<ApplicationsState> {
  @override
  ApplicationsState build() {
    Future.microtask(() => _fetchPage(1));
    return const ApplicationsState(isLoadingMore: true);
  }

  Future<void> _fetchPage(int page) async {
    try {
      final res = await ref.read(dioProvider).get(
        '/employee/applications',
        queryParameters: {'page': page},
      );

      final data     = res.data['data'] as List;
      final lastPage = res.data['last_page'] as int? ?? 1;
      final fetched  = data
          .map((e) => Application.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        items:         page == 1 ? fetched : [...state.items, ...fetched],
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

  void refresh() {
    state = const ApplicationsState(isLoadingMore: true);
    _fetchPage(1);
  }
}

final applicationsProvider =
    AutoDisposeNotifierProvider<ApplicationsNotifier, ApplicationsState>(
        ApplicationsNotifier.new);
