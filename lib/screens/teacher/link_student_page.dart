import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/relationship_service.dart';

class LinkStudentPage extends StatefulWidget {
  const LinkStudentPage({super.key});

  @override
  State<LinkStudentPage> createState() =>
      _LinkStudentPageState();
}

class _LinkStudentPageState extends State<LinkStudentPage> {
  final TextEditingController _studentIdController =
      TextEditingController();

  final RelationshipService _relationshipService =
      RelationshipService();

  bool _isLoading = false;
  String? _message;

  Future<void> _linkStudent() async {
    final teacher = FirebaseAuth.instance.currentUser;

    if (teacher == null) {
      setState(() {
        _message = 'ログインしていません';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _relationshipService.linkStudent(
        teacherUid: teacher.uid,
        studentLoginId: _studentIdController.text,
      );

      setState(() {
        _message = '生徒を登録しました';
      });

      _studentIdController.clear();
    } catch (e) {
      setState(() {
        _message = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
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
    _studentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生徒を登録'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: '生徒ID',
                hintText: 'S001',
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isLoading ? null : _linkStudent,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('生徒を登録'),
              ),
            ),

            const SizedBox(height: 24),

            if (_message != null)
              Text(
                _message!,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}