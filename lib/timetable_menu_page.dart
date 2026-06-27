import 'package:flutter/material.dart';
import 'class_timetable_page.dart';

class TimetableMenuPage extends StatelessWidget {
  const TimetableMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('時間割メニュー'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ① 授業時間割
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClassTimetablePage(),
                    ),
                  );
                },
                child: const Text('授業時間割'),
              ),
            ),

            const SizedBox(height: 16),

            // ② テスト時間割
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TestTimetablePage(),
                    ),
                  );
                },
                child: const Text('テスト時間割'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//仮ページ
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

