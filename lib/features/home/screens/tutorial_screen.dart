import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  void _showTutorialPopup(BuildContext context, Map<String, dynamic> step) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.brownLight.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        color: AppColors.brownDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _getTutorialDescription(step['id'] as String),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brownDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Mengerti'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTutorialDescription(String id) {
    switch (id) {
      case '1.':
        return 'Gunakan fitur pencarian di halaman utama untuk menemukan pekerjaan berdasarkan posisi, lokasi, atau kategori yang Anda inginkan.';
      case '2.':
        return 'Klik pada kartu lowongan yang menarik minat Anda, lalu tekan tombol Lamar Sekarang untuk memulai proses pendaftaran.';
      case '3.':
        return 'Pastikan CV, portofolio, dan dokumen pendukung lainnya dalam format PDF sudah siap untuk diunggah ke sistem.';
      case '4.':
        return 'Beberapa perusahaan memerlukan jawaban singkat terkait pengalaman Anda. Jawablah dengan jujur dan profesional.';
      case '5.':
        return 'Selalu perbarui data diri, pengalaman kerja, dan kontak Anda di menu Profil agar perusahaan mudah menghubungi Anda.';
      case '6.':
        return 'Cek kembali semua data yang sudah diisi. Jika sudah sesuai, klik Kirim Lamaran dan tunggu notifikasi selanjutnya.';
      default:
        return 'Ikuti petunjuk yang tersedia pada aplikasi untuk menyelesaikan proses ini.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutorialSteps = <Map<String, dynamic>>[
      {
        'id': '1.',
        'title': 'Cari Lowongan Pekerjaan',
        'icon': Icons.search_rounded,
      },
      {
        'id': '2.',
        'title': 'Lamar Lowongan Tersebut',
        'icon': Icons.work_outline_rounded,
      },
      {
        'id': '3.',
        'title': 'Upload Dokumen Lamaran',
        'icon': Icons.cloud_upload_outlined,
      },
      {
        'id': '4.',
        'title': 'Jawab Pertanyaan Perusahaan',
        'icon': Icons.chat_bubble_outline_rounded,
      },
      {
        'id': '5.',
        'title': 'Periksa dan Perbarui Profil',
        'icon': Icons.person_outline_rounded,
      },
      {
        'id': '6.',
        'title': 'Review Data dan Kirim Lamaran',
        'icon': Icons.check_circle_outline_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F3ED),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.textMain,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Tutorial',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: tutorialSteps.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final step = tutorialSteps[index];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showTutorialPopup(context, step),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.brownLight
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                step['id'] as String,
                                style: const TextStyle(
                                  color: AppColors.brownDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                step['title'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey,
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
      ),
    );
  }
}
