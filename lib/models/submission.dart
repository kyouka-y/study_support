import 'package:cloud_firestore/cloud_firestore.dart';

class Submission {
  final String id;
  final String studentUid;
  final String studentName;
  final String teacherUid;
  final String message;

  final String imageUrl;
  final String imagePath;

  final String category;
  final String status;
  final String teacherReply;

  final Timestamp? createdAt;
  final Timestamp? reviewedAt;
  final Timestamp? repliedAt;

  const Submission({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.teacherUid,
    required this.message,
    required this.imageUrl,
    required this.imagePath,
    required this.category,
    required this.status,
    required this.teacherReply,
    required this.createdAt,
    required this.reviewedAt,
    required this.repliedAt,
  });

  factory Submission.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return Submission(
      id: document.id,
      studentUid:
          data['studentUid'] as String? ?? '',
      studentName:
          data['studentName'] as String? ?? '名前未設定',
      teacherUid:
          data['teacherUid'] as String? ?? '',
      message:
          data['message'] as String? ?? '',
      imageUrl:
          data['imageUrl'] as String? ?? '',
      imagePath:
          data['imagePath'] as String? ?? '',
      category:
          data['category'] as String? ?? 'unclassified',
      status:
          data['status'] as String? ?? 'submitted',
      teacherReply:
          data['teacherReply'] as String? ?? '',
      createdAt:
          data['createdAt'] as Timestamp?,
      reviewedAt:
          data['reviewedAt'] as Timestamp?,
      repliedAt:
          data['repliedAt'] as Timestamp?,
    );
  }

  bool get hasImage {
    return imageUrl.trim().isNotEmpty;
  }

  bool get hasTeacherReply {
    return teacherReply.trim().isNotEmpty;
  }
}