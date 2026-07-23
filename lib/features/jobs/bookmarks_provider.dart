import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/job.dart';

class BookmarkItem {
  final int bookmarkId;
  final String savedAt;
  final Job job;

  const BookmarkItem({
    required this.bookmarkId,
    required this.savedAt,
    required this.job,
  });

  factory BookmarkItem.fromJson(Map<String, dynamic> j) => BookmarkItem(
        bookmarkId: j['bookmark_id'] as int,
        savedAt:    j['saved_at'] as String,
        job:        Job.fromJson(j['job'] as Map<String, dynamic>),
      );
}

class BookmarksState {
  final List<BookmarkItem> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? error;

  const BookmarksState({
    this.items = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.error,
  });

  BookmarksState copyWith({
    List<BookmarkItem>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? error,
  }) =>
      BookmarksState(
        items:         items         ?? this.items,
        currentPage:   currentPage   ?? this.currentPage,
        hasMore:       hasMore       ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error:         error,
      );
}

class BookmarksNotifier extends AutoDisposeNotifier<BookmarksState> {
  @override
  BookmarksState build() {
    Future.microtask(() => _fetchPage(1));
    return const BookmarksState(isLoadingMore: true);
  }

  Future<void> _fetchPage(int page) async {
    try {
      final res = await ref.read(dioProvider).get(
        '/employee/bookmarks',
        queryParameters: {'page': page},
      );

      final data     = res.data['data'] as List;
      final lastPage = res.data['last_page'] as int? ?? 1;
      final fetched  = data
          .map((e) => BookmarkItem.fromJson(e as Map<String, dynamic>))
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
    state = const BookmarksState(isLoadingMore: true);
    _fetchPage(1);
  }

  /// Optimistic removal — removes from list immediately, fires DELETE in background.
  void removeBookmark(int jobId) {
    state = state.copyWith(
      items: state.items.where((b) => b.job.id != jobId).toList(),
    );
    () async {
      try {
        await ref.read(dioProvider).delete('/employee/bookmarks/$jobId');
      } catch (_) {
        // If delete fails, re-fetch to restore accurate state
        refresh();
      }
    }();
  }
}

final bookmarksProvider =
    AutoDisposeNotifierProvider<BookmarksNotifier, BookmarksState>(
        BookmarksNotifier.new);
