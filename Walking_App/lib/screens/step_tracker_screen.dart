import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sensors_plus/sensors_plus.dart';
class StepTrackerScreen extends StatefulWidget {
  @override
  _StepTrackerScreenState createState() => _StepTrackerScreenState();
}

class _StepTrackerScreenState extends State<StepTrackerScreen> {
  int _stepsToday = 0;
  int _initialStepCount = 0;
  late StreamSubscription<StepCount> _stepCountStream;
  late StreamSubscription<AccelerometerEvent> _accelerometerStream;

  final int _dailyGoal = 6000;
  late Box<int> _stepsBox;
  late Box<int> _initialStepsBox;

  double _stepLength = 60.0; // Khoảng cách bước trung bình (cm) = 0.6m theo google
  double _distance = 0.0; // Khoảng cách đã đi được (cm)
  double _threshold = 10.0; // Ngưỡng gia tốc để phát hiện bước đi: 10m2/s.
  double _totalDistance = 0.0; // Tổng quảng đường đã đi được (cm).
  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  @override
  void initState() {
    super.initState();
    _initPermissionsAndStart();
  }

  Future<void> _initPermissionsAndStart() async {
    _stepsBox = Hive.box<int>('steps');
    _initialStepsBox = Hive.box<int>('initSteps');

    final status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _loadTodaySteps();
      _loadInitialStepCount();
      _startStepTracking();
      _startAccelerometer(); // Bắt đầu theo dõi gia tốc kế
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permission denied. Cannot track steps.")),
      );
    }
  }

  void _loadTodaySteps() {
    _stepsToday = _stepsBox.get(_todayKey, defaultValue: 0)!;
    setState(() {});
  }

  void _loadInitialStepCount() {
    _initialStepCount = _initialStepsBox.get(_todayKey, defaultValue: 0)!;
  }

  void _startStepTracking() {
    _stepCountStream = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepError,
      cancelOnError: true,
    );
  }

void _startAccelerometer() {
  _accelerometerStream = accelerometerEvents.listen((AccelerometerEvent event) { // Không thay đổi dòng này, vì accelerometerEvents nằm trong sensors_plus
    double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    
    if (acceleration > _threshold) {
      _distance += _stepLength;
      _totalDistance += _stepLength;
      if (_distance >= _stepLength) {
        _stepsToday++;
        _distance = 0.0;
        _stepsBox.put(_todayKey, _stepsToday);
        _syncToFirestore(_stepsToday);
      }
    }
  });
}

  void _onStepCount(StepCount event) {
    if (_initialStepCount == 0) {
      _initialStepCount = event.steps;
      _initialStepsBox.put(_todayKey, _initialStepCount);
    }

    final todaySteps = event.steps - _initialStepCount;

    if (todaySteps != _stepsToday && todaySteps >= 0) {
      setState(() {
        _stepsToday = todaySteps;
      });
      _stepsBox.put(_todayKey, _stepsToday);
      _syncToFirestore(_stepsToday);
    }
  }

  void _onStepError(error) {
    print('Pedometer error: $error');
  }

  void _syncToFirestore(int steps) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('steps')
          .doc(dateKey)
          .set({'steps': steps, 'timestamp': DateTime.now()});
    }
  }

  @override
  void dispose() {
    _stepCountStream.cancel();
    _accelerometerStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double percent = (_stepsToday / _dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text("Daily Steps")),
      body: Center(
        child: CircularPercentIndicator(
          radius: 150.0,
          lineWidth: 12.0,
          animation: true,
          percent: percent,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_stepsToday',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              Text("steps", style: TextStyle(fontSize: 18)),
            ],
          ),
          progressColor: Colors.green,
          backgroundColor: Colors.grey[300]!,
          circularStrokeCap: CircularStrokeCap.round,
        ),
      ),
    );
  }
}