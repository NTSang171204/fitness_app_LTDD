import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotiService {
  NotiService._privateConstructor();
  static final NotiService _instance = NotiService._privateConstructor();
  factory NotiService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initNotification() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
    _isInitialized = true;
  }

  Future<void> showStepNotification(int steps, int goal) async {
    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        'Step_channel',
        'Step Counter',
        channelDescription: 'Thông báo số bước hôm nay',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
        showWhen: false,
        onlyAlertOnce: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      '🏃 $steps bước',
      'Mục tiêu số bước: $goal.',
      details,
    );
  }

    Future<void> showGoalReachedNotification(int goal) async {
    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        'goal_channel_id',
        'Goal Reached',
        channelDescription: 'Thông báo khi đạt số bước hôm nay',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: false,
        showWhen: false,
        onlyAlertOnce: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      1,
    '🎉 Đã đạt mục tiêu!',
    'Bạn đã hoàn thành $goal bước hôm nay!',
      details,
    );
  }




}
