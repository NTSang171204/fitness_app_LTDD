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

  double _movementThreshold = 1.5; // Ngưỡng độ rung để chấp nhận là bước chân
  double _avgAcceleration = 0.0;
  List<double> _accelHistory = [];

  // 🔄 MỚI: Đảm bảo init chỉ gọi 1 lần
  bool _isInitialized = false;

  String get todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  // ✅ ĐÃ THÊM: Hàm init async dùng cho UI có thể chờ
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    _stepsBox = Hive.box<int>('steps');
    _initialStepsBox = Hive.box<int>('initSteps');
    _distanceBox = Hive.box<double>('distance');

    final status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      // Load dữ liệu ban đầu từ Hive
      await Future.wait([
        _loadTodaySteps(),
        _loadInitialStepCount(),
        _loadTotalDistance(),
      ]);

      _startAccelerometer(); // Bắt đầu theo dõi rung
      _startStepTracking();  // Bắt đầu đếm bước
    } else {
      throw Exception("Permission denied. Cannot track steps.");
    }
  }

  // 🔄 MỚI: Load dữ liệu dùng await để UI đợi xong mới render
  Future<void> _loadTodaySteps() async {
    _stepsToday = _stepsBox.get(todayKey, defaultValue: 0)!;
    notifyListeners();
  }

  Future<void> _loadInitialStepCount() async {
    _initialStepCount = _initialStepsBox.get(todayKey, defaultValue: 0)!;
  }

  Future<void> _loadTotalDistance() async {
    _totalDistance = _distanceBox.get(todayKey, defaultValue: 0.0)!;
  }

  // Theo dõi gia tốc (dùng để lọc bước chân giả)
  void _startAccelerometer() {
    _accelerometerStream = accelerometerEvents.listen((event) {
      double acc = sqrt(event.x * event.x + event.y * event.y + event.z * event.z) - 9.8;
      acc = acc.abs();

      _accelHistory.add(acc);
      if (_accelHistory.length > 20) _accelHistory.removeAt(0);

      _avgAcceleration = _accelHistory.fold(0.00, (prev, x) => prev + x) / _accelHistory.length;
      notifyListeners();
    });
  }

  // Đăng ký stream pedometer
  void _startStepTracking() {
    _stepCountStream = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepError,
      cancelOnError: true,
    );
  }

  // Xử lý mỗi lần có dữ liệu bước chân
  void _onStepCount(StepCount event) {
    if (_initialStepCount == 0) {
      _initialStepCount = event.steps;
      _initialStepsBox.put(todayKey, _initialStepCount);
    }

    final todaySteps = event.steps - _initialStepCount;

    // 🔄 MỚI: Chỉ cập nhật khi có bước chân mới + đủ rung
    if (todaySteps != _stepsToday && todaySteps >= 0 && _avgAcceleration > _movementThreshold) {
      _stepsToday = todaySteps;
      _totalDistance = _stepsToday * _stepLength;

      _stepsBox.put(todayKey, _stepsToday);
      _distanceBox.put(todayKey, _totalDistance);

      _syncToFirestore(_stepsToday, _totalDistance / 100); // cm -> m
      notifyListeners();
    }
  }

  void _onStepError(error) {
    print('Pedometer error: $error');
  }

  // Gửi dữ liệu lên Firestore
  void _syncToFirestore(int steps, double distance) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('steps')
          .doc(todayKey)
          .set({'steps': steps, 'distance': distance, 'timestamp': DateTime.now()});
    }
  }

  @override
  void dispose() {
    _stepCountStream.cancel();
    _accelerometerStream.cancel();
    super.dispose();
  }

  int get stepsToday => _stepsToday;
  double get totalDistance => _totalDistance;
  double get averageAcceleration => _avgAcceleration;
}
