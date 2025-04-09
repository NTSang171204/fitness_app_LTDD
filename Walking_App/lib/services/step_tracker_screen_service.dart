import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sensors_plus/sensors_plus.dart';

class StepTrackerService with ChangeNotifier {
  int _stepsToday = 0;
  int _initialStepCount = 0;
  late StreamSubscription<StepCount> _stepCountStream;
  late StreamSubscription<AccelerometerEvent> _accelerometerStream;

  final int dailyGoal = 6000;
  late Box<int> _stepsBox;
  late Box<int> _initialStepsBox;
  late Box<double> _distanceBox;

  double _stepLength = 60.0; // cm
  double _totalDistance = 0.0;

  double _movementThreshold = 1.5;
  double _avgAcceleration = 0.0;
  List<double> _accelHistory = [];

  bool _isInitialized = false;

  // 🔄 MỚI: Timer để sync Firestore định kỳ mỗi giờ
  Timer? _syncTimer;
  DateTime? _lastSynced;

  String get todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  // ✅ Gọi từ UI để chờ init xong
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      _stepsBox = Hive.box<int>('steps');
      _initialStepsBox = Hive.box<int>('initSteps');
      _distanceBox = Hive.box<double>('distance');

      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        throw Exception("Permission denied. Cannot track steps.");
      }

      await Future.wait([
        _loadTodaySteps(),
        _loadInitialStepCount(),
        _loadTotalDistance(),
      ]);

      _startAccelerometer();
      _startStepTracking();
      _startFirestoreSyncTimer(); // ⏱️ bắt đầu Timer sync định kỳ

    } catch (e) {
      print("❌ Error initializing StepTrackerService: $e");
      rethrow;
    }
  }

  Future<void> _loadTodaySteps() async {
    _stepsToday = _stepsBox.get(todayKey, defaultValue: 0)!;
  }

  Future<void> _loadInitialStepCount() async {
    _initialStepCount = _initialStepsBox.get(todayKey, defaultValue: 0)!;
  }

  Future<void> _loadTotalDistance() async {
    _totalDistance = _distanceBox.get(todayKey, defaultValue: 0.0)!;
  }

  // 📱 Theo dõi cảm biến rung
  void _startAccelerometer() {
    _accelerometerStream = accelerometerEvents.listen((event) {
      try {
        double acc = sqrt(event.x * event.x + event.y * event.y + event.z * event.z) - 9.8;
        acc = acc.abs();

        _accelHistory.add(acc);
        if (_accelHistory.length > 20) _accelHistory.removeAt(0);

        double newAvg = _accelHistory.fold(0.0, (prev, x) => prev + x) / _accelHistory.length;

        // 🔄 Chỉ update nếu thay đổi đáng kể để tránh notifyListeners liên tục
        if ((newAvg - _avgAcceleration).abs() > 0.05) {
          _avgAcceleration = newAvg;
          notifyListeners();
        }
      } catch (e) {
        print("❌ Accelerometer error: $e");
      }
    });
  }

  // 👣 Đếm bước bằng pedometer
  void _startStepTracking() {
    _stepCountStream = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepError,
      cancelOnError: true,
    );
  }

  void _onStepCount(StepCount event) {
    try {
      if (_initialStepCount == 0) {
        _initialStepCount = event.steps;
        _initialStepsBox.put(todayKey, _initialStepCount);
      }

      final todaySteps = event.steps - _initialStepCount;

      if (todaySteps != _stepsToday &&
          todaySteps >= 0 &&
          _avgAcceleration > _movementThreshold) {
        _stepsToday = todaySteps;
        _totalDistance = _stepsToday * _stepLength;

        // 📦 Lưu vào Hive
        _stepsBox.put(todayKey, _stepsToday);
        _distanceBox.put(todayKey, _totalDistance);

        notifyListeners();
      }
    } catch (e) {
      print("❌ Error in _onStepCount: $e");
    }
  }

  void _onStepError(error) {
    print('❌ Pedometer error: $error');
  }

  // ☁️ Sync dữ liệu mỗi giờ
  void _startFirestoreSyncTimer() {
    _syncTimer = Timer.periodic(Duration(minutes: 10), (_) {
      _syncToFirestore(force: false);
    });
  }

  // ⏱️ Gọi khi cần sync thủ công (cuối ngày hoặc gọi tay)
  void _syncToFirestore({bool force = false}) {
    final now = DateTime.now();

    if (!force &&
        _lastSynced != null &&
        now.difference(_lastSynced!).inMinutes < 5) {
      // ❌ Đã sync gần đây rồi
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('steps')
          .doc(todayKey)
          .set({
        'steps': _stepsToday,
        'distance': _totalDistance / 100, // cm -> m
        'timestamp': now,
      });

      _lastSynced = now;
      print("✅ Synced to Firestore at $now");
    } catch (e) {
      print("❌ Firestore sync error: $e");
    }
  }

  @override
  void dispose() {
    _stepCountStream.cancel();
    _accelerometerStream.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  // 🧾 Getter
  int get stepsToday => _stepsToday;
  double get totalDistance => _totalDistance;
  double get averageAcceleration => _avgAcceleration;
}
