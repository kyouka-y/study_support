import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/user_model.dart';
import 'services/user_service.dart';
import 'screens/teacher/teacher_home_page.dart';
import 'screens/student/student_home_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserService _userService = UserService();

  AppUser? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        setState(() {
          _errorMessage = 'ログインしていません';
          _isLoading = false;
        });
        return;
      }

      final user = await _userService.getUserByUid(
        firebaseUser.uid,
      );

      setState(() {
        _user = user;
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(
            'エラー: $_errorMessage',
          ),
        ),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(
          child: Text('ユーザー情報が見つかりません'),
        ),
      );
    }

    switch (_user!.role) {
      case 'teacher':
        return TeacherHomePage(
          userName: _user!.name,
        );

      case 'student':
        return StudentHomePage(
          userName: _user!.name,
        );

      default:
        return Scaffold(
          body: Center(
            child: Text(
              '不明なユーザー種別です: ${_user!.role}',
            ),
          ),
        );
    }
  }
}