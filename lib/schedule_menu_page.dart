import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'today_schedule_page.dart';

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

            // 今日の予定
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const TodaySchedulePage(),
                    ),
                  );
                },
                child: const Text('今日の予定'),
              ),
            ),

            const SizedBox(height: 16),

            // カレンダー
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CalendarPage(),
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