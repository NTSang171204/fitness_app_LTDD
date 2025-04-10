import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:login/services/flutter_notify_services.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sensors_plus/sensors_plus.dart';

class StepTrackerService with ChangeNotifier {
  int _stepsToday = 0;
  int _initialStepCount = 0;
  int todaySteps = 0;
  late StreamSubscription<StepCount> _stepCountStream;
  late StreamSubscription<AccelerometerEvent> _accelerometerStream;
  bool _hasReachedGoatNotified =
      false; // 🆕 Biến để theo dõi thông báo đã gửi hay chưa

  final int dailyGoal = 6000;
  late Box<int> _stepsBox;
  late Box<int> _initialStepsBox;
  late Box<double> _distanceBox;
  late Box<double> _caloriesBox;

  double _stepLength = 60.0; // cm mỗi bước
  double _totalDistance = 0.0;
  double _caloriesBurned = 0.0;

  double _movementThreshold = 1.5;
  double _avgAcceleration = 0.0;
  List<double> _accelHistory = [];

  bool _isInitialized = false;

  Timer? _syncTimer;
  DateTime? _lastSynced;
  DateTime _lastAccelUpdate = DateTime.now();
  DateTime _lastNotified = DateTime.now();

  String get todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      _stepsBox = Hive.box<int>('steps');
      _initialStepsBox = Hive.box<int>('initSteps');
      _distanceBox = Hive.box<double>('distance');
      _caloriesBox = Hive.box<double>('calories'); // 🆕 Box cho calories

      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        throw Exception("Permission denied. Cannot track steps.");
      }

      // 🔄 Load dữ liệu cũ từ Hive
      final firestoreData = await _getFirestoreData();
      await Future.wait([
        _loadTodaySteps(firestoreData),
        _loadInitialStepCount(firestoreData),
        _loadTotalDistance(firestoreData),
        _loadCaloriesBurned(firestoreData), // 🆕
      ]);

      _startAccelerometer();
      _startStepTracking();
      _startFirestoreSyncTimer();
    } catch (e) {
      print("❌ Error initializing StepTrackerService: $e");
      rethrow;
    }
  }


  Future<void> _loadTodaySteps(Map<String, dynamic> firestoreData) async {
    _stepsToday = _stepsBox.get(todayKey, defaultValue: 0)!;
    if (_stepsToday <= 0) {
      _stepsToday = (firestoreData['steps'] as int?) ?? 0;
      _stepsBox.put(todayKey, _stepsToday);
    }
  }

  Future<void> _loadInitialStepCount(Map<String, dynamic> firestoreData) async {
    _initialStepCount = _initialStepsBox.get(todayKey, defaultValue: 0)!;
    if (_initialStepCount <= 0) {
      _initialStepCount = (firestoreData['initialSteps'] as int?) ?? 0;
      _initialStepsBox.put(todayKey, _initialStepCount);
    }
  }

  Future<void> _loadTotalDistance(Map<String, dynamic> firestoreData) async {
    _totalDistance = _distanceBox.get(todayKey, defaultValue: 0.0)!;
    if (_totalDistance <= 0) {
      _totalDistance = (firestoreData['distance'] as double?) ?? 0.0;
      _distanceBox.put(todayKey, _totalDistance);
    }
  }

  Future<void> _loadCaloriesBurned(Map<String, dynamic> firestoreData) async {
    _caloriesBurned = _caloriesBox.get(todayKey, defaultValue: 0.0)!;
    if (_caloriesBurned <= 0) {
      _caloriesBurned = (firestoreData['calories'] as double?) ?? 0.0;
      _caloriesBox.put(todayKey, _caloriesBurned);
    }
  }


  Future<Map<String, dynamic>> _getFirestoreData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('steps')
            .doc(todayKey)
            .get();

    if (doc.exists) {
      final data = doc.data();
      return (data ?? {});
    }

    return {};
  }

  // 📱 Bắt đầu lắng nghe cảm biến gia tốc
  void _startAccelerometer() {
    _accelerometerStream = accelerometerEvents.listen((event) {
      try {
        final now = DateTime.now();

        // ⏱️ Giới hạn update mỗi 500ms
        if (now.difference(_lastAccelUpdate).inMilliseconds < 500) return;
        _lastAccelUpdate = now;

        double acc =
            sqrt(event.x * event.x + event.y * event.y + event.z * event.z) -
            9.8;
        acc = acc.abs();

        _accelHistory.add(acc);
        if (_accelHistory.length > 20) _accelHistory.removeAt(0);

        double newAvg =
            _accelHistory.fold(0.0, (prev, x) => prev + x) /
            _accelHistory.length;

        if ((newAvg - _avgAcceleration).abs() > 0.05) {
          _avgAcceleration = newAvg;
          notifyListeners();
        }
      } catch (e) {
        print("❌ Accelerometer error: $e");
      }
    });
  }

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


    todaySteps = (event.steps - _initialStepCount);

    // 🧠 Kiểm tra bước thay đổi đủ lớn và không âm
    final hasNewStep = (todaySteps - _stepsToday).abs() >= 1;
    final isValidStep = todaySteps >= 0;

    // ⏱️ Kiểm tra thời gian giữa 2 lần notify để tránh spam UI
    final shouldNotify = DateTime.now().difference(_lastNotified).inMilliseconds > 1000;

    if (hasNewStep && isValidStep &&   _avgAcceleration > _movementThreshold) {
      _stepsToday = todaySteps;
      _totalDistance = _stepsToday * _stepLength;
      _caloriesBurned = _stepsToday * 0.04;

      // 📦 Lưu vào Hive
      _stepsBox.put(todayKey, _stepsToday);
      _distanceBox.put(todayKey, _totalDistance);
      _caloriesBox.put(todayKey, _caloriesBurned);

      print("✅ Received step event: ${event.steps}");
      print("➡️ Initial: $_initialStepCount | Today steps: $todaySteps");
      print("⚡ Avg Accel: $_avgAcceleration");

      // 🔔 Gửi thông báo bước chân hiện tại
      NotiService().showStepNotification(_stepsToday, dailyGoal);

      // 🎯 Gửi thông báo hoàn thành mục tiêu
      if (_stepsToday >= dailyGoal && !_hasReachedGoatNotified) {
        NotiService().showGoalReachedNotification(dailyGoal);
        _hasReachedGoatNotified = true;
      }

      // 📣 Cập nhật UI nếu đủ thời gian
      if (shouldNotify) {
        notifyListeners();
        _lastNotified = DateTime.now();
      }
    }
  } catch (e) {
    print("❌ Error in _onStepCount: $e");
  }
}


  void _onStepError(error) {
    print('❌ Pedometer error: $error');
  }

  void _startFirestoreSyncTimer() {
    print("🔄 Sync Timer bắt đầu. Đang sync lần đầu...");
    _syncToFirestore(force: true); // 🔁 Sync ngay khi khởi động

    _syncTimer = Timer.periodic(Duration(minutes: 10), (_) {
      print("🔁 Đã đến thời điểm sync định kỳ.");
      _syncToFirestore(force: false);
    });
  }

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
            'distance': _totalDistance / 100, // cm ➜ mét
            'calories': _caloriesBurned, // ✅ Gửi calories lên cloud
            'initialSteps': _initialStepCount,
            'timestamp': now,
          });

      _lastSynced = now;
      print(
        "✅ Đã sync Firestore lúc $now. Steps: $_stepsToday, Distance: ${_totalDistance / 100} m, Calories: $_caloriesBurned",
      );
    } catch (e) {
      print("❌ Lỗi khi sync Firestore: $e");
    }
  }

  @override
  void dispose() {
    _stepCountStream.cancel();
    _accelerometerStream.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  int get stepsToday => _stepsToday;
  double get totalDistance => _totalDistance;
  double get averageAcceleration => _avgAcceleration;
  double get caloriesBurned => _caloriesBurned; // 🔍 Public getter
}
