import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/employee.dart';
import 'auth_provider.dart';

/// Fetches and caches the current authenticated employee's full profile.
/// Returns null for employers or unauthenticated users.
final currentUserProvider = FutureProvider<Employee?>((ref) async {
  final auth = ref.watch(authProvider).valueOrNull;
  if (auth == null || !auth.isAuthenticated || auth.role != AuthRole.employee) {
    return null;
  }

  final res = await ref.read(dioProvider).get('/auth/me');
  if (res.data['role'] == 'employee') {
    return Employee.fromJson(res.data['user'] as Map<String, dynamic>);
  }
  return null;
});
