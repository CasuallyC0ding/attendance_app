import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String documentId;
  final Map<String, CourseAttendance> courses;

  AttendanceRecord({
    required this.documentId,
    required this.courses,
  });

  // Factory constructor to create an AttendanceRecord from Firestore document
  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final courses = <String, CourseAttendance>{};

    // Extract course data from the document
    data.forEach((key, value) {
      if (key != 'documentId' && value is Map<String, dynamic>) {
        courses[key] = CourseAttendance.fromMap(value);
      }
    });

    return AttendanceRecord(
      documentId: doc.id,
      courses: courses,
    );
  }

  // Convert the attendance record to a map for Firestore
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{};
    
    courses.forEach((courseCode, attendance) {
      map[courseCode] = attendance.toMap();
    });

    return map;
  }

  // Helper method to update attendance for a course
  Future<void> updateCourseAttendance({
    required String courseCode,
    required int attendanceLevel,
    required DateTime lastAttended,
  }) async {
    courses[courseCode] = CourseAttendance(
      attendanceLevel: attendanceLevel,
      lastAttended: lastAttended,
    );

    await FirebaseFirestore.instance
        .collection('Attendance Record')
        .doc(documentId)
        .update({
          courseCode: courses[courseCode]!.toMap(),
        });
  }
}

class CourseAttendance {
  final int attendanceLevel;
  final DateTime lastAttended;

  CourseAttendance({
    required this.attendanceLevel,
    required this.lastAttended,
  });

  factory CourseAttendance.fromMap(Map<String, dynamic> map) {
    return CourseAttendance(
      attendanceLevel: map['Attendance Level'] as int? ?? 0,
      lastAttended: (map['Last Attended'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'Attendance Level': attendanceLevel,
      'Last Attended': Timestamp.fromDate(lastAttended),
    };
  }
}