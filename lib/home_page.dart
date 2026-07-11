import 'package:flutter/material.dart';

import 'schedule_menu_page.dart';
import 'timetable_menu_page.dart';
import 'homework_menu_page.dart';

import 'models/user_model.dart';
import 'services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Support'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_errorMessage != null)
              Text('エラー: $_errorMessage')
            else if (_user == null)
              const Text('ユーザーが見つかりません')
            else
              Text(
                '${_user!.name} さん',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScheduleMenuPage(),
                    ),
                  );
                },
                child: const Text('予定を確認する'),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TimetableMenuPage(),
                    ),
                  );
                },
                child: const Text('時間割を入力する'),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeworkMenuPage(),
                    ),
                  );
                },
                child: const Text('宿題・テストを共有する'),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('設定画面は未実装です'),
                    ),
                  );
                },
                child: const Text('設定'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}