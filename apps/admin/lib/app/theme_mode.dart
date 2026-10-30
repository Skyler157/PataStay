import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Browser storage for the theme choice. Overridden at startup; when absent
/// (tests, or storage blocked) the choice simply isn't remembered.
final adminPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

const _themeModeKey = 'admin_theme_mode';

/// Light, dark, or follow the computer. Saved in this browser.
class AdminThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = ref.watch(adminPreferencesProvider)?.getString(_themeModeKey);
    return ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(adminPreferencesProvider)?.setString(_themeModeKey, mode.name);
  }
}

final adminThemeModeProvider =
    NotifierProvider<AdminThemeModeController, ThemeMode>(AdminThemeModeController.new);

/// App bar button that switches between system, light and dark.
class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  static const _options = [
    (ThemeMode.system, 'Same as computer', Icons.brightness_auto_outlined),
    (ThemeMode.light, 'Light', Icons.light_mode_outlined),
    (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(adminThemeModeProvider);
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Appearance',
      initialValue: current,
      icon: Icon(_options.firstWhere((o) => o.$1 == current).$3),
      onSelected: (mode) => ref.read(adminThemeModeProvider.notifier).set(mode),
      itemBuilder: (_) => [
        for (final (mode, label, icon) in _options)
          PopupMenuItem(
            value: mode,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 12),
              Icon(Icons.check_rounded, size: 18, color: mode == current ? null : Colors.transparent),
            ]),
          ),
      ],
    );
  }
}
