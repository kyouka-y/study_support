import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/submission.dart';
import '../../services/submission_service.dart';
import 'submission/widgets/submission_card.dart';
import 'submission/widgets/submission_input.dart';

class StudentSubmissionPage extends StatefulWidget {
  const StudentSubmissionPage({super.key});

  @override
  State<StudentSubmissionPage> createState() =>
      _StudentSubmissionPageState();
}

class _StudentSubmissionPageState
    extends State<StudentSubmissionPage> {
  static const int _pageSize = 20;

  final SubmissionService _submissionService =
      SubmissionService();

  final TextEditingController _messageController =
      TextEditingController();

  final List<Submission> _submissions = [];

  bool _isSending = false;
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

  @override
  void dispose() {
    _messageController.dispose();

    super.dispose();
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
          await _submissionService.getSubmissions(
        studentUid: user.uid,
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
            '提出履歴取得エラー\n$e',
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
          await _submissionService.getSubmissions(
        studentUid: user.uid,
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
            '過去の提出取得エラー\n$e',
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

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final message = _messageController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'メッセージを入力してください',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _submissionService.submit(
        studentUid: user.uid,
        message: message,
      );

      _messageController.clear();

      await _loadInitialSubmissions();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('提出しました'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '提出エラー\n$e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _deleteSubmission(
    Submission submission,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('送信取り消し'),
          content: const Text(
            'この提出を削除しますか？',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                '削除',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    try {
      await _submissionService.deleteSubmission(
        submission.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _submissions.removeWhere(
          (item) => item.id == submission.id,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '送信を取り消しました',
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
            '削除エラー\n$e',
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
              Icons.outbox_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'まだ提出はありません',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                '先生に質問や資料を送れます',
                style: TextStyle(
                  color: Colors.grey,
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
                          child:
                              CircularProgressIndicator(
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

          return SubmissionCard(
            submission: submission,
            onDelete: () {
              _deleteSubmission(submission);
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
        title: const Text('提出ボックス'),
        actions: [
          IconButton(
            onPressed: _loadInitialSubmissions,
            tooltip: '更新',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildSubmissionList(),
          ),
          SubmissionInput(
            controller: _messageController,
            isSending: _isSending,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}