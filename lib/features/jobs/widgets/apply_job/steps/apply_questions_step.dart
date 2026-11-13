import 'package:flutter/material.dart';

import '../../../controllers/apply_job_controller.dart';
import '../../../utils/apply_job_utils.dart';
import '../apply_job_colors.dart';
import '../apply_job_form_fields.dart';

class ApplyQuestionsStep extends StatelessWidget {
  final ApplyJobController controller;

  const ApplyQuestionsStep({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.pertanyaanSeleksi.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Tidak ada pertanyaan seleksi khusus.\nSilakan klik Lanjut.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Silakan jawab pertanyaan pada lowongan ini untuk membantu perusahaan mengenal potensi Anda lebih dalam.',
          style: TextStyle(
            fontSize: 14,
            color: applyTextDark,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 25),
        ...controller.pertanyaanSeleksi.asMap().entries.map((entry) {
          final number = entry.key + 1;
          final question = entry.value;
          final id = questionIdOf(question);
          final text = questionTextOf(question, number);
          final answerController =
              controller.pertanyaanControllers[id];

          return ApplyInputField(
            label: '$number. $text',
            hint: 'Tulis jawaban Anda di sini...',
            isTextArea: true,
            controller: answerController,
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }
}
