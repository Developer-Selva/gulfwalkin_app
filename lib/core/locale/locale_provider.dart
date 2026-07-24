import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const _kLocaleKey = 'gw_locale';

/// All supported locales in display order for the language picker.
const supportedLocales = [
  Locale('en'),
  Locale('ta'),
  Locale('hi'),
  Locale('te'),
  Locale('ml'),
];

/// Human-readable name for each locale, shown in its own script.
const localeDisplayNames = {
  'en': 'English',
  'ta': 'தமிழ்',
  'hi': 'हिन्दी',
  'te': 'తెలుగు',
  'ml': 'മലയാളം',
};

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_load());

  static Locale _load() {
    final saved = Hive.box('app_prefs').get(_kLocaleKey) as String?;
    return saved != null ? Locale(saved) : const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    await Hive.box('app_prefs').put(_kLocaleKey, locale.languageCode);
    state = locale;
  }
}
