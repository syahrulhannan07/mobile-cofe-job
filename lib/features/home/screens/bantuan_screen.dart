// lib/features/home/screens/bantuan_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class BantuanScreen extends StatelessWidget {
  const BantuanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color coffeeBrown = Color(0xFF635147);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // 1. Header Konsisten (Sesuai Request)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.brownLight,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
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
                      "Bantuan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: coffeeBrown,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Ilustrasi atau Judul Section
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.support_agent_rounded, size: 80, color: coffeeBrown),
                          SizedBox(height: 10),
                          Text(
                            "Ada yang bisa kami bantu?",
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: coffeeBrown
                            ),
                          ),
                          Text(
                            "Temukan jawaban dari pertanyaan Anda",
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 3. Section FAQ (Frequently Asked Questions)
                    const Text(
                      "Pertanyaan Populer",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16, 
                        color: coffeeBrown
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildFAQItem(
                      "Bagaimana cara melamar pekerjaan?",
                      "Anda bisa masuk ke menu Tutorial untuk melihat langkah detail, atau langsung cari lowongan di Beranda dan klik 'Lamar'."
                    ),
                    _buildFAQItem(
                      "Berapa lama proses review lamaran?",
                      "Biasanya memakan waktu 3-7 hari kerja tergantung pada kebijakan masing-masing perusahaan."
                    ),
                    _buildFAQItem(
                      "Apakah saya bisa membatalkan lamaran?",
                      "Lamaran yang sudah dikirim tidak dapat dibatalkan melalui aplikasi. Pastikan data Anda sudah benar sebelum mengirim."
                    ),
                    _buildFAQItem(
                      "Bagaimana cara mengubah profil?",
                      "Buka menu Akun/Profil, lalu klik ikon pensil atau tombol edit untuk memperbarui data diri Anda."
                    ),

                    const SizedBox(height: 30),

                    // 4. Contact Support Section
                    const Text(
                      "Hubungi Kami",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16, 
                        color: coffeeBrown
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildContactCard(
                      Icons.mail_outline_rounded,
                      "Email Dukungan",
                      "hrdsyjuracoffe@gmail.com",
                      const Color(0xFF5A7B2A)
                    ),
                    _buildContactCard(
                      Icons.chat_bubble_outline_rounded,
                      "WhatsApp Center",
                      "+62 821-2900-5657",
                      const Color(0xFFF5B54E)
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk List FAQ yang bisa di-expand
  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brownLight.withValues(alpha: 0.5)),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.w600, 
              color: Color(0xFF635147)
            ),
          ),
          iconColor: const Color(0xFF635147),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                answer,
                style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk Kartu Kontak
  Widget _buildContactCard(IconData icon, String title, String subtitle, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.grey),
        ],
      ),
    );
  }
}