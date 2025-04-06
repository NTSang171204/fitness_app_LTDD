import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/auth_view_model.dart';

class LoginScreen extends StatelessWidget {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Login / Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: emailCtrl, decoration: InputDecoration(labelText: "Email")),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                authVM.loginWithEmail(emailCtrl.text, passwordCtrl.text);
              },
              child: Text("Login with Email"),
            ),
            ElevatedButton(
              onPressed: () {
                authVM.registerWithEmail(emailCtrl.text, passwordCtrl.text);
              },
              child: Text("Register with Email"),
            ),
            ElevatedButton(
              onPressed: () {
                authVM.loginWithGoogle();
              },
              child: Text("Login with Google"),
            ),
            const SizedBox(height: 12),
            if (authVM.error != null) ...[
              SizedBox(height: 10),
              Text(
                authVM.error!,
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ]
          ],
        ),
      ),
    );
  }
}