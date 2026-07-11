import 'package:cloud_firestore/cloud_firestore.dart';

class RelationshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> linkStudent({
    required String teacherUid,
    required String studentLoginId,
  }) async {
    final normalizedLoginId =
        studentLoginId.trim().toUpperCase();

    final studentQuery = await _firestore
        .collection('users')
        .where('loginId', isEqualTo: normalizedLoginId)
        .where('role', isEqualTo: 'student')
        .limit(1)
        .get();

    if (studentQuery.docs.isEmpty) {
      throw Exception('生徒が見つかりません');
    }

    final studentUid = studentQuery.docs.first.id;

    final existingRelationship = await _firestore
        .collection('teacher_students')
        .where('teacherUid', isEqualTo: teacherUid)
        .where('studentUid', isEqualTo: studentUid)
        .limit(1)
        .get();

    if (existingRelationship.docs.isNotEmpty) {
      throw Exception('この生徒はすでに登録されています');
    }

    await _firestore.collection('teacher_students').add({
      'teacherUid': teacherUid,
      'studentUid': studentUid,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getStudents(
    String teacherUid,
  ) async {
    final relationshipQuery = await _firestore
        .collection('teacher_students')
        .where('teacherUid', isEqualTo: teacherUid)
        .where('active', isEqualTo: true)
        .get();

    final students = <Map<String, dynamic>>[];

    for (final relationship in relationshipQuery.docs) {
      final studentUid =
          relationship.data()['studentUid'] as String;

      final studentDocument = await _firestore
          .collection('users')
          .doc(studentUid)
          .get();

      if (studentDocument.exists) {
        students.add({
          'uid': studentDocument.id,
          ...studentDocument.data()!,
        });
      }
    }

    return students;
  }
}