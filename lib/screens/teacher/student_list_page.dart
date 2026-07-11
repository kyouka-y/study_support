import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/relationship_service.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() =>
      _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final RelationshipService _relationshipService =
      RelationshipService();

  List<Map<String, dynamic>> _students = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final teacher = FirebaseAuth.instance.currentUser;

      if (teacher == null) {
        setState(() {
          _errorMessage = 'ログインしていません';
          _isLoading = false;
        });

        return;
      }

      final students = await _relationshipService.getStudents(
        teacher.uid,
      );

      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('担当生徒'),
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

    if (_students.isEmpty) {
      return const Center(
        child: Text('登録されている生徒はいません'),
      );
    }

    return ListView.builder(
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];

        final name = student['name'] ?? '';
        final loginId = student['loginId'] ?? '';

        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person),
          ),
          title: Text(name),
          subtitle: Text(loginId),
          trailing: const Icon(
            Icons.chevron_right,
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name を選択しました'),
              ),
            );
          },
        );
      },
    );
  }
}