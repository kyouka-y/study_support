import 'package:flutter/material.dart';
import 'schedule_menu_page.dart';
import 'timetable_menu_page.dart';
import 'homework_menu_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            // ① 予定を確認する
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

            // ② 時間割を入力する（仮）
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

            // ③ 宿題・テストを共有（仮）
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

            // ④ 設定（仮）
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('設定画面は未実装です')),
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