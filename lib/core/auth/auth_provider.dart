import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../services/fcm_service.dart';
import '../services/google_auth_service.dart';
import 'token_storage.dart';

enum AuthRole { employee, employer, none }

class AuthState {
  final String? token;
  final AuthRole role;
  final bool loading;

  const AuthState({this.token, this.role = AuthRole.none, this.loading = false});

  bool get isAuthenticated => token != null && role != AuthRole.none;

  AuthState copyWith({String? token, AuthRole? role, bool? loading}) => AuthState(
        token:   token   ?? this.token,
        role:    role    ?? this.role,
        loading: loading ?? this.loading,
      );
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.read(tokenStorageProvider);
    final token   = await storage.getToken();
    final roleStr = await storage.getRole();

    if (token == null || roleStr == null) return const AuthState();

    final role = roleStr == 'employer' ? AuthRole.employer : AuthRole.employee;
    return AuthState(token: token, role: role);
  }

  Future<void> saveSession(String token, String role) async {
    final storage = ref.read(tokenStorageProvider);
    await storage.saveToken(token, role);
    await storage.saveFirstLoginAt(); // no-op if already set
    final r = role == 'employer' ? AuthRole.employer : AuthRole.employee;
    state = AsyncData(AuthState(token: token, role: r));
    // Register FCM token in the background — token is now in storage so the
    // Dio auth interceptor will attach the correct Bearer header automatically.
    FcmService.registerToken(ref.read(dioProvider));
  }

  Future<void> logout() async {
    await Future.wait([
      ref.read(tokenStorageProvider).clear(),
      GoogleAuthService.signOut(),
    ]);
    state = const AsyncData(AuthState());
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
