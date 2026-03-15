import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/providers.dart';

/// Global theme mode state. Persisted via PreferencesService.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<bool> {
  ThemeModeNotifier(this._ref) : super(AppConstants.defaultDarkMode) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final prefs = await _ref.read(preferencesServiceProvider.future);
    state = prefs.darkMode;
  }

  /// Load theme from persisted preferences (call once on app start).
  void loadFromPrefs(bool value) {
    state = value;
  }

  Future<void> setDarkMode(bool value) async {
    state = value;
    final prefs = await _ref.read(preferencesServiceProvider.future);
    await prefs.setDarkMode(value);
  }

  Future<void> toggle() async {
    await setDarkMode(!state);
  }
}
