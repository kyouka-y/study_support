import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentStudyRecordPage extends StatefulWidget {
  const StudentStudyRecordPage({super.key});

  @override
  State<StudentStudyRecordPage> createState() =>
      _StudentStudyRecordPageState();
}

class _StudentStudyRecordPageState
    extends State<StudentStudyRecordPage> {
  final Set<String> _expandedRecordIds = {};

  DateTime _selectedWeek = DateTime.now();

  DateTime _startOfWeek(DateTime date) {
    final day = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return day.subtract(
      Duration(days: day.weekday - 1),
    );
  }

  DateTime _endOfWeek(DateTime date) {
    return _startOfWeek(date).add(
      const Duration(days: 6),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  bool _isInSelectedWeek(DateTime date) {
    final start = _startOfWeek(_selectedWeek);
    final end = start.add(const Duration(days: 7));

    return !date.isBefore(start) && date.isBefore(end);
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return '日付不明';
    }

    final date = timestamp.toDate();

    return '${date.month}/${date.day}';
  }

  String _formatStudyTime(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours == 0) {
      return '$remainingMinutes分';
    }

    if (remainingMinutes == 0) {
      return '$hours時間';
    }

    return '$hours時間$remainingMinutes分';
  }

  void _previousWeek() {
    setState(() {
      _selectedWeek = _selectedWeek.subtract(
        const Duration(days: 7),
      );
    });
  }

  void _nextWeek() {
    setState(() {
      _selectedWeek = _selectedWeek.add(
        const Duration(days: 7),
      );
    });
  }

  void _goToCurrentWeek() {
    setState(() {
      _selectedWeek = DateTime.now();
    });
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) {
          return Icon(
            index < rating
                ? Icons.star
                : Icons.star_border,
            color: Colors.amber,
            size: 22,
          );
        },
      ),
    );
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
        title: const Text('学習記録'),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('study_records')
            .where(
              'studentUid',
              isEqualTo: student.uid,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '学習記録取得エラー\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final allRecords = snapshot.data!.docs;

          final weekRecords = allRecords.where((document) {
            final timestamp =
                document.data()['date'] as Timestamp?;

            if (timestamp == null) {
              return false;
            }

            return _isInSelectedWeek(
              timestamp.toDate(),
            );
          }).toList();

          weekRecords.sort((a, b) {
            final aDate =
                a.data()['date'] as Timestamp?;

            final bDate =
                b.data()['date'] as Timestamp?;

            if (aDate == null || bDate == null) {
              return 0;
            }

            return bDate.compareTo(aDate);
          });

          final dailyMinutes = _calculateDailyMinutes(
            weekRecords,
          );

          final totalMinutes = dailyMinutes.values.fold<int>(
            0,
            (total, minutes) => total + minutes,
          );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildStudySummary(
                  dailyMinutes: dailyMinutes,
                  totalMinutes: totalMinutes,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    24,
                    16,
                    8,
                  ),
                  child: Text(
                    '学習記録',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              if (weekRecords.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 48,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 56,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'この週の学習記録はありません',
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    24,
                  ),
                  sliver: SliverList.separated(
                    itemCount: weekRecords.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _buildRecordCard(
                        weekRecords[index],
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Map<DateTime, int> _calculateDailyMinutes(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> records,
  ) {
    final start = _startOfWeek(_selectedWeek);

    final Map<DateTime, int> result = {};

    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));

      result[
        DateTime(
          date.year,
          date.month,
          date.day,
        )
      ] = 0;
    }

    for (final document in records) {
      final data = document.data();

      final timestamp = data['date'] as Timestamp?;

      final actualMinutes =
          (data['actualMinutes'] as num?)?.toInt() ?? 0;

      if (timestamp == null) {
        continue;
      }

      final date = timestamp.toDate();

      final day = DateTime(
        date.year,
        date.month,
        date.day,
      );

      result[day] =
          (result[day] ?? 0) + actualMinutes;
    }

    return result;
  }

  Widget _buildStudySummary({
    required Map<DateTime, int> dailyMinutes,
    required int totalMinutes,
  }) {
    final weekStart = _startOfWeek(_selectedWeek);
    final weekEnd = _endOfWeek(_selectedWeek);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24,
      ),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _previousWeek,
                icon: const Icon(
                  Icons.chevron_left,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _goToCurrentWeek,
                  child: Column(
                    children: [
                      Text(
                        '${weekStart.year}年'
                        '${weekStart.month}月'
                        '${weekStart.day}日'
                        ' 〜 '
                        '${weekEnd.month}月'
                        '${weekEnd.day}日',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'タップで今週に戻る',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextWeek,
                icon: const Icon(
                  Icons.chevron_right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'この週の勉強時間',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatStudyTime(totalMinutes),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 28),
          _buildBarChart(dailyMinutes),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    Map<DateTime, int> dailyMinutes,
  ) {
    const dayLabels = [
      '月',
      '火',
      '水',
      '木',
      '金',
      '土',
      '日',
    ];

    final entries = dailyMinutes.entries.toList();

    int maxMinutes = 0;

    for (final entry in entries) {
      if (entry.value > maxMinutes) {
        maxMinutes = entry.value;
      }
    }

    if (maxMinutes < 60) {
      maxMinutes = 60;
    }

    const double chartHeight = 180;

    // 数値24 + 余白4 + グラフ180 + 余白8 + 曜日30
    // = 246px
    //
    // 少し余裕を持たせて260px確保
    const double chartAreaHeight = 260;

    return SizedBox(
      height: chartAreaHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          7,
          (index) {
            final entry = entries[index];
            final minutes = entry.value;

            final double barHeight = minutes == 0
                ? 0
                : (minutes / maxMinutes) * chartHeight;

            final isToday = _isSameDay(
              entry.key,
              DateTime.now(),
            );

            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 24,
                    child: minutes > 0
                        ? Center(
                            child: Text(
                              '$minutes',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: chartHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(
                          milliseconds: 300,
                        ),
                        width: 28,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: isToday
                              ? Colors.orange
                              : Colors.blue.shade400,
                          borderRadius:
                              const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 30,
                    child: Center(
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: isToday
                            ? BoxDecoration(
                                color: Colors.orange.shade100,
                                shape: BoxShape.circle,
                              )
                            : null,
                        child: Text(
                          dayLabels[index],
                          style: TextStyle(
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
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
      ),
    );
  }

  Widget _buildRecordCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final String title = data['title'] ?? '課題';

    final int estimatedMinutes =
        (data['estimatedMinutes'] as num?)?.toInt() ?? 0;

    final int actualMinutes =
        (data['actualMinutes'] as num?)?.toInt() ?? 0;

    final int rating =
        (data['rating'] as num?)?.toInt() ?? 0;

    final String memo = data['memo'] ?? '';

    final Timestamp? date =
        data['date'] as Timestamp?;

    final int difference =
        actualMinutes - estimatedMinutes;

    final bool isExpanded =
        _expandedRecordIds.contains(document.id);

    return Card(
      elevation: isExpanded ? 3 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedRecordIds.remove(document.id);
            } else {
              _expandedRecordIds.add(document.id);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const Divider(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _TimeInfo(
                        label: '予定',
                        minutes: estimatedMinutes,
                        icon: Icons.schedule,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.grey,
                    ),
                    Expanded(
                      child: _TimeInfo(
                        label: '実際',
                        minutes: actualMinutes,
                        icon: Icons.timer,
                      ),
                    ),
                  ],
                ),
                if (difference != 0) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: difference > 0
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        difference > 0
                            ? '予定より$difference分多くかかりました'
                            : '予定より${difference.abs()}分早く終わりました',
                        style: TextStyle(
                          color: difference > 0
                              ? Colors.orange.shade800
                              : Colors.green.shade800,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  '自己評価',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _buildStars(rating),
                if (memo.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'メモ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Text(memo),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeInfo extends StatelessWidget {
  final String label;
  final int minutes;
  final IconData icon;

  const _TimeInfo({
    required this.label,
    required this.minutes,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.blueGrey,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$minutes分',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}