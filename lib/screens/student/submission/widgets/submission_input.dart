import 'package:flutter/material.dart';

class SubmissionInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSubmit;

  const SubmissionInput({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .scaffoldBackgroundColor,
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              offset: Offset(0, -2),
              color: Color(0x14000000),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '先生に送るメッセージ',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed:
                  isSending ? null : onSubmit,
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}