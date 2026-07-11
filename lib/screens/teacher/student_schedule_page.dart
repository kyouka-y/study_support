import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/schedule_service.dart';

class StudentSchedulePage extends StatefulWidget {
  final String studentUid;
  final String studentName;

  const StudentSchedulePage({
    super.key,
    required this.studentUid,
    required this.studentName,
  });

  @override
  State<StudentSchedulePage> createState() =>
      _StudentSchedulePageState();
}

class _StudentSchedulePageState extends State<StudentSchedulePage> {
  final ScheduleService _scheduleService = ScheduleService();

  final TextEditingController _titleController =
      TextEditingController();

  DateTime _selectedDate = DateTime.now();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isLoading = false;
  String? _message;

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(
        hour: 8,
        minute: 0,
      ),
    );

    if (time != null) {
      setState(() {
        _startTime = time;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(
        hour: 9,
        minute: 0,
      ),
    );

    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  Future<void> _saveSchedule() async {
    final teacher = FirebaseAuth.instance.currentUser;

    if (teacher == null) {
      setState(() {
        _message = 'ログインしていません';
      });
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      setState(() {
        _message = '予定名を入力してください';
      });
      return;
    }

    if (_startTime == null || _endTime == null) {
      setState(() {
        _message = '開始時間と終了時間を選択してください';
      });
      return;
    }

    final startMinutes =
        _startTime!.hour * 60 + _startTime!.minute;

    final endMinutes =
        _endTime!.hour * 60 + _endTime!.minute;

    if (endMinutes <= startMinutes) {
      setState(() {
        _message = '終了時間は開始時間より後にしてください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _scheduleService.createSchedule(
        createdByUid: teacher.uid,
        createdByRole: 'teacher',
        studentUid: widget.studentUid,
        title: _titleController.text,
        date: _selectedDate,
        startTime: TimeStamp(
          hour: _startTime!.hour,
          minute: _startTime!.minute,
        ),
        endTime: TimeStamp(
          hour: _endTime!.hour,
          minute: _endTime!.minute,
        ),
      );

      if (!mounted) return;

      setState(() {
        _message = '予定を登録しました';
        _startTime = null;
        _endTime = null;
      });

      _titleController.clear();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'エラー: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) {
      return '未選択';
    }

    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName}の予定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '予定名',
              hintText: '学校・部活・夕食など',
            ),
          ),

          const SizedBox(height: 24),

          OutlinedButton(
            onPressed: _selectDate,
            child: Text(
              '日付：'
              '${_selectedDate.year}/'
              '${_selectedDate.month}/'
              '${_selectedDate.day}',
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton(
            onPressed: _selectStartTime,
            child: Text(
              '開始：${_formatTime(_startTime)}',
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton(
            onPressed: _selectEndTime,
            child: Text(
              '終了：${_formatTime(_endTime)}',
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isLoading ? null : _saveSchedule,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('予定を登録'),
          ),

          const SizedBox(height: 16),

          if (_message != null)
            Text(
              _message!,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}