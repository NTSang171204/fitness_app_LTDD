import '../services/firebase_auth_service.dart';

class AuthRepository {
  final _authService = FirebaseAuthService();

  Future signInWithEmail(String email, String password) =>
      _authService.signInWithEmail(email, password);

  Future registerWithEmail(String email, String password) =>
      _authService.registerWithEmail(email, password);

  Future signInWithGoogle() => _authService.signInWithGoogle();

  Future signOut() => _authService.signOut();
}