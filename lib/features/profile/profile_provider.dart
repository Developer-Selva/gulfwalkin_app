import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/employee.dart';

class ProfileNotifier extends AsyncNotifier<Employee> {
  @override
  Future<Employee> build() async {
    final res = await ref.read(dioProvider).get('/employee/profile');
    return Employee.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    final current = state.valueOrNull;
    try {
      await ref.read(dioProvider).put('/employee/profile', data: data);
      ref.invalidateSelf();
    } catch (e) {
      if (current != null) state = AsyncData(current);
      rethrow;
    }
  }

  Future<String> uploadPhoto(File file) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(file.path,
          filename: file.path.split('/').last),
    });
    final res = await ref.read(dioProvider).post('/employee/photo', data: form);
    final url = res.data['photo_url'] as String;
    // Optimistically update photo URL then refresh score
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(photoUrl: url));
    }
    ref.invalidateSelf();
    return url;
  }

  Future<String> uploadResume(File file) async {
    final form = FormData.fromMap({
      'resume': await MultipartFile.fromFile(file.path,
          filename: file.path.split('/').last),
    });
    final res = await ref.read(dioProvider).post('/employee/resume', data: form);
    final url = res.data['resume_url'] as String;
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(resumeUrl: url));
    }
    ref.invalidateSelf();
    return url;
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, Employee>(ProfileNotifier.new);
