import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class AppState extends ChangeNotifier {
  bool _hasSeenOnboard = false;
  bool _isLoggedIn = false;

  bool get hasSeenOnboard => _hasSeenOnboard;
  bool get isLoggedIn => _isLoggedIn;

  AppState() {
    loadState();
  }

  Future<void> loadState() async {
    var box = await Hive.openBox('appState');
    _hasSeenOnboard = box.get('hasSeenOnboard', defaultValue: false);
    _isLoggedIn = box.get('isLoggedIn', defaultValue: false);
    notifyListeners();
  }

  Future<void> markOnboardSeen(bool value) async {
    _hasSeenOnboard = value;
    var box = Hive.box('appState');
    await box.put('hasSeenOnboard', true);
    notifyListeners();
  }

  Future<void> setLoggedIn(bool value) async {
    _isLoggedIn = value;
    var box = Hive.box('appState');
    await box.put('isLoggedIn', value);
    notifyListeners();
  }
}
