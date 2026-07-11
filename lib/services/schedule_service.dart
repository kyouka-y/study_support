import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createSchedule({
    required String createdByUid,
    required String createdByRole,
    required String studentUid,
    required String title,
    required DateTime date,
    required TimeStamp startTime,
    required TimeStamp endTime,
  }) async {
    await _firestore.collection('daily_schedules').add({
      'createdByUid': createdByUid,
      'createdByRole': createdByRole,
      'studentUid': studentUid,
      'title': title.trim(),
      'date': Timestamp.fromDate(
        DateTime(date.year, date.month, date.day),
      ),
      'startMinutes': startTime.minutes,
      'endMinutes': endTime.minutes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getStudentSchedules(
    String studentUid,
  ) {
    return _firestore
        .collection('daily_schedules')
        .where('studentUid', isEqualTo: studentUid)
        .snapshots();
  }
}

class TimeStamp {
  final int hour;
  final int minute;

  const TimeStamp({
    required this.hour,
    required this.minute,
  });

  int get minutes => hour * 60 + minute;
}