import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifyService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  static Future showDone() async {
    const android = AndroidNotificationDetails(
      'pomodoro',
      'Pomodoro',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _plugin.show(
      0,
      "Pomodoro Finished!",
      "Time for a break ☕",
      const NotificationDetails(android: android),
    );
  }
}
