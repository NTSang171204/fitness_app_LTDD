// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class FirestoreSyncService {
//   final Map<String, DateTime> _lastSyncedMap = {};

//   Future<bool> syncToFirestore({
//     required String dateKey,
//     required int steps,
//     required double distanceInMeters,
//     bool force = false,
//   }) async {
//     final now = DateTime.now();
//     if (!force &&
//         _lastSyncedMap[dateKey] != null &&
//         now.difference(_lastSyncedMap[dateKey]!).inMinutes < 5) {
//       return false;
//     }

//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return false;

//     try {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('steps')
//           .doc(dateKey)
//           .set({
//         'steps': steps,
//         'distance': distanceInMeters,
//         'timestamp': now,
//       });
//       _lastSyncedMap[dateKey] = now;
//       print("✅ Synced to Firestore for $dateKey at $now");
//       return true;
//     } catch (e) {
//       print("❌ Firestore sync error: $e");
//       return false;
//     }
//   }
// }
