import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_config.dart';

class AuthService {
  // ================= LOGIN =================
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"email": email, "kata_sandi": password}),
      );

      print("DEBUG Status: ${response.statusCode}");
      print("DEBUG Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        var responseData = data['data'];

        // Mengambil token dari data (berdasarkan log Anda)
        String? token = responseData != null
            ? responseData['token']?.toString()
            : null;

        if (token != null) {
          // 1. Simpan Token
          await prefs.setString("token", token);

          // 2. Set isLoggedIn agar main.dart langsung mengarah ke beranda
          await prefs.setBool("isLoggedIn", true);

          await prefs.setString(
            "user_name",
            responseData['pengguna']['nama_pengguna'],
          );

          // 3. Ambil data profil (menggunakan key 'pengguna' sesuai log server)
          var userProfile = responseData['pengguna'] ?? {};

          return {
            "status": true,
            "message": data["message"] ?? "Login Berhasil",
            "user": userProfile,
          };
        } else {
          return {
            "status": false,
            "message": "Login berhasil, namun token tidak ditemukan.",
          };
        }
      } else {
        return {
          "status": false,
          "message": data["message"] ?? "Email atau Password salah",
        };
      }
    } catch (e) {
      print("CRITICAL ERROR: $e");
      return {
        "status": false,
        "message": "Terjadi kesalahan sistem saat memproses data akun.",
      };
    }
  }

  // ================= REGISTER PELAMAR =================
  Future<Map<String, dynamic>> registerPelamar({
    required String nama,
    required String email,
    required String password,
    required String konfirmasi_password,
    required String peran,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerPelamar),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "nama_pengguna": nama,
          "email": email,
          "kata_sandi": password,
          "konfirmasi_kata_sandi": konfirmasi_password,
          "peran": peran,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "status": true,
          "message": data["message"] ?? "Registrasi berhasil",
        };
      } else {
        if (data["errors"] != null) {
          return {
            "status": false,
            "message": data["errors"].values.first[0].toString(),
          };
        }
        return {
          "status": false,
          "message": data["message"] ?? "Registrasi gagal",
        };
      }
    } catch (e) {
      return {"status": false, "message": "Gagal terhubung ke server."};
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
