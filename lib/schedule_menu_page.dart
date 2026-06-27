import 'package:flutter/material.dart';
import 'calendar_page.dart';

class ScheduleMenuPage extends StatelessWidget {
  const ScheduleMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('予定メニュー'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ① 今日の予定（仮）
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TodaySchedulePage(),
                    ),
                  );
                },
                child: const Text('今日の予定'),
              ),
            ),

            const SizedBox(height: 16),

            // ② カレンダー
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarPage(),
                    ),
                  );
                },
                child: const Text('カレンダー'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//仮ページ
class TodaySchedulePage extends StatelessWidget {
  const TodaySchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日の予定'),
      ),
      body: const Center(
        child: Text('ここに今日の予定を表示'),
      ),
    );
  }
}

class TestTimetablePage extends StatelessWidget {
  const TestTimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('テスト時間割'),
      ),
      body: const Center(
        child: Text('ここにテスト時間割を入力・表示'),
      ),
    );
  }
}