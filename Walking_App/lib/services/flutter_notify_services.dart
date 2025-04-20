import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotiService {
  NotiService._privateConstructor();
  static final NotiService _instance = NotiService._privateConstructor();
  factory NotiService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  static const String _notiKey = 'notifications'; // key dùng để lưu trạng thái

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

  /// Kiểm tra nếu người dùng đã bật thông báo thì mới gửi
  Future<void> showStepNotification(int steps, int goal) async {
    final isOn = await isNotificationEnabled();
    if (!isOn) return;

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
    final isOn = await isNotificationEnabled();
    if (!isOn) return;

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

  /// Bật hoặc tắt thông báo
  Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notiKey, enabled);
  }

  /// Trả về trạng thái hiện tại của thông báo
  Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notiKey) ?? true; // mặc định là bật
  }
}
