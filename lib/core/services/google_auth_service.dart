import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Web Client ID from Google Cloud Console → APIs & Services → Credentials
// → OAuth 2.0 Client IDs → "Web client (auto created by Google Service)".
// Required on Android to obtain an idToken for server-side verification.
const _webClientId =
    '351112954399-hdgeim64b52o47eh8182hkqcimr8pfk3.apps.googleusercontent.com';

final _googleSignIn = GoogleSignIn(
  serverClientId: _webClientId,
  scopes: ['email', 'profile'],
);

/// Thrown when Google Sign-In fails due to a configuration problem
/// (e.g. SHA-1 fingerprint not registered, wrong package name).
class GoogleSignInConfigException implements Exception {
  final String message;
  const GoogleSignInConfigException(this.message);

  @override
  String toString() => message;
}

class GoogleAuthService {
  /// Triggers the Google account picker and returns the id_token.
  ///
  /// Returns `null` if the user cancelled.
  /// Throws [GoogleSignInConfigException] if the sign-in fails due to a
  /// configuration issue (SHA-1 not registered, DEVELOPER_ERROR etc.).
  static Future<String?> getIdToken() async {
    // Force account picker every time (no silent sign-in).
    await _googleSignIn.signOut();

    GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
    } on PlatformException catch (e) {
      // Codes the user can't act on → configuration error for the developer.
      // Error 10 = DEVELOPER_ERROR (SHA-1 not registered or wrong package).
      if (e.code == 'sign_in_canceled' || e.code == 'sign_in_cancelled') {
        return null;
      }
      throw GoogleSignInConfigException(
        'Google Sign-In failed (${e.code}). '
        'Make sure the SHA-1 fingerprint of your debug keystore is '
        'registered in Google Cloud Console for package com.gulfwalkin.app.',
      );
    }

    // Null account = user dismissed the picker.
    if (account == null) return null;

    final auth = await account.authentication;
    if (auth.idToken == null) {
      // Account was obtained but no server-side token — usually means the
      // Android OAuth client is missing from Google Cloud Console.
      throw const GoogleSignInConfigException(
        'Google authentication succeeded but idToken is null. '
        'Ensure an Android OAuth client with the correct SHA-1 is configured '
        'in Google Cloud Console for com.gulfwalkin.app.',
      );
    }

    return auth.idToken;
  }

  /// Clears the Google sign-in session on logout.
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
