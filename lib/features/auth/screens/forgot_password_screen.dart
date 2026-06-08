// lib/features/auth/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../features/auth/services/auth_service.dart';

/// Halaman Lupa Password — langkah 1: kirim email reset
/// Alur:
///   1. User masukkan email → tap "Kirim Link Reset"
///   2. App panggil API forgotPassword(email)
///   3. Tampilkan status: berhasil (cek email) / gagal (pesan error)
///   4. User buka email → klik link → diarahkan ke ResetPasswordScreen
///      (via deep link / WebView / browser, sesuai implementasi proyek)

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService(); // instance — bukan static

  /// 'form'    → tampilkan input email
  /// 'berhasil'→ email terkirim, minta user cek inbox
  /// 'memproses' ditangani via [_sedangMemproses]
  String _status = 'form';
  bool _sedangMemproses = false;
  String _pesanGalat = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ── Logic ──────────────────────────────────────────────────────────────────

  /// Kirim permintaan reset password ke backend (sama seperti website)
  Future<void> _kirimLinkReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _sedangMemproses = true;
      _pesanGalat = '';
    });

    try {
      // Panggil endpoint: POST /api/forgot-password  { email: "..." }
      final result = await _authService.forgotPassword(
        email: _emailController.text.trim(),
      );

      if (mounted) {
        if (result['status'] == true) {
          setState(() => _status = 'berhasil');
        } else {
          setState(() {
            _pesanGalat = result['message'] ??
                'Gagal mengirim link reset. Periksa email Anda atau coba lagi.';
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _pesanGalat = 'Gagal mengirim link reset. Periksa email Anda atau coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _sedangMemproses = false);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Logo ──────────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4C4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/logo_cafe_job.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.lock_reset_rounded,
                      size: 50,
                      color: Color(0xFF7B5E43),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Konten berganti berdasarkan status ────────────────────────
              if (_status == 'form') _buildFormKirimEmail(),
              if (_status == 'berhasil') _buildStatusBerhasil(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget: Form kirim email ───────────────────────────────────────────────
  Widget _buildFormKirimEmail() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Judul
          const Text(
            "Lupa Password?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Masukkan email akun Anda. Kami akan mengirimkan link untuk mengatur ulang password.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMain,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Card form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Input email dengan validasi
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Alamat Email",
                    labelStyle: const TextStyle(color: AppColors.textMain),
                    hintText: "contoh@email.com",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.textMain),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.buttonMain,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong.';
                    }
                    final emailValid = RegExp(
                      r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$',
                    ).hasMatch(value.trim());
                    if (!emailValid) return 'Format email tidak valid.';
                    return null;
                  },
                ),

                // Pesan galat dari API
                if (_pesanGalat.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(color: Colors.red.shade500, width: 4),
                      ),
                    ),
                    child: Text(
                      _pesanGalat,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Tombol kirim
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _sedangMemproses ? null : _kirimLinkReset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonMain,
                      disabledBackgroundColor:
                          AppColors.buttonMain.withValues(alpha: 0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: _sedangMemproses
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.textOnButton,
                            ),
                          )
                        : const Text(
                            "Kirim Link Reset",
                            style: TextStyle(
                              color: AppColors.textOnButton,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Kembali ke login
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "← Kembali ke halaman masuk",
              style: TextStyle(
                color: AppColors.buttonMain,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Widget: Status email terkirim ─────────────────────────────────────────
  Widget _buildStatusBerhasil() {
    return Column(
      children: [
        // Ikon centang
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_rounded,
            size: 34,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          "Email Terkirim!",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Link reset password telah dikirim ke:\n${_emailController.text.trim()}\n\nSilakan cek inbox (atau folder spam) dan klik link tersebut untuk mengatur ulang password Anda.",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textMain,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),

        // Kembali ke login
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonMain,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Kembali ke Halaman Masuk",
              style: TextStyle(
                color: AppColors.textOnButton,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),

        // Kirim ulang
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _status = 'form';
            _pesanGalat = '';
          }),
          child: const Text(
            "Tidak menerima email? Kirim ulang",
            style: TextStyle(
              color: AppColors.buttonMain,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}