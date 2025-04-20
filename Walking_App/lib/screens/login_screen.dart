import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login/services/app_state.dart';
import 'package:provider/provider.dart';
import '../widgets/social_login_buttons.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  void _login() async {
  try {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final uid = userCredential.user?.uid;

    if (uid != null) {
      await Provider.of<AppState>(context, listen: false).setLoggedIn(true, uid);

      // 🔍 Kiểm tra user đã có thông tin chưa
      final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (docSnapshot.exists && docSnapshot.data()?['name'] != null) {
        Navigator.pushReplacementNamed(context, '/dailySteps');
      } else {
        Navigator.pushReplacementNamed(context, '/userInfoForm');
      }
    } else {
      throw Exception("User ID is null");
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Login failed: $e"),
    ));
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log in', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            SizedBox(height: 10),
            TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
            SizedBox(height: 20),
            SocialLoginButtons(),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _login, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: EdgeInsets.symmetric(vertical: 14)), child: Text('Log in', style: TextStyle(fontSize: 16, color: Colors.white))),
            SizedBox(height: 10),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/register'), child: Text('Don\'t have an account? Sign up')),
          ],
        ),
      ),
    );
  }
}
