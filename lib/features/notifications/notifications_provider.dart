import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/error_handler.dart';
import 'notification_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class NotificationsState {
  final List<AppNotification> items;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? error;
  final int unreadCount;

  const NotificationsState({
    this.items = const [],
    this.currentPage = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? error,
    int? unreadCount,
  }) =>
      NotificationsState(
        items:         items         ?? this.items,
        currentPage:   currentPage   ?? this.currentPage,
        hasMore:       hasMore       ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error:         error,
        unreadCount:   unreadCount   ?? this.unreadCount,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotificationsNotifier
    extends AutoDisposeNotifier<NotificationsState> {
  static const _perPage = 20;

  @override
  NotificationsState build() {
    Future.microtask(() => _fetchPage(1));
    return const NotificationsState(isLoadingMore: true);
  }

  Future<void> _fetchPage(int page) async {
    if (state.isLoadingMore && page > 1) return;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final res = await ref.read(dioProvider).get(
        '/notifications',
        queryParameters: {'page': page, 'per_page': _perPage},
      );

      final rawList = res.data['data'] as List? ?? [];
      final items = rawList
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();

      // Backend may return unread_count in meta; fall back to counting locally.
      final meta         = res.data['meta'] as Map<String, dynamic>?;
      final backendCount = meta?['unread_count'] as int?;
      final unreadCount  = backendCount ??
          (page == 1
              ? items.where((n) => !n.isRead).length
              : state.unreadCount + items.where((n) => !n.isRead).length);

      state = state.copyWith(
        items:       page == 1 ? items : [...state.items, ...items],
        currentPage: page,
        hasMore:     items.length >= _perPage,
        isLoadingMore: false,
        unreadCount: page == 1 ? unreadCount : state.unreadCount,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoadingMore: false, error: handleDioError(e));
    }
  }

  void loadMore() {
    if (!state.hasMore || state.isLoadingMore) return;
    _fetchPage(state.currentPage + 1);
  }

  void refresh() => _fetchPage(1);

  Future<void> markAllRead() async {
    // Optimistic update — mark all as read in UI immediately.
    final now = DateTime.now();
    state = state.copyWith(
      items: state.items.map((n) => n.isRead ? n : n.copyWith(readAt: now)).toList(),
      unreadCount: 0,
    );
    // Clear the bell badge on the home screen AppBar immediately.
    ref.invalidate(unreadCountProvider);
    try {
      await ref.read(dioProvider).put('/notifications/read-all');
    } catch (_) {
      // API failed — re-fetch to restore accurate state.
      refresh();
    }
  }
}

final notificationsProvider =
    AutoDisposeNotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);

// ── Lightweight unread-count provider (used for the bell badge) ───────────────
// Fetches only the first page; resolves to 0 on error so it never blocks the UI.

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final res = await ref.read(dioProvider).get(
      '/notifications',
      queryParameters: {'page': 1, 'per_page': 20},
    );
    final meta = res.data['meta'] as Map<String, dynamic>?;
    if (meta?['unread_count'] != null) {
      return meta!['unread_count'] as int;
    }
    final rawList = res.data['data'] as List? ?? [];
    return rawList
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .where((n) => !n.isRead)
        .length;
  } catch (_) {
    return 0;
  }
});
