import 'dart:async';
import 'dart:math';
// import 'package:background_fetch/background_fetch.dart';
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
  late Box<double> _distanceBox;

  double _stepLength = 60.0; // cm
  double _totalDistance = 0.0;

  // Dùng để lọc lắc nhẹ
  double _movementThreshold = 1.5; // Gia tốc trung bình để được coi là đang đi
  double _avgAcceleration = 0.0;
  List<double> _accelHistory = [];

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  @override
  void initState() {
    super.initState();
    _initPermissionsAndStart();
    // _initBackgroundFetch();
  }

  Future<void> _initPermissionsAndStart() async {
    _stepsBox = Hive.box<int>('steps');
    _initialStepsBox = Hive.box<int>('initSteps');
    _distanceBox = Hive.box<double>('distance');

    final status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      _loadTodaySteps();
      _loadInitialStepCount();
      _loadTotalDistance();
      _startStepTracking();
      _startAccelerometer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permission denied. Cannot track steps.")),
      );
    }
  }


//   void _initBackgroundFetch() async {
//   BackgroundFetch.configure(
//     BackgroundFetchConfig(
//       minimumFetchInterval: 15, // 15 phút (Android giới hạn thấp nhất)
//       stopOnTerminate: false,
//       enableHeadless: true,
//       startOnBoot: true,
//       requiresBatteryNotLow: false,
//       requiresCharging: false,
//       requiresStorageNotLow: false,
//       requiresDeviceIdle: false,
//       requiredNetworkType: NetworkType.NONE,
//     ),
//     (String taskId) async {
//       // ✅ Gọi lại lưu Hive và sync Firestore
//       print("[BackgroundFetch] Event received $taskId");

//       // Lấy lại Hive box
//       final stepsBox = Hive.box<int>('steps');
//       final distanceBox = Hive.box<double>('distance');
//       final key = _todayKey;
//       final steps = stepsBox.get(key, defaultValue: 0)!;
//       final distance = distanceBox.get(key, defaultValue: 0.0)!;

//       _syncToFirestore(steps, distance / 100);

//       BackgroundFetch.finish(taskId);
//     },
//     (String taskId) async {
//       print("[BackgroundFetch] TIMEOUT: $taskId");
//       BackgroundFetch.finish(taskId);
//     },
//   );
// }


  void _loadTodaySteps() {
    _stepsToday = _stepsBox.get(_todayKey, defaultValue: 0)!;
    setState(() {});
  }

  void _loadInitialStepCount() {
    _initialStepCount = _initialStepsBox.get(_todayKey, defaultValue: 0)!;
  }

  void _loadTotalDistance() {
    _totalDistance = _distanceBox.get(_todayKey, defaultValue: 0.0)!;
  }

  void _startAccelerometer() {
    _accelerometerStream = accelerometerEvents.listen((AccelerometerEvent event) {
      double acc = sqrt(event.x * event.x + event.y * event.y + event.z * event.z) - 9.8;
      acc = acc.abs();

      _accelHistory.add(acc);
      if (_accelHistory.length > 20) {
        _accelHistory.removeAt(0);
      }

      // Tính trung bình dao động trong 1 khoảng thời gian
      double sum = _accelHistory.fold(0, (prev, x) => prev + x);
      _avgAcceleration = sum / _accelHistory.length;
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
    if (_initialStepCount == 0) {
      _initialStepCount = event.steps;
      _initialStepsBox.put(_todayKey, _initialStepCount);
    }

    final todaySteps = event.steps - _initialStepCount;

    // ✅ Chỉ cập nhật bước nếu đang "chuyển động thực sự"
    if (todaySteps != _stepsToday && todaySteps >= 0 && _avgAcceleration > _movementThreshold) {
      setState(() {
        _stepsToday = todaySteps;
        _totalDistance = _stepsToday * _stepLength;
      });
      _stepsBox.put(_todayKey, _stepsToday);
      _distanceBox.put(_todayKey, _totalDistance);
      _syncToFirestore(_stepsToday, _totalDistance / 100);
    }
  }

  void _onStepError(error) {
    print('Pedometer error: $error');
  }

  void _syncToFirestore(int steps, double distance) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('steps')
          .doc(dateKey)
          .set({'steps': steps, 'distance': distance, 'timestamp': DateTime.now()});
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
    double distanceInMeters = _totalDistance / 100;

    return Scaffold(
      appBar: AppBar(title: Text("Daily Steps")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
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
            SizedBox(height: 20),
            Text(
              'Distance: ${distanceInMeters.toStringAsFixed(2)} m',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Avg Accel: ${_avgAcceleration.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:login/services/steps_counter_service.dart';
// import 'package:percent_indicator/circular_percent_indicator.dart';

// class StepTrackerScreen extends StatefulWidget {
//   @override
//   State<StepTrackerScreen> createState() => _StepTrackerScreenState();
// }

// class _StepTrackerScreenState extends State<StepTrackerScreen> {
//   final _service = StepCounterService();
//   final int _dailyGoal = 6000;

//   @override
//   void initState() {
//     super.initState();
//     _service.init().then((_) {
//       setState(() {});
//       _service.start();
//     });
//   }

//   @override
//   void dispose() {
//     _service.stop();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final percent = (_service.stepsToday / _dailyGoal).clamp(0.0, 1.0);
//     return Scaffold(
//       appBar: AppBar(title: Text("Daily Steps")),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularPercentIndicator(
//               radius: 150,
//               lineWidth: 12,
//               animation: true,
//               percent: percent,
//               center: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text('${_service.stepsToday}', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
//                   Text("steps", style: TextStyle(fontSize: 18)),
//                 ],
//               ),
//               progressColor: Colors.green,
//               backgroundColor: Colors.grey[300]!,
//               circularStrokeCap: CircularStrokeCap.round,
//             ),
//             SizedBox(height: 20),
//             Text('Distance: ${_service.getDistanceInMeters().toStringAsFixed(2)} m', style: TextStyle(fontSize: 20)),
//             SizedBox(height: 10),
//             Text('Avg Accel: ${_service.avgAcceleration.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, color: Colors.grey)),
//           ],
//         ),
//       ),
//     );
//   }
// }
