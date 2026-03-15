import 'package:project_1/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConstants', () {
    test('default dark mode is false', () {
      expect(AppConstants.defaultDarkMode, isFalse);
    });

    test('default timer minutes is 15', () {
      expect(AppConstants.defaultTimerMinutes, 15);
    });

    test('SharedPreferences keys are non-empty', () {
      expect(AppConstants.keyDarkMode, isNotEmpty);
      expect(AppConstants.keyDefaultTimerMinutes, isNotEmpty);
      expect(AppConstants.keySoundEnabled, isNotEmpty);
    });

    test('validation limits are positive', () {
      expect(AppConstants.maxMissionTitleLength, greaterThan(0));
      expect(AppConstants.maxStepTitleLength, greaterThan(0));
      expect(AppConstants.minTimerMinutes, lessThan(AppConstants.maxTimerMinutes));
    });
  });
}
