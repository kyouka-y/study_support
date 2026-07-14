import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../models/submission.dart';

class SubmissionCard extends StatelessWidget {
  final Submission submission;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  const SubmissionCard({
    super.key,
    required this.submission,
    this.onTap,
    required this.onDelete,
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

    final hasReply =
        submission.teacherReply.trim().isNotEmpty;

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
                  Text(
                    _formatDate(
                      submission.createdAt,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: '送信を取り消す',
                    icon: const Icon(
                      Icons.delete_outline,
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
              if (hasReply) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.shade100,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.reply,
                            size: 18,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '先生からの返信',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        submission.teacherReply,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}