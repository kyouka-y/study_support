import 'package:flutter/material.dart';

class TodaySchedulePage extends StatelessWidget {
  const TodaySchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日の予定'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              '${today.year}/${today.month}/${today.day}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: 17, // 6:00～22:00
                itemBuilder: (context, index) {
                  final hour = index + 6;

                  return SizedBox(
                    height: 60,
                    child: Row(
                      children: [

                        SizedBox(
                          width: 70,
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}