import 'package:flutter/material.dart';

import '../../../controllers/apply_job_controller.dart';
import '../../../utils/apply_job_utils.dart';
import '../apply_job_colors.dart';
import '../apply_job_upload_card.dart';

class ApplyDocumentsStep extends StatelessWidget {
  final ApplyJobController controller;

  const ApplyDocumentsStep({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.dokumenWajib.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Tidak ada dokumen persyaratan khusus.',
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
          'Silakan lengkapi dokumen persyaratan di bawah ini untuk memulai perjalanan kariermu.',
          style: TextStyle(
            fontSize: 14,
            color: applyTextDark,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: applyInfoBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: applyGold.withValues(alpha: 0.4),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: applyGold,
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dokumen diunggah langsung saat Anda memilih file. Tunggu hingga muncul tanda ✓ sebelum lanjut.',
                  style: TextStyle(
                    fontSize: 11,
                    color: applyInfoText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...controller.dokumenWajib.map((document) {
          final id = documentIdOf(document);
          final required = isDocumentRequired(document);
          final isUploaded =
              controller.uploadedDokumenIds.contains(id);
          final isPending =
              controller.uploadedFiles.containsKey(id) && !isUploaded;
          final label = required ? ' (Wajib)' : ' (Opsional)';
          final subtitle = isUploaded
              ? controller.uploadedFileNames[id] ?? 'Tersimpan'
              : (isPending
                  ? 'Sedang diunggah...'
                  : 'Ketuk untuk memilih berkas');

          return ApplyJobUploadCard(
            icon: Icons.description_rounded,
            title: '${documentNameOf(document)}$label',
            subtitle: subtitle,
            onTap: () => controller.pickFile(id),
            isUploaded: isUploaded,
            isPending: isPending,
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }
}
