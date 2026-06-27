import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ClassTimetablePage extends StatefulWidget {
  const ClassTimetablePage({super.key});

  @override
  State<ClassTimetablePage> createState() => _ClassTimetablePageState();
}

class _ClassTimetablePageState extends State<ClassTimetablePage> {
  final List<String> days = ["月", "火", "水", "木", "金", "土"];
  final List<String> periods = ["1限", "2限", "3限", "4限", "5限"];

  // 時間割データ
  Map<String, Map<String, String>> timetable = {};

  @override
  void initState() {
    super.initState();

    // 初期値作成
    for (var period in periods) {
      timetable[period] = {};
      for (var day in days) {
        timetable[period]![day] = "";
      }
    }

    _loadTimetable();
  }

  /// ==========================
  /// 保存
  /// ==========================
  Future<void> _saveTimetable() async {
    final prefs = await SharedPreferences.getInstance();

    String jsonString = jsonEncode(timetable);

    await prefs.setString(
      'class_timetable',
      jsonString,
    );
  }

  /// ==========================
  /// 読み込み
  /// ==========================
  Future<void> _loadTimetable() async {
    final prefs = await SharedPreferences.getInstance();

    String? jsonString =
        prefs.getString('class_timetable');

    if (jsonString == null) {
      return;
    }

    Map<String, dynamic> decoded =
        jsonDecode(jsonString);

    setState(() {
      timetable = decoded.map(
        (period, dayMap) => MapEntry(
          period,
          Map<String, String>.from(dayMap),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('授業時間割'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // ===== ヘッダー =====
            Row(
              children: [
                const SizedBox(width: 60),
                ...days.map((d) {
                  return Container(
                    width: 80,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ],
            ),

            // ===== 時間割本体 =====
            ...periods.map((period) {
              return Row(
                children: [
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      period,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 各セル
                  ...days.map((day) {
                    return GestureDetector(
                      onTap: () {
                        _editCell(period, day);
                      },
                      child: Container(
                        width: 80,
                        height: 60,
                        margin: const EdgeInsets.all(2),
                        color: Colors.blue[50],
                        alignment: Alignment.center,
                        child: Text(
                          (timetable[period]?[day] ?? "")
                                  .isEmpty
                              ? "_"
                              : timetable[period]![day]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// ==========================
  /// セル編集
  /// ==========================
  void _editCell(String period, String day) {
    final controller = TextEditingController(
      text: timetable[period]![day],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$day $period"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "科目を入力",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("キャンセル"),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  timetable[period]![day] =
                      controller.text;
                });

                await _saveTimetable();

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("保存"),
            ),
          ],
        );
      },
    );
  }
}