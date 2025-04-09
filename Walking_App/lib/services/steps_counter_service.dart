// import 'dart:async';
// import 'dart:math';
// import 'package:hive/hive.dart';
// import 'package:pedometer/pedometer.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class StepCounterService {
//   static final StepCounterService _instance = StepCounterService._internal();
//   factory StepCounterService() => _instance;
//   StepCounterService._internal();

//   int _initialStepCount = 0;
//   int stepsToday = 0;
//   double stepLength = 60.0;
//   double totalDistance = 0.0;
//   double avgAcceleration = 0.0;
//   double movementThreshold = 1.5;

//   late Box<int> _stepsBox;
//   late Box<int> _initialStepsBox;
//   late Box<double> _distanceBox;

//   StreamSubscription<StepCount>? _stepSub;
//   StreamSubscription<AccelerometerEvent>? _accelSub;
//   final List<double> _accelHistory = [];

//   String get todayKey {
//     final now = DateTime.now();
//     return '${now.year}-${now.month}-${now.day}';
//   }

//   Future<void> init() async {
//     _stepsBox = Hive.box<int>('steps');
//     _initialStepsBox = Hive.box<int>('initSteps');
//     _distanceBox = Hive.box<double>('distance');

//     _initialStepCount = _initialStepsBox.get(todayKey, defaultValue: 0)!;
//     stepsToday = _stepsBox.get(todayKey, defaultValue: 0)!;
//     totalDistance = _distanceBox.get(todayKey, defaultValue: 0.0)!;
//   }

//   void start() {
//     _stepSub = Pedometer.stepCountStream.listen(_onStep);
//     _accelSub = accelerometerEvents.listen(_onAccel);
//   }

//   void stop() {
//     _stepSub?.cancel();
//     _accelSub?.cancel();
//   }

//   void _onAccel(AccelerometerEvent e) {
//     double acc = sqrt(e.x * e.x + e.y * e.y + e.z * e.z) - 9.8;
//     acc = acc.abs();

//     _accelHistory.add(acc);
//     if (_accelHistory.length > 20) {
//       _accelHistory.removeAt(0);
//     }

//     avgAcceleration = _accelHistory.reduce((a, b) => a + b) / _accelHistory.length;
//   }

//   void _onStep(StepCount e) {
//     if (_initialStepCount == 0) {
//       _initialStepCount = e.steps;
//       _initialStepsBox.put(todayKey, _initialStepCount);
//     }

//     final currentSteps = e.steps - _initialStepCount;

//     if (currentSteps != stepsToday && currentSteps >= 0 && avgAcceleration > movementThreshold) {
//       stepsToday = currentSteps;
//       totalDistance = stepsToday * stepLength;

//       _stepsBox.put(todayKey, stepsToday);
//       _distanceBox.put(todayKey, totalDistance);
//       _syncToFirestore(stepsToday, totalDistance / 100);
//     }
//   }

//   void _syncToFirestore(int steps, double distance) {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final today = DateTime.now();
//       final key = '${today.year}-${today.month}-${today.day}';
//       FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('steps')
//           .doc(key)
//           .set({'steps': steps, 'distance': distance, 'timestamp': DateTime.now()});
//     }
//   }

//   Future<void> syncNow() async {
//     await init();
//     _syncToFirestore(stepsToday, totalDistance / 100);
//   }

//   double getDistanceInMeters() => totalDistance / 100;
// }
