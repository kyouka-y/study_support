import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/homework_service.dart';

class StudentHomeworkPage extends StatefulWidget {
  const StudentHomeworkPage({super.key});

  @override
  State<StudentHomeworkPage> createState() =>
      _StudentHomeworkPageState();
}

class _StudentHomeworkPageState
    extends State<StudentHomeworkPage> {
  final HomeworkService _homeworkService = HomeworkService();

  List<Map<String, dynamic>> _homeworks = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHomeworks();
  }

  Future<void> _loadHomeworks() async {
    try {
      final student = FirebaseAuth.instance.currentUser;

      if (student == null) {
        setState(() {
          _errorMessage = 'ログインしていません';
          _isLoading = false;
        });
        return;
      }

      final homeworks =
          await _homeworkService.getStudentHomeworks(
        student.uid,
      );

      if (!mounted) return;

      setState(() {
        _homeworks = homeworks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _completeHomework(
    String homeworkId,
  ) async {
    await _homeworkService.completeHomework(
      homeworkId,
    );

    await _loadHomeworks();
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return '期限なし';
    }

    final date = timestamp.toDate();

    return '${date.year}/${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('宿題'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          'エラー: $_errorMessage',
        ),
      );
    }

    if (_homeworks.isEmpty) {
      return const Center(
        child: Text('宿題はありません'),
      );
    }

    return ListView.builder(
      itemCount: _homeworks.length,
      itemBuilder: (context, index) {
        final homework = _homeworks[index];

        final String homeworkId = homework['id'];
        final String title = homework['title'] ?? '';
        final String description =
            homework['description'] ?? '';

        final bool completed =
            homework['completed'] ?? false;

        final Timestamp? dueDate = homework['dueDate'];

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(description),

                const SizedBox(height: 8),

                Text(
                  '期限：${_formatDate(dueDate)}',
                ),

                const SizedBox(height: 16),

                if (completed)
                  const Text(
                    '✅ 完了済み',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _completeHomework(homeworkId);
                      },
                      child: const Text('完了'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}