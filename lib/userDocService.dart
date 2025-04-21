import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDocumentService {
  static String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  static DocumentReference get _userDoc {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  static Future<void> initializeUserDocument() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await _userDoc.set({
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'attendanceRecords': {},
    }, SetOptions(merge: true)); // Merge with existing data if any
  }

  static Stream<DocumentSnapshot> get userStream => _userDoc.snapshots();

  static Future<Map<String, dynamic>> getCourseAttendance(String courseCode) async {
    final snapshot = await _userDoc.get();
    final data = snapshot.data() as Map<String, dynamic>?;
    return data?['attendanceRecords']?[courseCode] ?? {};
  }

  static Future<void> updateCourseAttendance({
    required String courseCode,
    required int attendanceLevel,
  }) async {
    await _userDoc.update({
      'attendanceRecords.$courseCode': {
        'Attendance Level': attendanceLevel,
        'Last Attended': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

Future<void> createUserDocument() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not authenticated');
  
  await FirebaseFirestore.instance
    .collection('users')
    .doc(user.uid)  // Using UID as document ID
    .set({
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'attendanceRecords': {}
    });
}

