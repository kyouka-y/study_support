import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/homework_service.dart';
import 'student_schedule_page.dart';

class StudentDetailPage extends StatefulWidget {
  final String studentUid;
  final String studentName;
  final String studentLoginId;

  const StudentDetailPage({
    super.key,
    required this.studentUid,
    required this.studentName,
    required this.studentLoginId,
  });

  @override
  State<StudentDetailPage> createState() =>
      _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  final HomeworkService _homeworkService = HomeworkService();

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  DateTime? _dueDate;

  bool _isLoading = false;
  String? _message;

  Future<void> _selectDueDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );

    if (selectedDate != null) {
      setState(() {
        _dueDate = selectedDate;
      });
    }
  }

  Future<void> _createHomework() async {
    final teacher = FirebaseAuth.instance.currentUser;

    if (teacher == null) {
      setState(() {
        _message = 'ログインしていません';
      });
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      setState(() {
        _message = '宿題名を入力してください';
      });
      return;
    }

    if (_dueDate == null) {
      setState(() {
        _message = '期限を選択してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _homeworkService.createHomework(
        teacherUid: teacher.uid,
        studentUid: widget.studentUid,
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: _dueDate!,
      );

      if (!mounted) return;

      setState(() {
        _message = '宿題を登録しました';
        _dueDate = null;
      });

      _titleController.clear();
      _descriptionController.clear();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'エラー: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
        title: Text(widget.studentName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              widget.studentName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(widget.studentLoginId),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentSchedulePage(
                        studentUid: widget.studentUid,
                        studentName: widget.studentName,
                      ),
                    ),
                  );
                },
                child: const Text('1日の予定を登録'),
              ),
            ),

            const SizedBox(height: 32),

            const Text(
              '宿題を登録',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '宿題名',
                hintText: '数学ワーク',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '内容',
                hintText: 'p.20〜25',
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: _selectDueDate,
              child: Text(
                _dueDate == null
                    ? '期限を選択'
                    : '期限：'
                        '${_dueDate!.year}/'
                        '${_dueDate!.month}/'
                        '${_dueDate!.day}',
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _createHomework,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('宿題を登録'),
            ),

            const SizedBox(height: 16),

            if (_message != null)
              Text(
                _message!,
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 40),

            const Text(
              '登録済みの宿題',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('homeworks')
                  .where(
                    'studentUid',
                    isEqualTo: widget.studentUid,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'エラー: ${snapshot.error}',
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final homeworks = snapshot.data!.docs;

                if (homeworks.isEmpty) {
                  return const Text('宿題はありません');
                }

                return Column(
                  children: homeworks.map((document) {
                    final data =
                        document.data() as Map<String, dynamic>;

                    final String title =
                        data['title'] ?? '';

                    final String description =
                        data['description'] ?? '';

                    final bool completed =
                        data['completed'] ?? false;

                    final Timestamp? dueDate =
                        data['dueDate'] as Timestamp?;

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          completed
                              ? Icons.check_circle
                              : Icons.assignment,
                        ),
                        title: Text(title),
                        subtitle: Text(
                          '$description\n'
                          '期限：${_formatDate(dueDate)}',
                        ),
                        trailing: Text(
                          completed ? '完了' : '未完了',
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}