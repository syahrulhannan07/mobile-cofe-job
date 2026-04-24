// lib/features/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // 1. Logo (Menggunakan Image Asset)
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    child: Image.asset(
                      'assets/logo_cofe_job.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.coffee_rounded,
                          size: 50,
                          color: Color(0xFF7B5E43),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Judul
                const Text(
                  "Selamat Datang di CAFE JOB",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Buat Akun untuk Careermu",
                  style: TextStyle(fontSize: 14, color: AppColors.textMain),
                ),
                const SizedBox(height: 24),

                // 3. Container Putih (Form)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const CustomTextField(label: "Username"),
                      const SizedBox(height: 16),
                      const CustomTextField(label: "Email"),
                      const SizedBox(height: 16),
                      const CustomTextField(
                        label: "Password",
                        isPassword: true,
                      ),
                      const SizedBox(height: 16),
                      const CustomTextField(
                        label: "Konfirmasi Password",
                        isPassword: true,
                      ),
                      const SizedBox(height: 12),

                      // 4. Baris Teks Bawah Input
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Sudah punya akun? Masuk disini",
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 5. Tombol Daftar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonMain,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Daftar",
                            style: TextStyle(
                              color: AppColors.textOnButton,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        "Atau",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 6. Tombol Daftar dengan Google (Tambahan Baru)
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.g_mobiledata,
                          color: Color.fromRGBO(74, 52, 40, 1),
                          size: 30,
                        ),
                        label: const Text(
                          "Daftar dengan Google",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 40,
                ), // Ruang ekstra di bawah agar nyaman di-scroll
              ],
            ),
          ),
        ),
      ),
    );
  }
}
