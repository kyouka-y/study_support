import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeworkSelectionData {
  final String homeworkId;
  final String title;
  final String description;
  final int estimatedMinutes;

  const HomeworkSelectionData({
    required this.homeworkId,
    required this.title,
    required this.description,
    required this.estimatedMinutes,
  });
}

class StudentTimelinePage extends StatefulWidget {
  const StudentTimelinePage({super.key});

  @override
  State<StudentTimelinePage> createState() =>
      _StudentTimelinePageState();
}

class _StudentTimelinePageState extends State<StudentTimelinePage> {
  DateTime _selectedDate = DateTime.now();

  HomeworkSelectionData? _selectedHomework;
  String? _editingPlanId;
  int? _previewStartMinutes;

  static const int startHour = 6;
  static const int endHour = 24;
  static const double hourHeight = 80;
  static const double timeLabelWidth = 60;

  DateTime get _selectedDay {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
  }

  bool _isSameDay(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (date == null) return;

    setState(() {
      _selectedDate = date;
      _cancelSelection();
    });
  }

  void _cancelSelection() {
    _selectedHomework = null;
    _editingPlanId = null;
    _previewStartMinutes = null;
  }

  String _formatTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  int _snapTo15Minutes(int minutes) {
    return (minutes / 15).round() * 15;
  }

  int _calculateMinutesFromPosition(double y) {
    final minutesFromStart = (y / hourHeight) * 60;

    return _snapTo15Minutes(
      startHour * 60 + minutesFromStart.round(),
    );
  }

  bool _hasOverlap({
    required int startMinutes,
    required int endMinutes,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        schedules,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> plans,
  }) {
    for (final document in schedules) {
      final data = document.data();

      final int scheduleStart =
          (data['startMinutes'] as num).toInt();

      final int scheduleEnd =
          (data['endMinutes'] as num).toInt();

      if (startMinutes < scheduleEnd &&
          endMinutes > scheduleStart) {
        return true;
      }
    }

    for (final document in plans) {
      if (document.id == _editingPlanId) {
        continue;
      }

      final data = document.data();

      final int planStart =
          (data['startMinutes'] as num).toInt();

      final int duration =
          (data['durationMinutes'] as num).toInt();

      final int planEnd = planStart + duration;

      if (startMinutes < planEnd &&
          endMinutes > planStart) {
        return true;
      }
    }

    return false;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showCompletionDialog({
    required String homeworkId,
    required String studyPlanId,
    required String title,
    required int estimatedMinutes,
  }) async {
    final student = FirebaseAuth.instance.currentUser;

    if (student == null) {
      _showMessage('ログインしていません');
      return;
    }

    final minutesController = TextEditingController(
      text: estimatedMinutes.toString(),
    );

    final memoController = TextEditingController();

    int rating = 3;

    final shouldSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('$titleを完了'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '実際にかかった時間',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        suffixText: '分',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '自分の評価',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) {
                          final starNumber = index + 1;

                          return IconButton(
                            onPressed: () {
                              setDialogState(() {
                                rating = starNumber;
                              });
                            },
                            icon: Icon(
                              starNumber <= rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 36,
                            ),
                          );
                        },
                      ),
                    ),
                    Center(
                      child: Text('$rating / 5'),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'メモ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: memoController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: '難しかったところや気づいたこと',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('キャンセル'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final actualMinutes = int.tryParse(
                      minutesController.text.trim(),
                    );

