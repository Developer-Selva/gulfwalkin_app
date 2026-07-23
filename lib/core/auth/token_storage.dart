import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _kTokenKey              = 'gw_auth_token';
const _kRoleKey               = 'gw_auth_role';
const _kFirstLoginKey         = 'gw_first_login_at';
const _kFeedbackPromptShown   = 'gw_feedback_prompt_shown';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

class TokenStorage {
  // Stored in the app's private Hive box (inaccessible without root on Android).
  // flutter_secure_storage was removed because its v10.x migration code unconditionally
  // initialises EncryptedSharedPreferences (requires Tink 1.8+), which crashes on
  // certain Android 12/13 OEM builds where the Tink class is missing from the DEX.
  Box get _box => Hive.box('app_prefs');

  Future<void> saveToken(String token, String role) async {
    try {
      await Future.wait([
        _box.put(_kTokenKey, token),
        _box.put(_kRoleKey,  role),
      ]);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    try {
      return _box.get(_kTokenKey) as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRole() async {
    try {
      return _box.get(_kRoleKey) as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await Future.wait([
        _box.delete(_kTokenKey),
        _box.delete(_kRoleKey),
      ]);
    } catch (_) {}
  }

  /// Saves the current timestamp as the first-login date.
  /// No-op if a value is already stored (preserves the original first-login).
  Future<void> saveFirstLoginAt() async {
    try {
      if (_box.get(_kFirstLoginKey) == null) {
        await _box.put(_kFirstLoginKey, DateTime.now().toIso8601String());
      }
    } catch (_) {}
  }

  DateTime? getFirstLoginAt() {
    try {
      final raw = _box.get(_kFirstLoginKey) as String?;
      return raw != null ? DateTime.parse(raw) : null;
    } catch (_) {
      return null;
    }
  }

  bool isFeedbackPromptShown() {
    try {
      return _box.get(_kFeedbackPromptShown) as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> markFeedbackPromptShown() async {
    try {
      await _box.put(_kFeedbackPromptShown, true);
    } catch (_) {}
  }
}
