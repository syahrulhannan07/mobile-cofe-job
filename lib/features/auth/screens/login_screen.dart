import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/network/api_config.dart'; // 🔥 Import ApiConfig yang baru dibuat
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Menyimpan session login secara lengkap & sinkron
  Future<void> _saveLoginSession(Map<String, dynamic> userData, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('token', token);
    
    if (userData['id_pengguna'] != null) {
      int? idInt = int.tryParse(userData['id_pengguna'].toString());
      if (idInt != null) {
        await prefs.setInt('user_id', idInt);
      }
    }
    
    await prefs.setString('userEmail', userData['email'] ?? '');
    await prefs.setString('userName', userData['nama_pengguna'] ?? '');
    await prefs.setString('userRole', userData['peran'] ?? '');
  }

  // Mengirim Token FCM ke Laravel Backend menggunakan ApiConfig
  Future<void> _uploadFcmTokenToBackend(String jwtToken) async {
    try {
      // 1. Ambil token FCM unik dari perangkat
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      
      if (fcmToken != null) {
        print("FCM Token Perangkat: $fcmToken");

        // 2. Kirim ke API Laravel menggunakan URL dari ApiConfig
        final dio = Dio(); 
        final response = await dio.post(
          ApiConfig.updateFcmToken, // 🔥 Menggunakan rute terpusat dari ApiConfig
          data: {
            'fcm_token': fcmToken,
          },
          options: Options(
            headers: {
              'Authorization': 'Bearer $jwtToken', // Membawa token JWT Pelamar
              'Accept': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200) {
          print("Token FCM berhasil disimpan di database Laravel.");
        }
      }
    } catch (e) {
      print("Gagal mengirim Token FCM ke backend: $e");
    }
  }

  Future<void> _handleLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Email dan Password wajib diisi", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(email, password);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result["status"] == true) {
        final userData = result["user"]; 
        final String token = result["token"] ?? "";

        // Validasi pengaman jika token gagal dilemparkan dari AuthService
        if (userData == null || token.isEmpty) {
          _showMessage("Gagal memproses data session dari server.", isError: true);
          return;
        }

        final String peran = userData["peran"] ?? "";

        // VALIDASI AKTOR: Hanya Pelamar yang boleh masuk ke Mobile App
        if (peran == "Pelamar") {
          // 1. Simpan session login local perangkat
          await _saveLoginSession(userData, token);

          // 2. Ambil dan kirim token FCM ke database Laravel
          await _uploadFcmTokenToBackend(token);

          _showMessage("Login berhasil! Selamat datang", isError: false);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainLayout()),
          );
        } else {
          _showMessage(
            "Akses ditolak. Akun Anda terdaftar sebagai $peran. Silakan login melalui Website.", 
            isError: true
          );
        }
      } else {
        _showMessage(result["message"] ?? "Login gagal", isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage("Terjadi kesalahan sistem. Coba lagi nanti.", isError: true);
    }
  }

  Future<void> _handleGoogleLogin() async {
  setState(() => _isLoading = true);

  try {
    final result = await _authService.signInWithGoogle();

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (!mounted) return;

    if (result['status'] == true) {
      final userData = result['user'];
      final String token = result['token'] ?? '';

      if (userData == null || token.isEmpty) {
        _showMessage(
          "Gagal memproses data akun Google",
          isError: true,
        );
        return;
      }

      final String peran =
          userData["peran"] ?? "";

      if (peran == "Pelamar") {

        await _saveLoginSession(
          userData,
          token,
        );

        await _uploadFcmTokenToBackend(
          token,
        );

        _showMessage(
          "Login Google berhasil",
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const MainLayout(),
          ),
        );

      } else {
        _showMessage(
          "Akses ditolak. Akun ini terdaftar sebagai $peran",
          isError: true,
        );
      }
    } else {
      _showMessage(
        result['message'] ??
            "Login Google gagal",
        isError: true,
      );
    }
  } catch (e) {

    if (mounted) {
      setState(() => _isLoading = false);
    }

    _showMessage(
      e.toString(),
      isError: true,
    );
  }
}

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: Image.asset(
                        'assets/logo_cofe_job.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.coffee,
                            size: 80,
                            color: Colors.brown,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Selamat Datang di CAFE JOB",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Masuk dan Temukan Career Impian Anda",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textAccent,
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
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CustomTextField(
                          label: "Email",
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          hintText: "Masukkan email",
                          prefixIcon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: "Password",
                          isPassword: true,
                          controller: _passwordController,
                          hintText: "Masukkan password",
                          prefixIcon: Icons.lock_outline,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Belum punya akun? Daftar",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textAccent,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Lupa Password?",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonMain,
                              disabledBackgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Masuk",
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

OutlinedButton.icon(
  onPressed: _isLoading
      ? null
      : _handleGoogleLogin,
  icon: _isLoading
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        )
      : const Icon(
          Icons.g_mobiledata,
          size: 30,
          color: Color.fromRGBO(
            74,
            52,
            40,
            1,
          ),
        ),
  label: Text(
    _isLoading
        ? "Memproses..."
        : "Masuk dengan Google",
    style: const TextStyle(
      color: Colors.grey,
      fontSize: 14,
    ),
  ),
  style: OutlinedButton.styleFrom(
    minimumSize: const Size(
      double.infinity,
      50,
    ),
    shape: RoundedRectangleBorder(
      borderRadius:
          BorderRadius.circular(30),
    ),
    side: const BorderSide(
      color: Colors.grey,
    ),
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
      ),
    );
  }
}