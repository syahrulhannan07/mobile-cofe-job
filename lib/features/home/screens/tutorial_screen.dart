import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  // Fungsi untuk menampilkan Pop-up Tutorial
  void _showTutorialPopup(BuildContext context, Map<String, dynamic> step) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDF7F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: step['iconBg'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(step['icon'], color: Colors.white, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  "${step['id']} ${step['title']}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF635147),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Langkah-langkah:",
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF635147)),
              ),
              const SizedBox(height: 10),
              Text(
                _getTutorialDescription(step['id']),
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Mengerti",
                style: TextStyle(color: Color(0xFF5A7B2A), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Fungsi Helper untuk deskripsi singkat tutorial
  String _getTutorialDescription(String id) {
    switch (id) {
      case "1.":
        return "Gunakan fitur pencarian di halaman utama untuk menemukan pekerjaan berdasarkan posisi, lokasi, atau kategori yang Anda inginkan.";
      case "2.":
        return "Klik pada kartu lowongan yang menarik minat Anda, lalu tekan tombol 'Lamar Sekarang' untuk memulai proses pendaftaran.";
      case "3.":
        return "Pastikan CV, Portofolio, dan dokumen pendukung lainnya dalam format PDF sudah siap untuk diunggah ke sistem.";
      case "4.":
        return "Beberapa perusahaan memerlukan jawaban singkat terkait pengalaman Anda. Jawablah dengan jujur dan profesional.";
      case "5.":
        return "Selalu perbarui data diri, pengalaman kerja, dan kontak Anda di menu Profil agar perusahaan mudah menghubungi Anda.";
      case "6.":
        return "Cek kembali semua data yang sudah diisi. Jika sudah sesuai, klik 'Kirim Lamaran' dan tunggu notifikasi selanjutnya.";
      default:
        return "Ikuti petunjuk yang tersedia pada aplikasi untuk menyelesaikan proses ini.";
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color coffeeBrown = Color(0xFF635147);
    const Color coffeeTan = Color(0xFF9E8E81);
    const Color matchaGreen = Color(0xFF5A7B2A);
    const Color matchaLight = Color(0xFF8DB04B);
    const Color accentOrange = Color(0xFFF5B54E);
    const Color accentLightGreen = Color(0xFFB8E08C);

    final List<Map<String, dynamic>> tutorialSteps = [
      {"id": "1.", "title": "Cari Lowongan Pekerjaan", "icon": Icons.search_rounded, "gradient": [coffeeBrown, coffeeTan], "iconBg": accentOrange},
      {"id": "2.", "title": "Lamar Lowongan Tersebut", "icon": Icons.coffee_rounded, "gradient": [matchaGreen, matchaLight], "iconBg": accentLightGreen},
      {"id": "3.", "title": "Upload Dokumen Lamaran", "icon": Icons.cloud_upload_rounded, "gradient": [matchaLight, matchaGreen], "iconBg": accentLightGreen},
      {"id": "4.", "title": "Jawab Pertanyaan Perusahaan", "icon": Icons.chat_bubble_rounded, "gradient": [coffeeTan, coffeeBrown], "iconBg": accentOrange},
      {"id": "5.", "title": "Periksa Profile dan Perbarui", "icon": Icons.person_search_rounded, "gradient": [coffeeBrown, coffeeTan], "iconBg": accentOrange},
      {"id": "6.", "title": "Review Ringkasan Data Lamaran dan Kirim", "icon": Icons.content_paste_search_rounded, "gradient": [matchaGreen, matchaLight], "iconBg": accentLightGreen},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.brownLight,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 10,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: coffeeBrown),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Text(
                      "Tutorial",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2, color: coffeeBrown),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.85,
                ),
                itemCount: tutorialSteps.length,
                itemBuilder: (context, index) {
                  final step = tutorialSteps[index];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: step['gradient'],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (step['gradient'][0] as Color).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        // AKSI KLIK UNTUK MUNCULKAN POP-UP
                        onTap: () => _showTutorialPopup(context, step),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: step['iconBg'],
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(step['icon'], color: Colors.white, size: 32),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                step['id'],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                step['title'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.2, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
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