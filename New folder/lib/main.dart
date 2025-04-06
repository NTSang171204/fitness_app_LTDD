import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/firebase_initializer.dart';
import 'view_model/auth_view_model.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitializer.initialize();
  runApp(MyApp());
}