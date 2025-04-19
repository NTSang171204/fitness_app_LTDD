import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login/services/app_state.dart';
import 'package:provider/provider.dart';

Future<void> handleLogout(BuildContext context) async {
  final appState = Provider.of<AppState>(context, listen: false);
  await FirebaseAuth.instance.signOut();
  await appState.logout();

  if (context.mounted) {
    Navigator.pushReplacementNamed(context, '/login');
  }
}
