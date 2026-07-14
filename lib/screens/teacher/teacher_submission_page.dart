import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/submission.dart';
import '../../services/submission_service.dart';
import 'submission/widgets/teacher_submission_card.dart';

class TeacherSubmissionPage extends StatefulWidget {
  const TeacherSubmissionPage({super.key});

  @override
  State<TeacherSubmissionPage> createState() =>
      _TeacherSubmissionPageState();
}

class _TeacherSubmissionPageState
    extends State<TeacherSubmissionPage> {
  static const int _pageSize = 20;

  final SubmissionService _submissionService =
      SubmissionService();

  final List<Submission> _submissions = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  QueryDocumentSnapshot<Map<String, dynamic>>?
      _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadInitialSubmissions();
  }

  Future<void> _loadInitialSubmissions() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          await _submissionService.getTeacherSubmissions(
        teacherUid: user.uid,
        pageSize: _pageSize,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _submissions
          ..clear()
          ..addAll(result.submissions);

        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '受信データ取得エラー\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreSubmissions() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null ||
        _lastDocument == null ||
        !_hasMore ||
        _isLoadingMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result =
          await _submissionService.getTeacherSubmissions(
        teacherUid: user.uid,
        pageSize: _pageSize,
        lastDocument: _lastDocument,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _submissions.addAll(
          result.submissions,
        );

        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '過去の受信データ取得エラー\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _openSubmission(
    Submission submission,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  submission.studentName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  submission.message,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                if (submission.teacherReply.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    '先生の返信',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      submission.teacherReply,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  '分類',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(
                    Icons.help_outline,
                    color: Colors.blue,
                  ),
                  title: const Text('質問'),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'category:question',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.assignment_outlined,
                    color: Colors.orange,
                  ),
                  title: const Text('宿題'),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'category:homework',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.fact_check_outlined,
                    color: Colors.purple,
                  ),
                  title: const Text('テスト範囲'),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'category:test_range',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.more_horiz,
                    color: Colors.grey,
                  ),
                  title: const Text('その他'),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'category:other',
                    );
                  },
                ),
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(
                    Icons.reply,
                    color: Colors.green,
                  ),
                  title: Text(
                    submission.teacherReply.isEmpty
                        ? '返信する'
                        : '返信を変更する',
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'reply',
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    if (result == 'reply') {
      await _openReplyDialog(submission);
      return;
    }

    if (result.startsWith('category:')) {
      final category = result.substring(
        'category:'.length,
      );

      await _updateCategory(
        submission,
        category,
      );
    }
  }

  Future<void> _openReplyDialog(
    Submission submission,
  ) async {
    final controller = TextEditingController(
      text: submission.teacherReply,
    );

    final reply = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            '${submission.studentName}さんへ返信',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: '返信を入力してください',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();

                if (text.isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  text,
                );
              },
              child: const Text('返信する'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reply == null || reply.isEmpty) {
      return;
    }

    await _sendReply(
      submission,
      reply,
    );
  }

  Future<void> _sendReply(
    Submission submission,
    String reply,
  ) async {
    try {
      await _submissionService.sendTeacherReply(
        submissionId: submission.id,
        reply: reply,
      );

      await _loadInitialSubmissions();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '返信を送信しました',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '返信送信エラー\n$e',
          ),
        ),
      );
    }
  }

  Future<void> _updateCategory(
    Submission submission,
    String category,
  ) async {
    try {
      await _submissionService.updateCategory(
        submissionId: submission.id,
        category: category,
      );

      await _loadInitialSubmissions();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '分類を保存しました',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '分類保存エラー\n$e',
          ),
        ),
      );
    }
  }

  Widget _buildSubmissionList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_submissions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadInitialSubmissions,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 160),
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                '受信した提出はありません',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialSubmissions,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount:
            _submissions.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == _submissions.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: _isLoadingMore
                      ? null
                      : _loadMoreSubmissions,
                  icon: _isLoadingMore
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.expand_more,
                        ),
                  label: Text(
                    _isLoadingMore
                        ? '読み込み中...'
                        : '過去の提出を読み込む',
                  ),
                ),
              ),
            );
          }

          final submission = _submissions[index];

          return TeacherSubmissionCard(
            submission: submission,
            onTap: () {
              _openSubmission(submission);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'ログインしていません',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('受信ボックス'),
        actions: [
          IconButton(
            onPressed: _loadInitialSubmissions,
            tooltip: '更新',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildSubmissionList(),
    );
  }
}