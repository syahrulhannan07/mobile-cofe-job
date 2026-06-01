import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {

  // ================= SIGN GOOGLE =================
  Future<Map<String, dynamic>> signInWithGoogle() async {
  try {

    // Login Google
    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    final googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    final user = userCredential.user;

    if (user == null) {
      return {
        "status": false,
        "message": "User Google tidak ditemukan",
      };
    }

    final prefs = await SharedPreferences.getInstance();

    final fcmToken = prefs.getString("fcm_token");

    final response = await http.post(
      Uri.parse(ApiConfig.googleAuth),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "nama_pengguna": user.displayName ?? "",
        "email": user.email ?? "",
        "fcm_token": fcmToken,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final token = data["token"];

      final userData = data["data"];

      await prefs.setString("token", token);
      await prefs.setBool("isLoggedIn", true);

      if (userData["id_pengguna"] != null) {
        await prefs.setInt(
          "user_id",
          int.parse(userData["id_pengguna"].toString()),
        );
      }

      await prefs.setString(
        "userName",
        userData["nama_pengguna"] ?? "",
      );

      await prefs.setString(
        "userEmail",
        userData["email"] ?? "",
      );

      await prefs.setString(
        "userRole",
        userData["peran"] ?? "",
      );

      return {
        "status": true,
        "token": token,
        "user": userData,
      };
    }

    return {
      "status": false,
      "message": data["message"] ?? "Login gagal",
    };
  } catch (e) {
    return {
      "status": false,
      "message": e.toString(),
    };
  }
}

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

        // Mengambil token dari data
        String? token = responseData != null
            ? responseData['token']?.toString()
            : null;

        if (token != null) {
          var userProfile = responseData['pengguna'] ?? {};

          // 1. Simpan Token dengan key 'auth_token' (Sinkron dengan NotificationScreen)
          await prefs.setString("token", token);

          // 2. Set isLoggedIn agar main.dart langsung mengarah ke beranda
          await prefs.setBool("isLoggedIn", true);

          // 3. Simpan user_id sebagai int untuk WebSocket Reverb
          if (userProfile['id_pengguna'] != null) {
            int? idInt = int.tryParse(userProfile['id_pengguna'].toString());
            if (idInt != null) {
              await prefs.setInt("user_id", idInt);
            }
          }

          // 4. Simpan data profil pendukung lainnya
          await prefs.setString("user_name", userProfile['nama_pengguna'] ?? '');
          await prefs.setString("userName", userProfile['nama_pengguna'] ?? '');
          await prefs.setString("userEmail", userProfile['email'] ?? '');
          await prefs.setString("userRole", userProfile['peran'] ?? '');

          // PERBAIKAN: Masukkan token ke dalam return agar dibaca oleh login_screen
          return {
            "status": true,
            "message": data["message"] ?? "Login Berhasil",
            "token": token,
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