import 'package:flutter/material.dart';

class HomeworkMenuPage extends StatelessWidget {
  const HomeworkMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('宿題・テスト共有'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // 宿題
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeworkPage(),
                    ),
                  );
                },
                child: const Text('宿題'),
              ),
            ),

            const SizedBox(height: 16),

            // テスト
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TestPage(),
                    ),
                  );
                },
                child: const Text('テスト'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//仮ページ
class HomeworkPage extends StatelessWidget {
  const HomeworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('宿題'),
      ),
      body: const Center(
        child: Text('宿題画面'),
      ),
    );
  }
}

//仮ページ2
class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('テスト'),
      ),
      body: const Center(
        child: Text('テスト画面'),
      ),
    );
  }
}