import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../models/submission.dart';

class TeacherSubmissionCard extends StatelessWidget {
  final Submission submission;
  final VoidCallback onTap;

  const TeacherSubmissionCard({
    super.key,
    required this.submission,
    required this.onTap,
  });

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return '送信中';
    }

    final date = timestamp.toDate();

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$month/$day $hour:$minute';
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'question':
        return '質問';

      case 'homework':
        return '宿題';

      case 'test_range':
        return 'テスト範囲';

      case 'other':
        return 'その他';

      default:
        return '未分類';
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'question':
        return Colors.blue;

      case 'homework':
        return Colors.orange;

      case 'test_range':
        return Colors.purple;

      case 'other':
        return Colors.grey;

      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(
      submission.category,
    );

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      submission.studentName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(
                      submission.createdAt,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                submission.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _categoryLabel(
                        submission.category,
                      ),
                      style: TextStyle(
                        color: categoryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}