// import 'dart:async';
// import 'dart:math';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'package:pedometer/pedometer.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:hive/hive.dart';

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       isForegroundMode: true,
//       autoStart: true,
//       autoStartOnBoot: true,
//     ),
//     iosConfiguration: IosConfiguration(
//       onForeground: onStart,
//       onBackground: (_) => true,
//     ),
//   );

//   service.startService();
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) {
//   if (service is AndroidServiceInstance) {
//     service.setAsForegroundService();
//   }

//   final stepsBox = Hive.box<int>('steps');
//   final initStepsBox = Hive.box<int>('initSteps');
//   final distanceBox = Hive.box<double>('distance');

//   int initialStep = 0;
//   int stepsToday = 0;
//   double totalDistance = 0.0;
//   double stepLength = 60.0;

//   double movementThreshold = 1.5;
//   List<double> accelHistory = [];

//   StreamSubscription<StepCount>? stepStream;
//   StreamSubscription<AccelerometerEvent>? accelStream;

//   String todayKey() {
//     final now = DateTime.now();
//     return '${now.year}-${now.month}-${now.day}';
//   }

//   void syncToFirestore(int steps, double distance) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final today = DateTime.now();
//       final dateKey = '${today.year}-${today.month}-${today.day}';
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('steps')
//           .doc(dateKey)
//           .set({
//         'steps': steps,
//         'distance': distance,
//         'timestamp': DateTime.now(),
//       });
//     }
//   }

//   void startPedometer() {
//     stepStream = Pedometer.stepCountStream.listen((StepCount event) {
//       if (initialStep == 0) {
//         initialStep = event.steps;
//         initStepsBox.put(todayKey(), initialStep);
//       }

//       int currentSteps = event.steps - initialStep;

//       // Tính trung bình gia tốc
//       double avgAccel = accelHistory.isEmpty
//           ? 0
//           : accelHistory.reduce((a, b) => a + b) / accelHistory.length;

//       if (currentSteps != stepsToday &&
//           currentSteps >= 0 &&
//           avgAccel > movementThreshold) {
//         stepsToday = currentSteps;
//         totalDistance = stepsToday * stepLength;

//         stepsBox.put(todayKey(), stepsToday);
//         distanceBox.put(todayKey(), totalDistance);
//         syncToFirestore(stepsToday, totalDistance / 100);
//       }
//     });
//   }

//   void startAccelerometer() {
//     accelStream = accelerometerEvents.listen((AccelerometerEvent event) {
//       double acc = sqrt(event.x * event.x + event.y * event.y + event.z * event.z) - 9.8;
//       acc = acc.abs();

//       accelHistory.add(acc);
//       if (accelHistory.length > 20) {
//         accelHistory.removeAt(0);
//       }
//     });
//   }

//   Future<void> initLogic() async {
//     initialStep = initStepsBox.get(todayKey(), defaultValue: 0)!;
//     stepsToday = stepsBox.get(todayKey(), defaultValue: 0)!;
//     totalDistance = distanceBox.get(todayKey(), defaultValue: 0.0)!;

//     startPedometer();
//     startAccelerometer();
//   }

//   initLogic();

//   service.on('stopService').listen((event) {
//     stepStream?.cancel();
//     accelStream?.cancel();
//     service.stopSelf();
//   });
// }


// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:login/services/steps_counter_service.dart';

// void initializeService() {
//   FlutterBackgroundService().configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//       notificationChannelId: 'step_tracker_channel',
//       foregroundServiceNotificationId: 888,
//       initialNotificationTitle: 'Step Tracker Running',
//       initialNotificationContent: 'Tracking your steps in background',
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: true,
//       onForeground: onStart,
//     ),
//   );
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   final stepService = StepCounterService();
//   await stepService.syncNow();

//   if (service is AndroidServiceInstance) {
//     service.setForegroundNotificationInfo(
//       title: "Step Tracker",
//       content: "Running in background",
//     );
//   }

//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });
// }
