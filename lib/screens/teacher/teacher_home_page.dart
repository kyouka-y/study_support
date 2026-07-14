import 'package:flutter/material.dart';

import '../../schedule_menu_page.dart';
import '../../timetable_menu_page.dart';
import '../../homework_menu_page.dart';
import '../../services/auth_service.dart';

import '../auth/login_page.dart';
import 'link_student_page.dart';
import 'student_list_page.dart';
import 'teacher_submission_page.dart';

class TeacherHomePage extends StatelessWidget {
  final String userName;

  const TeacherHomePage({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('先生ホーム'),
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
                          const ScheduleMenuPage(),
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
                      builder: (context) =>
                          const TimetableMenuPage(),
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
                      builder: (context) =>
                          const HomeworkMenuPage(),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const TeacherSubmissionPage(),
                    ),
                  );
                },
                child: const Text('受信ボックス'),
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
                      builder: (context) =>
                          const StudentListPage(),
                    ),
                  );
                },
                child: const Text('担当生徒一覧'),
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
                      builder: (context) =>
                          const LinkStudentPage(),
                    ),
                  );
                },
                child: const Text('生徒を登録する'),
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
