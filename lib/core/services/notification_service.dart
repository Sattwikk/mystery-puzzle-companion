import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications for graduate requirement: mission completion, reminders.
class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationDetails _androidDetails = AndroidNotificationDetails(
    'mission_channel',
    'Mission Notifications',
    channelDescription: 'Mission completion and step reminders',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onSelect,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'mission_channel',
            'Mission Notifications',
            description: 'Mission completion and step reminders',
            importance: Importance.defaultImportance,
          ),
        );
    _initialized = true;
  }

  void _onSelect(NotificationResponse response) {
    // Could navigate to session or home when user taps notification
  }

  /// Show notification when mission is completed (graduate: local notifications).
  Future<void> showMissionCompleted(String missionTitle) async {
    await init();
    await _plugin.show(
      0,
      'Mission completed!',
      'You finished: $missionTitle',
      const NotificationDetails(android: _androidDetails),
    );
  }
}
