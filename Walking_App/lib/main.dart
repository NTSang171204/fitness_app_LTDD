import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:login/screens/history_screen.dart';
import 'package:login/screens/login_screen.dart';
import 'package:login/screens/onboard_screen.dart';
import 'package:login/screens/register_screen.dart';
import 'package:login/screens/step_tracker_screen.dart';
import 'package:login/services/app_state.dart';
import 'package:login/services/flutter_notify_services.dart';
import 'package:login/services/step_tracker_screen_service.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// Future<void> requestNotificationPermission() async {
//   // Nếu quyền chưa được cấp (hoặc bị từ chối tạm thời), xin quyền
//   if (await Permission.notification.isDenied ||
//       await Permission.notification.isPermanentlyDenied) {
//     await Permission.notification.request();
//   }
// }

// Future<void> checkNotificationPermissionStatus() async {
//   final status = await Permission.notification.status;
//   print("Notification permission status: $status");
// }

// Future<void> initNotification() async {
//   const AndroidInitializationSettings androidInit =
//       AndroidInitializationSettings('@mipmap/ic_launcher');
//   const InitializationSettings initSettings =
//       InitializationSettings(android: androidInit);
//   await flutterLocalNotificationsPlugin.initialize(initSettings);
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox<int>('steps');
  await Hive.openBox<int>('initSteps');
  await Hive.openBox<double>('distance');
  await Hive.openBox<double>('calories');
  await Hive.openBox('appState'); // mở box lưu trạng thái người dùng

  // Xin quyền thông báo và kiểm tra trạng thái
  // await requestNotificationPermission();
  // await initNotification();
  // await checkNotificationPermissionStatus();

  //Init Notifications
  await NotiService().initNotification();

  final appState = AppState();
  await appState.loadState();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    String initialRoute;
    if (!appState.hasSeenOnboard) {
      initialRoute = '/onboard';
    } else if (!appState.isLoggedIn) {
      initialRoute = '/login';
    } else {
      initialRoute = '/dailySteps';
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StepTrackerService()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Walking Step by step',
            theme: ThemeData(primarySwatch: Colors.blue),
            initialRoute: initialRoute,
            routes: {
              '/onboard': (context) => OnboardScreen(),
              '/login': (context) => LoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/history': (context) => HistoryScreen(),
              '/dailySteps': (context) => StepTrackerScreen(),
            },
          );
        },
      ),
    );
  }
}
