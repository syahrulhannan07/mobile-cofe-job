// lib/features/auth/screens/reset_password_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';
import '../../../../features/auth/services/auth_service.dart';

/// Halaman Atur Ulang Password — langkah 2
///
/// Dibuka setelah user klik link dari email. Link berisi query params:
///   ?token=xxx&email=yyy
///
/// Cara menerima parameter (pilih salah satu sesuai implementasi proyek):
///   A) Deep link  → gunakan paket `app_links` / `go_router`, parse URI-nya
///   B) In-app WebView → intercept URL lalu push halaman ini dengan argumen
///   C) Browser biasa → halaman website yang sudah jalan (tidak butuh file ini)
///
/// Contoh navigasi ke halaman ini dari deep link handler:
///   Navigator.pushNamed(
///     context,
///     '/reset-password',
///     arguments: ResetPasswordArgs(token: token, email: email),
///   );
///
/// Alur sama persis dengan website (AturUlangSandi.jsx):
///   • Terima token + email dari argumen navigasi
///   • Validasi lokal (min 8 karakter, konfirmasi cocok)
///   • POST ke API resetPassword → status berhasil / gagal

class ResetPasswordArgs {
  final String token;
  final String email;
  const ResetPasswordArgs({required this.token, required this.email});
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _passwordBaruController = TextEditingController();
  final _konfirmasiController = TextEditingController();
  final _authService = AuthService(); // instance — bukan static

  bool _sedangMemproses = false;
  bool _lihatPassword = false;
  bool _lihatKonfirmasi = false;

  /// 'form'     → tampilkan form isi password baru
  /// 'berhasil' → password berhasil diubah
  /// 'gagal'    → token invalid / kadaluarsa
  String _status = 'form';
  String _pesanGalat = '';

  late String _token;
  late String _emailPengguna;
  bool _argsDiambil = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsDiambil) {
      final args =
          ModalRoute.of(context)?.settings.arguments as ResetPasswordArgs?;
      if (args == null || args.token.isEmpty || args.email.isEmpty) {
        _status = 'gagal';
        _pesanGalat =
            'Link reset password tidak valid. Parameter token atau email tidak ditemukan.';
      } else {
        _token = args.token;
        _emailPengguna = args.email;
      }
      _argsDiambil = true;
    }
  }

  @override
  void dispose() {
    _passwordBaruController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  // ── Logic ──────────────────────────────────────────────────────────────────

  /// Kirim request ke API — sama persis dengan website:
  ///   POST /api/reset-password
  ///   { token, email, password, password_confirmation }
  Future<void> _simpanPasswordBaru() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _sedangMemproses = true;
      _pesanGalat = '';
    });

    try {
      final result = await _authService.resetPassword(
        token: _token,
        email: _emailPengguna,
        password: _passwordBaruController.text,
        passwordConfirmation: _konfirmasiController.text,
      );

      if (mounted) {
        if (result['status'] == true) {
          setState(() => _status = 'berhasil');
        } else {
          setState(() {
            _pesanGalat = result['message'] ??
                'Gagal mengatur ulang kata sandi. Link mungkin sudah kadaluarsa.';
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _pesanGalat = 'Gagal mengatur ulang kata sandi. Link mungkin sudah kadaluarsa.';
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
        leading: _status == 'form'
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textMain),
                onPressed: () => Navigator.pop(context),
              )
            : const SizedBox.shrink(),
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

              // Konten berganti sesuai status
              if (_status == 'form') _buildFormPasswordBaru(),
              if (_status == 'berhasil') _buildStatusBerhasil(),
              if (_status == 'gagal') _buildStatusGagal(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget: Form password baru ────────────────────────────────────────────
  Widget _buildFormPasswordBaru() {
    return Column(
      children: [
        const Text(
          "Atur Ulang Kata Sandi",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Masukkan kata sandi baru untuk akun $_emailPengguna",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textMain,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── Input password baru ──────────────────────────────────
                TextFormField(
                  controller: _passwordBaruController,
                  obscureText: !_lihatPassword,
                  decoration: InputDecoration(
                    labelText: "Kata Sandi Baru",
                    labelStyle: const TextStyle(color: AppColors.textMain),
                    hintText: "Minimal 8 karakter",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.textMain),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.buttonMain, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _lihatPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textMain,
                      ),
                      onPressed: () =>
                          setState(() => _lihatPassword = !_lihatPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kata sandi tidak boleh kosong.';
                    }
                    if (value.length < 8) {
                      return 'Kata sandi minimal 8 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Input konfirmasi password ────────────────────────────
                TextFormField(
                  controller: _konfirmasiController,
                  obscureText: !_lihatKonfirmasi,
                  decoration: InputDecoration(
                    labelText: "Konfirmasi Kata Sandi",
                    labelStyle: const TextStyle(color: AppColors.textMain),
                    hintText: "Ulangi kata sandi baru",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.textMain),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: AppColors.buttonMain, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _lihatKonfirmasi
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textMain,
                      ),
                      onPressed: () => setState(
                          () => _lihatKonfirmasi = !_lihatKonfirmasi),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi kata sandi tidak boleh kosong.';
                    }
                    if (value != _passwordBaruController.text) {
                      return 'Konfirmasi kata sandi tidak cocok.';
                    }
                    return null;
                  },
                ),

                // ── Pesan galat dari API ─────────────────────────────────
                if (_pesanGalat.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left:
                            BorderSide(color: Colors.red.shade500, width: 4),
                      ),
                    ),
                    child: Text(
                      _pesanGalat,
                      style: TextStyle(
                          color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Tombol simpan ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _sedangMemproses ? null : _simpanPasswordBaru,
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
                            "Simpan Kata Sandi Baru",
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
        ),

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
    );
  }

  // ── Widget: Berhasil ──────────────────────────────────────────────────────
  Widget _buildStatusBerhasil() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded,
              size: 36, color: Colors.green.shade700),
        ),
        const SizedBox(height: 20),
        const Text(
          "Berhasil!",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Kata sandi Anda berhasil diubah.\nSilakan masuk dengan kata sandi baru Anda.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textMain, height: 1.6),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(context, '/masuk', (_) => false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonMain,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: const Text(
              "Masuk Sekarang",
              style: TextStyle(
                color: AppColors.textOnButton,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Widget: Gagal / link invalid ─────────────────────────────────────────
  Widget _buildStatusGagal() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            shape: BoxShape.circle,
          ),
          child:
              Icon(Icons.close_rounded, size: 36, color: Colors.red.shade700),
        ),
        const SizedBox(height: 20),
        const Text(
          "Link Tidak Valid",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _pesanGalat,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textMain, height: 1.6),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(context, '/masuk', (_) => false),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonMain,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: const Text(
              "Kembali ke Halaman Login",
              style: TextStyle(
                color: AppColors.textOnButton,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}