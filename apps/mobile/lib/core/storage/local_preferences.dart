import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small, non-sensitive device preferences. Auth sessions are stored by
/// supabase_flutter itself; nothing private is kept here.
abstract interface class LocalPreferences {
  bool get onboardingSeen;
  Future<void> setOnboardingSeen();
}

class SharedLocalPreferences implements LocalPreferences {
  SharedLocalPreferences(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static const _onboardingSeen = 'onboarding_seen_v1';
  static const keys = {_onboardingSeen};

  @override
  bool get onboardingSeen => _prefs.getBool(_onboardingSeen) ?? false;

  @override
  Future<void> setOnboardingSeen() => _prefs.setBool(_onboardingSeen, true);
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
