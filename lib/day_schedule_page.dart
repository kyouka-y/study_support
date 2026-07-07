import 'package:flutter/material.dart';

class DaySchedulePage extends StatelessWidget {
  final DateTime selectedDay;

  const DaySchedulePage({
    super.key,
    required this.selectedDay,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('1日の予定'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              '${selectedDay.year}/${selectedDay.month}/${selectedDay.day}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: 17,
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