import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:login/providers/theme_provider.dart';
import 'package:login/screens/history_screen.dart';
import 'package:login/screens/login_screen.dart';
import 'package:login/screens/onboard_screen.dart';
import 'package:login/screens/register_screen.dart';
import 'package:login/screens/step_tracker_screen.dart';
import 'package:login/screens/profile_screen.dart';
import 'package:login/screens/decide_screen.dart';
import 'package:login/screens/user_info_screen.dart';
import 'package:login/services/app_state.dart';
import 'package:login/services/flutter_notify_services.dart';
import 'package:login/services/step_tracker_screen_service.dart';
import 'package:login/theme/custom_theme.dart';
import 'package:provider/provider.dart';
import 'screens/policy_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox<int>('steps');
  await Hive.openBox<int>('initSteps');
  await Hive.openBox<double>('distance');
  await Hive.openBox<double>('calories');
  await Hive.openBox('appState');

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
      initialRoute = '/decide';
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StepTrackerService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Walking Step by Step',
            theme: CustomTheme.lightTheme,
            darkTheme: CustomTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: initialRoute,
            routes: {
              '/onboard': (context) => OnboardScreen(),
              '/login': (context) => LoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/history': (context) => HistoryScreen(),
              '/dailySteps': (context) => StepTrackerScreen(),
              '/profile': (context) => ProfileScreen(),
              '/userInfoForm': (context) => UserInfoFormScreen(),
              '/decide': (context) => DecideScreen(),
              '/policy': (context) => const PolicyScreen(),
            },
          );
        },
      ),
    );
  }
}
