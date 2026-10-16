import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small, non-sensitive device preferences. Auth sessions are stored by
/// supabase_flutter itself; nothing private is kept here.
abstract interface class LocalPreferences {
  bool get onboardingSeen;
  Future<void> setOnboardingSeen();

  /// 'system', 'light' or 'dark'.
  String get themeMode;
  Future<void> setThemeMode(String mode);

  /// When the guest last opened their enquiries (drives the "new reply" badge).
  DateTime? get enquiriesSeenAt;
  Future<void> setEnquiriesSeenAt(DateTime time);
}

class SharedLocalPreferences implements LocalPreferences {
  SharedLocalPreferences(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static const _onboardingSeen = 'onboarding_seen_v1';
  static const _themeMode = 'theme_mode';
  static const _enquiriesSeenAt = 'enquiries_seen_at';
  static const keys = {_onboardingSeen, _themeMode, _enquiriesSeenAt};

  @override
  bool get onboardingSeen => _prefs.getBool(_onboardingSeen) ?? false;

  @override
  Future<void> setOnboardingSeen() => _prefs.setBool(_onboardingSeen, true);

  @override
  String get themeMode => _prefs.getString(_themeMode) ?? 'system';

  @override
  Future<void> setThemeMode(String mode) => _prefs.setString(_themeMode, mode);

  @override
  DateTime? get enquiriesSeenAt {
    final raw = _prefs.getString(_enquiriesSeenAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  Future<void> setEnquiriesSeenAt(DateTime time) => _prefs.setString(_enquiriesSeenAt, time.toUtc().toIso8601String());
}

final localPreferencesProvider = Provider<LocalPreferences>(
  (ref) => throw StateError('localPreferencesProvider must be overridden at startup'),
);

class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.watch(localPreferencesProvider).onboardingSeen;

  Future<void> complete() async {
    await ref.read(localPreferencesProvider).setOnboardingSeen();
    state = true;
  }
}

final onboardingCompleteProvider = NotifierProvider<OnboardingController, bool>(OnboardingController.new);

/// Light, dark, or follow the phone. Saved on the device.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.values.firstWhere(
        (m) => m.name == ref.watch(localPreferencesProvider).themeMode,
        orElse: () => ThemeMode.system,
      );

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(localPreferencesProvider).setThemeMode(mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
