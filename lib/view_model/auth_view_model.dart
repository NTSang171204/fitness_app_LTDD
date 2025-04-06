import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repository/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final _repo = AuthRepository();
  User? user;
  String? error;

  AuthViewModel() {
    user = FirebaseAuth.instance.currentUser;
    debugPrint("Initial user: $user");
  }

  Future<void> loginWithEmail(String email, String password) async {
    try {
      error = null;
      user = await _repo.signInWithEmail(email, password);
      debugPrint("✅ Email Login Success: ${user?.email}");
      notifyListeners();
    } catch (e) {
      error = e.toString();
      debugPrint("❌ Email Login Failed: $error");
      notifyListeners();
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    try {
      error = null;
      user = await _repo.registerWithEmail(email, password);
      debugPrint("✅ Register Success: ${user?.email}");
      notifyListeners();
    } catch (e) {
      error = e.toString();
      debugPrint("❌ Register Failed: $error");
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      error = null;
      user = await _repo.signInWithGoogle();
      debugPrint("✅ Google Sign In Success: ${user?.email}");
      notifyListeners();
    } catch (e) {
      error = e.toString();
      debugPrint("❌ Google Sign In Failed: $error");
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repo.signOut();
    debugPrint("👋 User logged out");
    user = null;
    notifyListeners();
  }
}
