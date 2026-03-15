import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

/// SharedPreferences wrapper for user settings. Used for theme, default timer, sound, last active team/session.
class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  bool get darkMode =>
      _prefs.getBool(AppConstants.keyDarkMode) ?? AppConstants.defaultDarkMode;
  Future<void> setDarkMode(bool value) async =>
      await _prefs.setBool(AppConstants.keyDarkMode, value);

  int get defaultTimerMinutes =>
      _prefs.getInt(AppConstants.keyDefaultTimerMinutes) ??
      AppConstants.defaultTimerMinutes;
  Future<void> setDefaultTimerMinutes(int value) async =>
      await _prefs.setInt(AppConstants.keyDefaultTimerMinutes, value);

  bool get soundEnabled =>
      _prefs.getBool(AppConstants.keySoundEnabled) ?? AppConstants.defaultSoundEnabled;
  Future<void> setSoundEnabled(bool value) async =>
      await _prefs.setBool(AppConstants.keySoundEnabled, value);

  String? get lastActiveTeamId =>
      _prefs.getString(AppConstants.keyLastActiveTeamId);
  Future<void> setLastActiveTeamId(String? value) async {
    if (value == null) {
      await _prefs.remove(AppConstants.keyLastActiveTeamId);
    } else {
      await _prefs.setString(AppConstants.keyLastActiveTeamId, value);
    }
  }

  String? get lastActiveSessionId =>
      _prefs.getString(AppConstants.keyLastActiveSessionId);
  Future<void> setLastActiveSessionId(String? value) async {
    if (value == null) {
      await _prefs.remove(AppConstants.keyLastActiveSessionId);
    } else {
      await _prefs.setString(AppConstants.keyLastActiveSessionId, value);
    }
  }
}
