import 'package:flutter/material.dart';

import '../../../controllers/apply_job_controller.dart';
import '../../../utils/apply_job_utils.dart';
import '../apply_job_avatar.dart';
import '../apply_job_colors.dart';

class ApplyReviewStep extends StatelessWidget {
  final ApplyJobController controller;

  const ApplyReviewStep({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: applyInfoBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: applyGold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: applyGold,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pastikan data sudah benar sebelum mengirim lamaran untuk lowongan ${controller.jobTitle}.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: applyInfoText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('DOKUMEN TERLAMPIR'),
        if (controller.dokumenWajib.isEmpty)
          const Text(
            'Tidak ada dokumen yang dilampirkan.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          )
        else
          ...controller.dokumenWajib.map((document) {
            final name = documentNameOf(document);
            final isUploaded = controller.uploadedDokumenIds.contains(
              documentIdOf(document),
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_rounded,
                    color: isUploaded ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    isUploaded
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isUploaded ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                ],
              ),
            );
          }),
        if (controller.pertanyaanSeleksi.isNotEmpty) ...[
          const SizedBox(height: 15),
          _sectionTitle('JAWABAN PERTANYAAN SELEKSI'),
          ...controller.pertanyaanSeleksi.asMap().entries.map((entry) {
            final number = entry.key + 1;
            final question = entry.value;
            final answer = controller
                    .pertanyaanControllers[questionIdOf(question)]?.text ??
                '-';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number. ${questionTextOf(question, number)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: applyBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    answer,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 15),
        _sectionTitle('RINGKASAN PROFIL'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ApplyJobAvatar(
                    radius: 28,
                    name: controller.namaController.text,
                    imageProvider: controller.profileImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.namaController.text.isEmpty
                              ? 'Nama Pelamar'
                              : controller.namaController.text,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          controller.emailController.text.isEmpty
                              ? 'Email belum diisi'
                              : controller.emailController.text,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 25),
              _infoRow('Telepon', controller.noTelpController.text),
              _infoRow('Alamat', controller.alamatController.text),
              _infoRow('Tentang Saya', controller.tentangSayaController.text),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (controller.pendidikanForms.isNotEmpty) ...[
          _sectionTitle('PENDIDIKAN'),
          ...controller.pendidikanForms.asMap().entries.map((entry) {
            final form = entry.value;
            final institution =
                (form['institusi'] as TextEditingController).text;
            final major = (form['jurusan'] as TextEditingController).text;
            final level = (form['tingkat'] as TextEditingController).text;
            final start =
                (form['tahun_mulai'] as TextEditingController).text;
            final end =
                (form['tahun_selesai'] as TextEditingController).text;

            return _summaryCard(
              title: institution.isEmpty ? 'Institusi' : institution,
              subtitle: [level, major].where((v) => v.isNotEmpty).join(' - '),
              trailing: _yearRange(start, end),
            );
          }),
        ],
        if (controller.skillForms.isNotEmpty) ...[
          _sectionTitle('SKILL'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.skillForms.map((form) {
              final name =
                  (form['nama_skill'] as TextEditingController).text;

              return Chip(
                label: Text(
                  name.isEmpty ? 'Skill' : name,
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: applyGold.withValues(alpha: 0.15),
                side: BorderSide(
                  color: applyGold.withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),
        ],
        if (controller.pengalamanForms.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle('PENGALAMAN KERJA'),
          ...controller.pengalamanForms.map((form) {
            final company =
                (form['nama_perusahaan'] as TextEditingController).text;
            final position =
                (form['posisi'] as TextEditingController).text;
            final start =
                (form['tanggal_mulai'] as TextEditingController).text;
            final end =
                (form['tanggal_selesai'] as TextEditingController).text;

            return _summaryCard(
              title: company.isEmpty ? 'Perusahaan' : company,
              subtitle: position,
              trailing: _yearRange(start, end),
            );
          }),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing.isNotEmpty)
            Text(
              trailing,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  String _yearRange(String start, String end) {
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isNotEmpty && end.isNotEmpty) return '$start - $end';
    return start.isNotEmpty ? start : end;
  }
}
