import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _kTokenKey = 'gw_auth_token';
const _kRoleKey  = 'gw_auth_role';

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
}
