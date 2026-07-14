import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/submission.dart';

class SubmissionPageResult {
  final List<Submission> submissions;

  final QueryDocumentSnapshot<Map<String, dynamic>>?
      lastDocument;

  final bool hasMore;

  const SubmissionPageResult({
    required this.submissions,
    required this.lastDocument,
    required this.hasMore,
  });
}

class SubmissionService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  Future<String?> findTeacherUid(
    String studentUid,
  ) async {
    final snapshot = await _firestore
        .collection('teacher_students')
        .where(
          'studentUid',
          isEqualTo: studentUid,
        )
        .where(
          'active',
          isEqualTo: true,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final data = snapshot.docs.first.data();

    return data['teacherUid'] as String?;
  }

  Future<String> findStudentName(
    String studentUid,
  ) async {
    final document = await _firestore
        .collection('users')
        .doc(studentUid)
        .get();

    if (!document.exists) {
      return '名前未設定';
    }

    final data = document.data();

    if (data == null) {
      return '名前未設定';
    }

    return data['name'] as String? ?? '名前未設定';
  }

  Future<SubmissionPageResult> getSubmissions({
    required String studentUid,
    required int pageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>?
        lastDocument,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('submissions')
        .where(
          'studentUid',
          isEqualTo: studentUid,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(pageSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(
        lastDocument,
      );
    }

    final snapshot = await query.get();

    final submissions = snapshot.docs
        .map(
          Submission.fromDocument,
        )
        .toList();

    return SubmissionPageResult(
      submissions: submissions,
      lastDocument: snapshot.docs.isNotEmpty
          ? snapshot.docs.last
          : null,
      hasMore: snapshot.docs.length == pageSize,
    );
  }

  Future<SubmissionPageResult> getTeacherSubmissions({
    required String teacherUid,
    required int pageSize,
    QueryDocumentSnapshot<Map<String, dynamic>>?
        lastDocument,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('submissions')
        .where(
          'teacherUid',
          isEqualTo: teacherUid,
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(pageSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(
        lastDocument,
      );
    }

    final snapshot = await query.get();

    final submissions = snapshot.docs
        .map(
          Submission.fromDocument,
        )
        .toList();

    return SubmissionPageResult(
      submissions: submissions,
      lastDocument: snapshot.docs.isNotEmpty
          ? snapshot.docs.last
          : null,
      hasMore: snapshot.docs.length == pageSize,
    );
  }

  Future<void> submit({
    required String studentUid,
    required String message,
    XFile? image,
  }) async {
    final teacherUid = await findTeacherUid(
      studentUid,
    );

    if (teacherUid == null || teacherUid.isEmpty) {
      throw Exception(
        '担当の先生が見つかりません',
      );
    }

    final studentName = await findStudentName(
      studentUid,
    );

    final submissionReference =
        _firestore.collection('submissions').doc();

    String imageUrl = '';
    String imagePath = '';

    try {
      if (image != null) {
        final imageBytes = await image.readAsBytes();

        imagePath =
            'submissions/$studentUid/${submissionReference.id}.jpg';

        final storageReference =
            _storage.ref().child(imagePath);

        await storageReference.putData(
          imageBytes,
          SettableMetadata(
            contentType: image.mimeType ?? 'image/jpeg',
          ),
        );

        imageUrl =
            await storageReference.getDownloadURL();
      }

      await submissionReference.set({
        'studentUid': studentUid,
        'studentName': studentName,
        'teacherUid': teacherUid,
        'message': message,
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'category': 'unclassified',
        'status': 'submitted',
        'teacherReply': '',
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'repliedAt': null,
      });
    } catch (e) {
      if (imagePath.isNotEmpty) {
        try {
          await _storage
              .ref()
              .child(imagePath)
              .delete();
        } catch (_) {
          // アップロード未完了などの場合は何もしない
        }
      }

      rethrow;
    }
  }

  Future<void> updateCategory({
    required String submissionId,
    required String category,
  }) async {
    await _firestore
        .collection('submissions')
        .doc(submissionId)
        .update({
      'category': category,
      'status': 'reviewed',
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendTeacherReply({
    required String submissionId,
    required String reply,
  }) async {
    await _firestore
        .collection('submissions')
        .doc(submissionId)
        .update({
      'teacherReply': reply,
      'status': 'replied',
      'repliedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSubmission(
    String submissionId,
  ) async {
    final documentReference = _firestore
        .collection('submissions')
        .doc(submissionId);

    final document = await documentReference.get();

    if (!document.exists) {
      return;
    }

    final data = document.data();

    final imagePath =
        data?['imagePath'] as String? ?? '';

    if (imagePath.isNotEmpty) {
      try {
        await _storage
            .ref()
            .child(imagePath)
            .delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') {
          rethrow;
        }
      }
    }

    await documentReference.delete();
  }
}

