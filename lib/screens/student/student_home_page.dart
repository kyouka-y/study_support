import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import 'student_homework_page.dart';

class StudentHomePage extends StatelessWidget {
  final String userName;

  const StudentHomePage({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('生徒ホーム'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$userName さん',
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
                      builder: (context) =>
                          const StudentHomeworkPage(),
                    ),
                  );
                },
                child: const Text('宿題を確認する'),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('予定を確認する'),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('学習記録'),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await authService.signOut();

                  if (!context.mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const LoginPage(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('ログアウト'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}