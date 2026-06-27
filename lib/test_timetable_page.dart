import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TestTimetablePage extends StatefulWidget {
  const TestTimetablePage({super.key});

  @override
  State<TestTimetablePage> createState() => _TestTimetablePageState();
}

class _TestTimetablePageState extends State<TestTimetablePage> {

  final List<String> days = [
    "1日目",
    "2日目",
    "3日目",
    "4日目",
    "5日目"
  ];

  final List<String> periods = [
    "1限",
    "2限",
    "3限",
    "4限",
    "5限"
  ];

  Map<String, Map<String, String>> timetable = {};

  @override
  void initState() {
    super.initState();

    for (var period in periods) {
      timetable[period] = {};

      for (var day in days) {
        timetable[period]![day] = "";
      }
    }

    _loadTimetable();
  }

  Future<void> _saveTimetable() async {
    final prefs = await SharedPreferences.getInstance();

    String jsonString = jsonEncode(timetable);

    await prefs.setString(
      'test_timetable',
      jsonString,
    );
  }

  Future<void> _loadTimetable() async {
    final prefs = await SharedPreferences.getInstance();

    String? jsonString =
        prefs.getString('test_timetable');

    if (jsonString == null) return;

    Map<String, dynamic> decoded =
        jsonDecode(jsonString);

    setState(() {
      timetable = decoded.map(
        (key, value) => MapEntry(
          key,
          Map<String, String>.from(value),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("テスト時間割"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [

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

                  ...days.map((day) {
                    return GestureDetector(
                      onTap: () {
                        _editCell(period, day);
                      },
                      child: Container(
                        width: 80,
                        height: 60,
                        margin: const EdgeInsets.all(2),
                        color: Colors.orange[50],
                        alignment: Alignment.center,
                        child: Text(
                          (timetable[period]?[day] ?? "")
                                  .isEmpty
                              ? "_"
                              : timetable[period]![day]!,
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

  void _editCell(
    String period,
    String day,
  ) {
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
              hintText: "教科名を入力",
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

                Navigator.pop(context);
              },
              child: const Text("保存"),
            ),
          ],
        );
      },
    );
  }
}