/// App-wide constants: keys, defaults, limits.
class AppConstants {
  AppConstants._();

  // SharedPreferences keys
  static const String keyDarkMode = 'dark_mode';
  static const String keyDefaultTimerMinutes = 'default_timer_minutes';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyLastActiveTeamId = 'last_active_team_id';
  static const String keyLastActiveSessionId = 'last_active_session_id';

  // Defaults
  static const int defaultTimerMinutes = 15;
  static const bool defaultSoundEnabled = true;
  static const bool defaultDarkMode = false;

  // Validation
  static const int maxMissionTitleLength = 100;
  static const int maxStepTitleLength = 150;
  static const int maxTeamNameLength = 50;
  static const int minTimerMinutes = 1;
  static const int maxTimerMinutes = 120;
}
