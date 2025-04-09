// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_analytics/firebase_analytics.dart';
// import 'package:login/screens/dailysteps_page.dart';
// import 'package:login/screens/onboard_screen.dart';
// import 'package:login/screens/login_screen.dart';
// import 'package:login/screens/register_screen.dart';
// import 'package:login/screens/history_screen.dart';
// import 'package:hive_flutter/hive_flutter.dart'; // Import Hive Flutter
// import 'package:hive/hive.dart'; // Import Hive
// import 'package:jiffy/jiffy.dart'; // Import Jiffy
// import 'package:google_fonts/google_fonts.dart'; // Import Google fonts

// String globalRawTime = '00:00:00:00';
// int globalSecondTime = 0;
// // String hiveSleepKey = Jiffy(DateTime.now()).format('dd-MM-yyyy');

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(); // Khởi tạo Firebase
//   FirebaseAnalytics analytics = FirebaseAnalytics.instance;
//   await analytics.logEvent(name: 'app_opened'); // Gửi sự kiện test

//   await Hive.initFlutter(); // Khởi tạo Hive Flutter
//   await Hive.openBox<int>('steps'); // Mở hộp Hive cho số bước chân
//   await Hive.openBox<int>('sleepbox'); // Mở hộp Hive cho dữ liệu giấc ngủ
//   await Hive.openBox<String>('gotoSleepBox'); // Mở hộp Hive cho thời gian đi ngủ
//   await Hive.openBox<String>('wakeupBox'); // Mở hộp Hive cho thời gian thức dậy

//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
      // debugShowCheckedModeBanner: false,
      // title: 'Flutter Auth',
      // theme: ThemeData(primarySwatch: Colors.blue),
      // initialRoute: '/onboard',
      // routes: {
      //   '/onboard': (context) => OnboardScreen(),
      //   '/login': (context) => LoginScreen(),
      //   '/register': (context) => RegisterScreen(),
      //   '/history': (context) => HistoryScreen(),
      //   '/dailySteps': (context) => StepTrackerScreen(), // Thêm tuyến đường cho DailyStepsPage
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:login/screens/history_screen.dart';
import 'package:login/screens/login_screen.dart';
import 'package:login/screens/onboard_screen.dart';
import 'package:login/screens/register_screen.dart';
import 'package:login/screens/step_tracker_screen.dart';
import 'package:login/services/app_state.dart';
import 'package:login/services/step_tracker_screen_service.dart';
import 'package:provider/provider.dart'; // Import Provider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox<int>('steps');
  await Hive.openBox<int>('initSteps');
  await Hive.openBox<double>('distance');
  await Hive.openBox('appState'); // mở box lưu trạng thái người dùng

  final appState = AppState();
  await appState.loadState();

  runApp(ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MyApp(),
    ),);
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
            title: 'Flutter Auth',
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
