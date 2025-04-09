// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class FirestoreService {
//   static final _db = FirebaseFirestore.instance;

//   static Future<void> saveStepsToFirestore(int steps) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

//     await _db
//         .collection('users')
//         .doc(user.uid)
//         .collection('dailySteps')
//         .doc(dateKey)
//         .set({'steps': steps});
//   }
// }
