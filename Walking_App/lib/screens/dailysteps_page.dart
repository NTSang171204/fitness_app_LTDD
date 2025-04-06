// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:pedometer/pedometer.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   await Hive.initFlutter();
//   await Hive.openBox<int>('stepBox');
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Step Tracker',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: StepTrackerScreen(),
//     );
//   }
// }

// class StepTrackerScreen extends StatefulWidget {
//   @override
//   _StepTrackerScreenState createState() => _StepTrackerScreenState();
// }

// class _StepTrackerScreenState extends State<StepTrackerScreen> {
//   late Stream<StepCount> _stepCountStream;
//   int _steps = 0;
//   double _km = 0.0;
//   double _calories = 0.0;

//   final Box<int> stepBox = Hive.box<int>('stepBox');

//   @override
//   void initState() {
//     super.initState();
//     _initStepCount();
//     _loadSavedSteps();
//   }

//   void _initStepCount() {
//     _stepCountStream = Pedometer.stepCountStream;
//     _stepCountStream.listen(
//       (StepCount event) {
//         setState(() {
//           _steps = event.steps;
//           _km = _steps * 0.0008; // 1000 bước = 0.8 km
//           _calories = _steps * 0.04;
//         });

//         // Lưu vào Hive
//         stepBox.put('steps', _steps);

//         // Lưu vào Firestore
//         FirebaseFirestore.instance.collection('stepData').add({
//           'steps': _steps,
//           'km': _km,
//           'calories': _calories,
//           'timestamp': Timestamp.now(),
//         });
//       },
//       onError: (error) => print('Lỗi bước chân: $error'),
//     );
//   }

//   void _loadSavedSteps() {
//     final savedSteps = stepBox.get('steps', defaultValue: 0) ?? 0;
//     setState(() {
//       _steps = savedSteps;
//       _km = _steps * 0.0008;
//       _calories = _steps * 0.04;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Step Tracker')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('Steps: $_steps', style: TextStyle(fontSize: 24)),
//             SizedBox(height: 10),
//             Text('Kilometers: ${_km.toStringAsFixed(2)} km', style: TextStyle(fontSize: 20)),
//             SizedBox(height: 10),
//             Text('Calories: ${_calories.toStringAsFixed(2)} cal', style: TextStyle(fontSize: 20)),
//           ],
//         ),
//       ),
//     );
//   }
// }
