// import 'package:hive/hive.dart';

// class StepsStorageService {
//   final Box<int> stepsBox = Hive.box<int>('steps');
//   final Box<int> initialStepsBox = Hive.box<int>('initSteps');
//   final Box<double> distanceBox = Hive.box<double>('distance');

//   String todayKey() {
//     final now = DateTime.now();
//     return '${now.year}-${now.month}-${now.day}';
//   }

//   int getTodaySteps() => stepsBox.get(todayKey(), defaultValue: 0)!;
//   int getInitialSteps() => initialStepsBox.get(todayKey(), defaultValue: 0)!;
//   double getTodayDistance() => distanceBox.get(todayKey(), defaultValue: 0.0)!;

//   void saveTodaySteps(int steps) => stepsBox.put(todayKey(), steps);
//   void saveInitialSteps(int steps) => initialStepsBox.put(todayKey(), steps);
//   void saveDistance(double distance) => distanceBox.put(todayKey(), distance);
// }
