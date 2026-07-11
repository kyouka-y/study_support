import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createHomework({
    required String teacherUid,
    required String studentUid,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    await _firestore.collection('homeworks').add({
      'teacherUid': teacherUid,
      'studentUid': studentUid,
      'title': title.trim(),
      'description': description.trim(),
      'dueDate': Timestamp.fromDate(dueDate),
      'completed': false,
      'completedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getStudentHomeworks(
    String studentUid,
  ) async {
    final querySnapshot = await _firestore
        .collection('homeworks')
        .where('studentUid', isEqualTo: studentUid)
        .get();

    return querySnapshot.docs.map((document) {
      return {
        'id': document.id,
        ...document.data(),
      };
    }).toList();
  }

  Future<void> completeHomework(String homeworkId) async {
    await _firestore
        .collection('homeworks')
        .doc(homeworkId)
        .update({
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}