                    if (actualMinutes == null ||
                        actualMinutes <= 0) {
                      ScaffoldMessenger.of(dialogContext)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'かかった時間を正しく入力してください',
                          ),
                        ),
                      );

                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('完了'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) {
      minutesController.dispose();
      memoController.dispose();
      return;
    }

    final actualMinutes = int.parse(
      minutesController.text.trim(),
    );

    final memo = memoController.text.trim();

    minutesController.dispose();
    memoController.dispose();

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final homeworkReference = firestore
          .collection('homeworks')
          .doc(homeworkId);

      final recordReference = firestore
          .collection('study_records')
          .doc(studyPlanId);

      batch.update(
        homeworkReference,
        {
          'completed': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.set(
        recordReference,
        {
          'studentUid': student.uid,
          'homeworkId': homeworkId,
          'studyPlanId': studyPlanId,
          'title': title,
          'date': Timestamp.fromDate(_selectedDay),
          'estimatedMinutes': estimatedMinutes,
          'actualMinutes': actualMinutes,
          'rating': rating,
          'memo': memo,
          'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      _showMessage('$titleを完了しました！');
    } catch (e) {
      _showMessage('完了報告エラー: $e');
    }
  }

  Future<void> _cancelHomeworkCompletion({
    required String homeworkId,
    required String studyPlanId,
    required String title,
  }) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('完了を取り消す'),
          content: Text(
            '「$title」の完了を取り消しますか？\n\n'
            '入力した所要時間・評価・メモも削除されます。',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                '完了を取り消す',
                style: TextStyle(
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final homeworkReference = firestore
          .collection('homeworks')
          .doc(homeworkId);

      final recordReference = firestore
          .collection('study_records')
          .doc(studyPlanId);

      batch.update(
        homeworkReference,
        {
          'completed': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.delete(recordReference);

      await batch.commit();

      _showMessage('$titleの完了を取り消しました');
    } catch (e) {
      _showMessage('完了取消エラー: $e');
    }
  }

  Future<void> _placeHomework({
    required String studentUid,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        schedules,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        currentDayPlans,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        allPlans,
  }) async {
    final homework = _selectedHomework;
    final startMinutes = _previewStartMinutes;

    if (homework == null || startMinutes == null) {
      return;
    }

    final endMinutes =
        startMinutes + homework.estimatedMinutes;

    if (startMinutes < startHour * 60 ||
        endMinutes > endHour * 60) {
      _showMessage('この時間には配置できません');
      return;
    }

    final hasOverlap = _hasOverlap(
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      schedules: schedules,
      plans: currentDayPlans,
    );

    if (hasOverlap) {
      _showMessage('予定または他の課題と重なっています');
      return;
    }

    try {
      if (_editingPlanId != null) {
        await FirebaseFirestore.instance
            .collection('study_plans')
            .doc(_editingPlanId)
            .update({
          'startMinutes': startMinutes,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _showMessage(
          '${homework.title}を'
          '${_formatTime(startMinutes)}に変更しました',
        );
      } else {
        final alreadyPlaced = allPlans.any((document) {
          return document.data()['homeworkId'] ==
              homework.homeworkId;
        });

        if (alreadyPlaced) {
          _showMessage(
            'この課題は別の日を含め、すでに配置されています',
          );
          return;
        }

        await FirebaseFirestore.instance
            .collection('study_plans')
            .add({
          'studentUid': studentUid,
          'homeworkId': homework.homeworkId,
          'title': homework.title,
          'date': Timestamp.fromDate(_selectedDay),
          'startMinutes': startMinutes,
          'durationMinutes': homework.estimatedMinutes,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _showMessage(
          '${homework.title}を'
          '${_formatTime(startMinutes)}に配置しました',
        );
      }

      if (mounted) {
        setState(() {
          _cancelSelection();
        });
      }
    } catch (e) {
      _showMessage('保存エラー: $e');
    }
  }

  Future<void> _showPlanMenu(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    Map<String, bool> completedMap,
  ) async {
    final data = document.data();

    final String title = data['title'] ?? '';
    final String homeworkId = data['homeworkId'] ?? '';

    final int startMinutes =
        (data['startMinutes'] as num).toInt();

    final int durationMinutes =
        (data['durationMinutes'] as num).toInt();

    final bool completed =
        completedMap[homeworkId] ?? false;

    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatTime(startMinutes)}〜'
                  '${_formatTime(
                    startMinutes + durationMinutes,
                  )}',
                ),
                if (completed) ...[
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '完了済み',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('時間を変更'),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    setState(() {
                      _selectedHomework =
                          HomeworkSelectionData(
                        homeworkId: homeworkId,
                        title: title,
                        description: '',
                        estimatedMinutes: durationMinutes,
                      );

                      _editingPlanId = document.id;
                      _previewStartMinutes = startMinutes;
                    });
                  },
                ),
                ListTile(
                  leading: Icon(
                    completed
                        ? Icons.undo
                        : Icons.check_circle_outline,
                    color: completed
                        ? Colors.orange
                        : Colors.green,
                  ),
                  title: Text(
                    completed
                        ? '完了を取り消す'
                        : '完了を報告',
                    style: TextStyle(
                      color: completed
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);

                    if (completed) {
                      await _cancelHomeworkCompletion(
                        homeworkId: homeworkId,
                        studyPlanId: document.id,
                        title: title,
                      );
                    } else {
                      await _showCompletionDialog(
                        homeworkId: homeworkId,
                        studyPlanId: document.id,
                        title: title,
                        estimatedMinutes: durationMinutes,
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: const Text(
                    '削除',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDeletePlan(document);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeletePlan(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data();

    final String title = data['title'] ?? '';
    final String homeworkId = data['homeworkId'] ?? '';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('課題を削除'),
          content: Text(
            '「$title」を1日の計画から削除しますか？\n'
            '課題そのものは削除されません。',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                '削除',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      batch.delete(
        firestore
            .collection('study_plans')
            .doc(document.id),
      );

      batch.delete(
        firestore
            .collection('study_records')
            .doc(document.id),
      );

      if (homeworkId.isNotEmpty) {
        batch.update(
          firestore
              .collection('homeworks')
              .doc(homeworkId),
          {
            'completed': false,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      _showMessage('$titleを計画から削除しました');

      if (mounted) {
        setState(() {
          _cancelSelection();
        });
      }
    } catch (e) {
      _showMessage('削除エラー: $e');
    }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('1日の計画を立てる'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_selectedDate.year}年'
                    '${_selectedDate.month}月'
                    '${_selectedDate.day}日',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_month),
                ),
              ],
            ),
          ),
          if (_selectedHomework != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              color: Colors.amber.shade50,
              child: Row(
                children: [
                  Icon(
                    _editingPlanId == null
                        ? Icons.push_pin
                        : Icons.schedule,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _editingPlanId == null
                          ? '${_selectedHomework!.title} '
                              '(${_selectedHomework!.estimatedMinutes}分) '
                              'を配置する時間を選んでください'
                          : '${_selectedHomework!.title}の'
                              '新しい時間を選んでください',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _cancelSelection();
                      });
                    },
                    child: const Text('キャンセル'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('daily_schedules')
                  .where(
                    'studentUid',
                    isEqualTo: student.uid,
                  )
                  .snapshots(),
              builder: (context, scheduleSnapshot) {
                if (scheduleSnapshot.hasError) {
                  return Center(
                    child: Text(
                      '予定取得エラー: '
                      '${scheduleSnapshot.error}',
                    ),
                  );
                }

                if (!scheduleSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final schedules =
                    scheduleSnapshot.data!.docs.where((document) {
                  final timestamp =
                      document.data()['date'] as Timestamp?;

                  if (timestamp == null) return false;

                  return _isSameDay(timestamp.toDate());
                }).toList();

                return StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('study_plans')
                      .where(
                        'studentUid',
                        isEqualTo: student.uid,
                      )
                      .snapshots(),
                  builder: (context, planSnapshot) {
                    if (planSnapshot.hasError) {
                      return Center(
                        child: Text(
                          '計画取得エラー: '
                          '${planSnapshot.error}',
                        ),
                      );
                    }

                    if (!planSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final allPlans = planSnapshot.data!.docs;

                    final currentDayPlans =
                        allPlans.where((document) {
                      final timestamp =
                          document.data()['date']
                              as Timestamp?;

                      if (timestamp == null) return false;

                      return _isSameDay(timestamp.toDate());
                    }).toList();

                    return StreamBuilder<
                        QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('homeworks')
                          .where(
                            'studentUid',
                            isEqualTo: student.uid,
                          )
                          .snapshots(),
                      builder: (context, homeworkSnapshot) {
                        if (homeworkSnapshot.hasError) {
                          return Center(
                            child: Text(
                              '課題取得エラー: '
                              '${homeworkSnapshot.error}',
                            ),
                          );
                        }

                        if (!homeworkSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final homeworks =
                            homeworkSnapshot.data!.docs;

                        final Map<String, bool> completedMap = {
                          for (final homework in homeworks)
                            homework.id:
                                homework.data()['completed'] ==
                                    true,
                        };

                        return Column(
                          children: [
                            Expanded(
                              child: _buildTimeline(
                                studentUid: student.uid,
                                schedules: schedules,
                                currentDayPlans: currentDayPlans,
                                allPlans: allPlans,
                                completedMap: completedMap,
                              ),
                            ),
                            _buildHomeworkArea(
                              homeworks,
                              allPlans,
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline({
    required String studentUid,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        schedules,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        currentDayPlans,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        allPlans,
    required Map<String, bool> completedMap,
  }) {
    final timelineHeight =
        (endHour - startHour) * hourHeight;

    return SingleChildScrollView(
      child: MouseRegion(
        onHover: (event) {
          if (_selectedHomework == null) return;

          final startMinutes =
              _calculateMinutesFromPosition(
            event.localPosition.dy,
          );

          if (_previewStartMinutes != startMinutes) {
            setState(() {
              _previewStartMinutes = startMinutes;
            });
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) async {
            if (_selectedHomework == null) return;

            final startMinutes =
                _calculateMinutesFromPosition(
              details.localPosition.dy,
            );

            setState(() {
              _previewStartMinutes = startMinutes;
            });

            await _placeHomework(
              studentUid: studentUid,
              schedules: schedules,
              currentDayPlans: currentDayPlans,
              allPlans: allPlans,
            );
          },
          child: SizedBox(
            height: timelineHeight,
            child: Stack(
              children: [
                ...List.generate(
                  endHour - startHour,
                  (index) {
                    final hour = startHour + index;

                    return Positioned(
                      top: index * hourHeight,
                      left: 0,
                      right: 0,
                      height: hourHeight,
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: timeLabelWidth,
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.black12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ...schedules.map(_buildScheduleBlock),
                ...currentDayPlans.map(
                  (document) => _buildStudyPlanBlock(
                    document,
                    completedMap,
                  ),
                ),
                if (_selectedHomework != null &&
                    _previewStartMinutes != null)
                  _buildPreviewBlock(
                    schedules: schedules,
                    plans: currentDayPlans,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewBlock({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        schedules,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> plans,
  }) {
    final homework = _selectedHomework!;
    final startMinutes = _previewStartMinutes!;

    final endMinutes =
        startMinutes + homework.estimatedMinutes;

    final outOfRange =
        startMinutes < startHour * 60 ||
            endMinutes > endHour * 60;

    final hasOverlap = outOfRange ||
        _hasOverlap(
          startMinutes: startMinutes,
          endMinutes: endMinutes,
          schedules: schedules,
          plans: plans,
        );

    final top =
        ((startMinutes - startHour * 60) / 60) *
            hourHeight;

    final height =
        (homework.estimatedMinutes / 60) * hourHeight;

    return Positioned(
      top: top,
      left: 70,
      right: 16,
      height: height,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.65,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasOverlap
                  ? Colors.red.shade200
                  : Colors.green.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    hasOverlap ? Colors.red : Colors.green,
                width: 2,
              ),
            ),
            child: Text(
              '${homework.title}\n'
              '${_formatTime(startMinutes)}〜'
              '${_formatTime(endMinutes)}',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleBlock(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final int startMinutes =
        (data['startMinutes'] as num).toInt();

    final int endMinutes =
        (data['endMinutes'] as num).toInt();

    final String title = data['title'] ?? '';

    final top =
        ((startMinutes - startHour * 60) / 60) *
            hourHeight;

    final height =
        ((endMinutes - startMinutes) / 60) *
            hourHeight;

    return Positioned(
      top: top,
      left: 70,
      right: 16,
      height: height,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.shade300,
            ),
          ),
          child: Text(
            '$title\n'
            '${_formatTime(startMinutes)}〜'
            '${_formatTime(endMinutes)}',
          ),
        ),
      ),
    );
  }

  Widget _buildStudyPlanBlock(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    Map<String, bool> completedMap,
  ) {
    final data = document.data();

    final int startMinutes =
        (data['startMinutes'] as num).toInt();

    final int durationMinutes =
        (data['durationMinutes'] as num).toInt();

    final String title = data['title'] ?? '';
    final String homeworkId = data['homeworkId'] ?? '';

    final bool completed =
        completedMap[homeworkId] ?? false;

    final endMinutes =
        startMinutes + durationMinutes;

    final top =
        ((startMinutes - startHour * 60) / 60) *
            hourHeight;

    final height =
        (durationMinutes / 60) * hourHeight;

    final isEditing = document.id == _editingPlanId;

    return Positioned(
      top: top,
      left: 70,
      right: 16,
      height: height,
      child: IgnorePointer(
        ignoring: _selectedHomework != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _showPlanMenu(
              document,
              completedMap,
            );
          },
          child: Opacity(
            opacity: isEditing ? 0.3 : 1,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: completed
                    ? Colors.green.shade200
                    : Colors.amber.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: completed
                      ? Colors.green
                      : Colors.orange,
                  width: completed ? 2 : 1,
                ),
              ),
              child: Text(
                completed
                    ? '✅ $title\n'
                        '${_formatTime(startMinutes)}〜'
                        '${_formatTime(endMinutes)}'
                    : '📌 $title\n'
                        '${_formatTime(startMinutes)}〜'
                        '${_formatTime(endMinutes)}',
                style: TextStyle(
                  fontWeight: completed
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeworkArea(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> homeworks,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allPlans,
  ) {
    final placedHomeworkIds = allPlans
        .map(
          (document) => document.data()['homeworkId'],
        )
        .toSet();

    final availableHomeworks = homeworks.where((document) {
      final data = document.data();

      return data['completed'] != true &&
          !placedHomeworkIds.contains(document.id);
    }).toList();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '課題ブロック',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: availableHomeworks.isEmpty
                ? const Text(
                    '配置できる課題はありません',
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableHomeworks.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final document =
                          availableHomeworks[index];

                      final data = document.data();

                      final String title =
                          data['title'] ?? '';

                      final String description =
                          data['description'] ?? '';

                      final int estimatedMinutes =
                          (data['estimatedMinutes'] as num?)
                                  ?.toInt() ??
                              30;

                      final homework =
                          HomeworkSelectionData(
                        homeworkId: document.id,
                        title: title,
                        description: description,
                        estimatedMinutes: estimatedMinutes,
                      );

                      final isSelected =
                          _selectedHomework?.homeworkId ==
                                  homework.homeworkId &&
                              _editingPlanId == null;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _cancelSelection();
                            } else {
                              _selectedHomework = homework;
                              _editingPlanId = null;
                              _previewStartMinutes = null;
                            }
                          });
                        },
                        child: AnimatedScale(
                          scale: isSelected ? 1.05 : 1,
                          duration: const Duration(
                            milliseconds: 150,
                          ),
                          child: Container(
                            width: 150,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.amber.shade300
                                  : Colors.amber.shade100,
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.deepOrange
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Text(
                                  '⏱ $estimatedMinutes分',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}