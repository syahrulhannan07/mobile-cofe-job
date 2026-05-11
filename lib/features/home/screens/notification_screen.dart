// lib/features/home/screens/notification_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Mematikan leading default
        titleSpacing: 0, // Agar title bisa menempel ke kiri setelah icon
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textMain,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                "Notifikasi",
                style: TextStyle(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildNotificationSection("Hari Ini"),
          _buildNotificationItem(
            icon: Icons.work_outline_rounded,
            color: Colors.blue,
            title: "Lowongan Baru",
            description:
                "Indra Coffee Roasters baru saja memposting lowongan 'Head Barista'. Cek sekarang!",
            time: "2 Jam lalu",
          ),
          _buildNotificationItem(
            icon: Icons.assignment_turned_in_outlined,
            color: Colors.orange,
            title: "Status Lamaran",
            description:
                "Status lamaran Anda di Dermayu Beans & Co. telah berubah menjadi 'Wawancara'.",
            time: "5 Jam lalu",
          ),
          const SizedBox(height: 10),
          _buildNotificationSection("Kemarin"),
          _buildNotificationItem(
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green,
            title: "Sukses Lamaran",
            description:
                "Lamaran Anda untuk posisi 'Outlet Manager' berhasil terkirim.",
            time: "1 Hari lalu",
          ),
          _buildNotificationItem(
            icon: Icons.lock_reset_rounded,
            color: Colors.redAccent,
            title: "Keamanan Akun",
            description:
                "Perubahan email atau kata sandi Anda telah berhasil diperbarui.",
            time: "1 Hari lalu",
          ),
          _buildNotificationItem(
            icon: Icons.person_outline_rounded,
            color: AppColors.brownDark,
            title: "Update Profile",
            description:
                "Data profil Anda telah berhasil diperbarui. Foto profil baru telah terpasang.",
            time: "1 Hari lalu",
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(String day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 5),
      child: Text(
        day,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMain.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
