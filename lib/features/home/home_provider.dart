import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/advertisement.dart';
import '../../core/models/category.dart';
import '../../core/models/job.dart';

class HomeData {
  final List<Category> categories;
  final List<Job> recentJobs;
  final List<Advertisement> ads;

  const HomeData({
    required this.categories,
    required this.recentJobs,
    required this.ads,
  });
}

final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final dio = ref.read(dioProvider);

  final results = await Future.wait([
    dio.get('/categories'),
    dio.get('/jobs', queryParameters: {'page': 1}),
    dio.get('/advertisements/active'),
  ]);

  final categories = (results[0].data['data'] as List)
      .map((e) => Category.fromJson(e as Map<String, dynamic>))
      .toList();

  final recentJobs = (results[1].data['data'] as List)
      .take(6)
      .map((e) => Job.fromJson(e as Map<String, dynamic>))
      .toList();

  final ads = (results[2].data['data'] as List)
      .map((e) => Advertisement.fromJson(e as Map<String, dynamic>))
      .toList();

  return HomeData(categories: categories, recentJobs: recentJobs, ads: ads);
});
