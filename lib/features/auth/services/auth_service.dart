import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String baseUrl = "http://103.174.237.196:8083/api/v1";

  // ================= LOGIN =================
  Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "kata_sandi": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs =
            await SharedPreferences.getInstance();
        await prefs.setString(
            "token", data['data']['token']);

        return {
          "status": true,
          "message": data["message"],
          "data": data,
        };
      } else {
        return {
          "status": false,
          "message":
              data["message"] ?? "Login gagal",
        };
      }
    } catch (e) {
      return {
        "status": false,
        "message":
            "Terjadi kesalahan koneksi ke server",
      };
    }
  }

  // ================= REGISTER PELAMAR =================
  Future<Map<String, dynamic>> registerPelamar({
    required String nama,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/daftar-pelamar"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "nama_pengguna": nama,
          "email": email,
          "kata_sandi": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return {
          "status": true,
          "message":
              data["message"] ??
              "Register berhasil",
          "data": data,
        };
      } else {
        // kalau ada validasi error Laravel
        if (data["errors"] != null) {
          return {
            "status": false,
            "message":
                data["errors"].values.first[0],
          };
        }

        return {
          "status": false,
          "message":
              data["message"] ??
              "Register gagal",
        };
      }
    } catch (e) {
      return {
        "status": false,
        "message":
            "Terjadi kesalahan koneksi ke server",
      };
    }
  }
}