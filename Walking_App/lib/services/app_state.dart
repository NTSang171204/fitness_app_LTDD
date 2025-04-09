import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class AppState extends ChangeNotifier {
  bool _hasSeenOnboard = false;
  bool _isLoggedIn = false;
  String? userId;

  bool get hasSeenOnboard => _hasSeenOnboard;
  bool get isLoggedIn => _isLoggedIn;

  AppState() {
    loadState();
  }

  Future<void> loadState() async {
    final box = await Hive.openBox('appState');
    _hasSeenOnboard = box.get('hasSeenOnboard', defaultValue: false);
    _isLoggedIn = box.get('isLoggedIn', defaultValue: false);
    userId = box.get('userId');
    notifyListeners();
  }

  Future<void> markOnboardSeen(bool value) async {
    _hasSeenOnboard = value;
    final box = Hive.box('appState');
    await box.put('hasSeenOnboard', true);
    notifyListeners();
  }

  Future<void> setLoggedIn(bool value, [String? uid]) async {
    _isLoggedIn = value;
    if (uid!=null) {
      userId = uid;
    }


    final box = Hive.box('appState');
    await box.put('isLoggedIn', value);
    if (uid != null) {
      await box.put('userId', uid);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    userId = null;
    final box = Hive.box('appState');
    await box.put('isLoggedIn', false);
    await box.delete('userId');
    notifyListeners();
  }
}