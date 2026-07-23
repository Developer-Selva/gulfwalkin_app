import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/job.dart';

const _kPrefsKey = 'recently_viewed_jobs';
const _kMaxItems = 10;

class RecentlyViewedNotifier extends StateNotifier<List<Job>> {
  RecentlyViewedNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPrefsKey);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList();
      state = list;
    } catch (_) {}
  }

  Future<void> clear() async {
    state = [];
    _persist();
  }

  Future<void> add(Job job) async {
    // Deduplicate by id, newest first, capped at _kMaxItems
    state = [job, ...state.where((j) => j.id != job.id)].take(_kMaxItems).toList();
    _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kPrefsKey,
        jsonEncode(state.map((j) => j.toJson()).toList()),
      );
    } catch (_) {}
  }
}

final recentlyViewedProvider =
    StateNotifierProvider<RecentlyViewedNotifier, List<Job>>(
  (_) => RecentlyViewedNotifier(),
);
