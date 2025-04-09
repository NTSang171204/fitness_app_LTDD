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

  double _stepLength = 60.0; // cm mỗi bước
  double _totalDistance = 0.0;

  double _movementThreshold = 1.5;
  double _avgAcceleration = 0.0;
  List<double> _accelHistory = [];

  bool _isInitialized = false;

  Timer? _syncTimer; // ⏱️ Timer để sync Firestore mỗi 10 phút
  DateTime? _lastSynced; // Lưu thời điểm sync gần nhất

  String get todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  // ✅ Gọi từ UI để khởi tạo service
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

      // ⬇️ Load dữ liệu cũ từ Hive
      await Future.wait([
        _loadTodaySteps(),
        _loadInitialStepCount(),
        _loadTotalDistance(),
      ]);

      // 🚀 Bắt đầu theo dõi cảm biến
      _startAccelerometer();
      _startStepTracking();
      _startFirestoreSyncTimer(); // ⏱️ Sync Firestore định kỳ

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

  // 📱 Bắt đầu lắng nghe cảm biến gia tốc
  void _startAccelerometer() {
    _accelerometerStream = accelerometerEvents.listen((event) {
      try {
        double acc = sqrt(event.x * event.x + event.y * event.y + event.z * event.z) - 9.8;
        acc = acc.abs();

        _accelHistory.add(acc);
        if (_accelHistory.length > 20) _accelHistory.removeAt(0);

        double newAvg = _accelHistory.fold(0.0, (prev, x) => prev + x) / _accelHistory.length;

        if ((newAvg - _avgAcceleration).abs() > 0.05) {
          _avgAcceleration = newAvg;
          notifyListeners(); // chỉ notify nếu có thay đổi đáng kể
        }
      } catch (e) {
        print("❌ Accelerometer error: $e");
      }
    });
  }

  // 👣 Bắt đầu đếm bước
  void _startStepTracking() {
    _stepCountStream = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepError,
      cancelOnError: true,
    );
  }

  // ✅ Gọi khi có thay đổi bước
  void _onStepCount(StepCount event) {
    try {
      if (_initialStepCount == 0) {
        _initialStepCount = event.steps;
        _initialStepsBox.put(todayKey, _initialStepCount);
      }

      final todaySteps = event.steps - _initialStepCount;

      // ⚠️ Chỉ tính bước nếu gia tốc đủ lớn
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

  // ⏱️ Khởi động Timer sync Firestore mỗi 10 phút và sync ngay khi bắt đầu
  void _startFirestoreSyncTimer() {
    print("🔄 Sync Timer bắt đầu. Đang sync lần đầu...");
    _syncToFirestore(force: true); // ✅ Sync ngay lần đầu khởi động

    _syncTimer = Timer.periodic(Duration(minutes: 10), (_) {
      print("🔁 Đã đến thời điểm sync định kỳ.");
      _syncToFirestore(force: false);
    });
  }

  // ☁️ Hàm thực hiện sync dữ liệu lên Firestore
  Future<void> _syncToFirestore({bool force = false}) async {
    final now = DateTime.now();

    if (!force &&
        _lastSynced != null &&
        now.difference(_lastSynced!).inMinutes < 5) {
      print("🕒 Đã sync gần đây, bỏ qua lần này.");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ Không tìm thấy user! Không thể sync.");
      return;
    }

    try {
      print("⬆️ Syncing lên Firestore cho UID: ${user.uid}...");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('steps')
          .doc(todayKey)
          .set({
        'steps': _stepsToday,
        'distance': _totalDistance / 100, // convert sang mét
        'timestamp': now,
      });

      _lastSynced = now;
      print("✅ Đã sync Firestore lúc $now. Steps: $_stepsToday, Distance: ${_totalDistance / 100} m");
    } catch (e) {
      print("❌ Lỗi khi sync Firestore: $e");
    }
  }

  // 🗑️ Hủy các stream và timer khi không cần thiết
  @override
  void dispose() {
    _stepCountStream.cancel();
    _accelerometerStream.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  // 🧾 Getter public
  int get stepsToday => _stepsToday;
  double get totalDistance => _totalDistance;
  double get averageAcceleration => _avgAcceleration;
}
