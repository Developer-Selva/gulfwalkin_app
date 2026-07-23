import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/job.dart';

final recommendedJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  final res = await ref.read(dioProvider).get('/employee/recommendations');
  return (res.data['data'] as List)
      .map((e) => Job.fromJson(e as Map<String, dynamic>))
      .toList();
});
