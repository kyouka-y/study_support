import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../auth/login_page.dart';

import 'student_homework_page.dart';
import 'daily_schedule_page.dart';
import 'student_schedule_input_page.dart';
import 'student_timeline_page.dart';
import 'student_study_record_page.dart';
import 'student_submission_page.dart';

class StudentHomePage extends StatefulWidget {
  final String userName;

  const StudentHomePage({
    super.key,
    required this.userName,
  });

  @override
  State<StudentHomePage> createState() =>
      _StudentHomePageState();
}

class _StudentHomePageState
    extends State<StudentHomePage> {
  final AuthService _authService = AuthService();

  Future<void> _logout() async {
    await _authService.signOut();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生徒ホーム'),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'ログアウト',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${widget.userName}さん',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '今日も自分のペースで進めよう',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            _buildMenuButton(
              icon: Icons.view_timeline_outlined,
              title: '学習スケジュール',
              subtitle: '課題を時間に配置して予定を立てる',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const StudentTimelinePage(),
                  ),
                );
              },
            ),

            _buildMenuButton(
              icon: Icons.outbox_outlined,
              title: '提出ボックス',
              subtitle: '先生に質問や資料を送る',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const StudentSubmissionPage(),
                  ),
                );
              },
            ),

            _buildMenuButton(
              icon: Icons.bar_chart,
              title: '学習記録',
              subtitle: '勉強時間やこれまでの記録を見る',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const StudentStudyRecordPage(),
                  ),
                );
              },
            ),

            _buildMenuButton(
              icon: Icons.assignment_outlined,
              title: '宿題・課題',
              subtitle: '先生から登録された課題を確認する',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const StudentHomeworkPage(),
                  ),
                );
              },
            ),

            _buildMenuButton(
              icon: Icons.calendar_today_outlined,
              title: '予定を確認',
              subtitle: '登録されている1日の予定を見る',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DailySchedulePage(),
                  ),
                );
              },
            ),

            _buildMenuButton(
              icon: Icons.edit_calendar_outlined,
              title: '予定を入力',
              subtitle: '学校や部活などの予定を登録する',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const StudentScheduleInputPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}