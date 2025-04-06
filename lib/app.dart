import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view/screens/home_screen.dart';
import 'view/screens/login_screen.dart';
import 'view_model/auth_view_model.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: Consumer<AuthViewModel>(
        builder: (context, authVM, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: authVM.user != null ? HomeScreen() : LoginScreen(),
          );
        },
      ),
    );
  }
}