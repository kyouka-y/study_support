import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/schedule_service.dart';

class DailySchedulePage extends StatelessWidget {
  const DailySchedulePage({super.key});

  String formatMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final student = FirebaseAuth.instance.currentUser;

    if (student == null) {
      return const Scaffold(
        body: Center(
          child: Text('ログインしていません'),
        ),
      );
    }

    final scheduleService = ScheduleService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('1日の予定'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: scheduleService.getStudentSchedules(
          student.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('エラー: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final schedules = snapshot.data!.docs.toList();

          schedules.sort((a, b) {
            final aMinutes =
                a.data()['startMinutes'] as int;

            final bMinutes =
                b.data()['startMinutes'] as int;

            return aMinutes.compareTo(bMinutes);
          });

          if (schedules.isEmpty) {
            return const Center(
              child: Text('予定はありません'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final data = schedules[index].data();

              final title = data['title'] ?? '';

              final startMinutes =
                  data['startMinutes'] as int;

              final endMinutes =
                  data['endMinutes'] as int;

              final date = data['date'] as Timestamp;

              final scheduleDate = date.toDate();

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(title),
                  subtitle: Text(
                    '${scheduleDate.year}/'
                    '${scheduleDate.month}/'
                    '${scheduleDate.day}\n'
                    '${formatMinutes(startMinutes)}'
                    ' ～ '
                    '${formatMinutes(endMinutes)}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}