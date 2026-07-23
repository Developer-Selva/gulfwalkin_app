import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/top_company.dart';

final topCompaniesProvider = FutureProvider.autoDispose<List<TopCompany>>((ref) async {
  final res = await ref.read(dioProvider).get('/companies/top-hiring', queryParameters: {'limit': 10});
  return (res.data['data'] as List)
      .map((e) => TopCompany.fromJson(e as Map<String, dynamic>))
      .toList();
});
