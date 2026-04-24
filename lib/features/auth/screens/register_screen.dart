// lib/features/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart'; // Pastikan path import ini sesuai

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. Inisialisasi Controller
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // 2. Fungsi Register
  Future<void> _handleRegister() async {
    final String name = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    // Validasi sederhana
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Semua field harus diisi");
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Konfirmasi password tidak cocok");
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.registerPelamar(
      nama: name,
      email: email,
      password: password,
    );

    setState(() => _isLoading = false);

    if (result['status'] == true) {
      _showSnackBar(result['message'], isSuccess: true);
      // Kembali ke halaman login setelah sukses
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } else {
      _showSnackBar(result['message']);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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

                // Logo
                Center(
                  child: SizedBox(
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

                // Judul
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

                // Container Putih (Form)
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
                      CustomTextField(
                        label: "Username",
                        controller: _usernameController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: "Email",
                        controller: _emailController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: "Password",
                        isPassword: true,
                        controller: _passwordController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: "Konfirmasi Password",
                        isPassword: true,
                        controller: _confirmPasswordController,
                      ),
                      const SizedBox(height: 12),

                      // Navigasi ke Login
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
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

                      // Tombol Daftar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonMain,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
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

                      // Tombol Google
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : () {},
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}