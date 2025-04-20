import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DecideScreen extends StatelessWidget {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        } else {
          final hasProfile = snapshot.data as bool;
          if (hasProfile) {
            Future.microtask(() => Navigator.pushReplacementNamed(context, '/dailySteps'));
          } else {
            Future.microtask(() => Navigator.pushReplacementNamed(context, '/userInfoForm'));
          }
          return SizedBox(); // tránh hiển thị gì đó thừa
        }
      },
    );
  }

  Future<bool> _checkUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.exists && doc.data()?['name'] != null; // Có thể chỉnh thêm điều kiện
  }
}
