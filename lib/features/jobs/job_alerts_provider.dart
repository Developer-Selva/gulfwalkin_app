import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/job_alert.dart';

class JobAlertsState {
  final List<JobAlert> alerts;
  final bool notifyAllNewJobs;

  const JobAlertsState({
    required this.alerts,
    required this.notifyAllNewJobs,
  });

  JobAlertsState copyWith({List<JobAlert>? alerts, bool? notifyAllNewJobs}) =>
      JobAlertsState(
        alerts:           alerts           ?? this.alerts,
        notifyAllNewJobs: notifyAllNewJobs ?? this.notifyAllNewJobs,
      );
}

class JobAlertsNotifier extends AsyncNotifier<JobAlertsState> {
  @override
  Future<JobAlertsState> build() => _fetch();

  Future<JobAlertsState> _fetch() async {
    final res = await ref.read(dioProvider).get('/employee/job-alerts');
    return JobAlertsState(
      alerts: (res.data['data'] as List)
          .map((e) => JobAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
      notifyAllNewJobs: res.data['notify_all_new_jobs'] as bool? ?? true,
    );
  }

  Future<void> create({
    String? keywords,
    String? location,
    String? category,
  }) async {
    await ref.read(dioProvider).post('/employee/job-alerts', data: {
      if (keywords != null && keywords.isNotEmpty) 'keywords': keywords,
      if (location != null && location.isNotEmpty) 'location': location,
      if (category != null && category.isNotEmpty) 'category': category,
    });
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    // Optimistic removal
    state = AsyncData(current.copyWith(
      alerts: current.alerts.where((a) => a.id != id).toList(),
    ));
    try {
      await ref.read(dioProvider).delete('/employee/job-alerts/$id');
    } on DioException {
      ref.invalidateSelf();
      rethrow;
    }
  }

  Future<void> toggleNotifyAll(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    // Optimistic update
    state = AsyncData(current.copyWith(notifyAllNewJobs: enabled));
    try {
      await ref.read(dioProvider).put(
        '/employee/job-alerts/notify-all',
        data: {'enabled': enabled},
      );
    } on DioException {
      // Roll back on failure
      state = AsyncData(current);
      rethrow;
    }
  }
}

final jobAlertsProvider =
    AsyncNotifierProvider<JobAlertsNotifier, JobAlertsState>(
  JobAlertsNotifier.new,
);
