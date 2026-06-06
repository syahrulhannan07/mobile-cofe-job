// lib/features/auth/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/network/api_config.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ================= SIGN IN / REGISTER WITH GOOGLE =================
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // ── WEB ──────────────────────────────────────────────────────
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        userCredential = await _auth.signInWithPopup(googleProvider);

      } else {
        // ── MOBILE (Android / iOS) ────────────────────────────────────
        // Paksa sign out dulu agar dialog pilih akun selalu muncul
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
  
        // Mulai alur autentikasi Google
        final GoogleSignInAccount? googleUser =
        await googleSignIn.signIn();

        if (googleUser == null) {
          return {
            "status": false,
            "message": "Login Google dibatalkan",
          };
        }
        
        // Minta token autentikasi
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        
        // idToken wajib ada untuk Firebase
        if (googleAuth.idToken == null) {
          return {
            "status": false,
            "message":
                "Gagal mendapatkan token dari Google. Pastikan koneksi internet stabil.",
          };
        }

        // Buat credential Firebase dari token Google
        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          // accessToken opsional di versi baru, tidak selalu tersedia
          accessToken: googleAuth.accessToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return {
          "status": false,
          "message": "Gagal memperoleh data akun dari Firebase.",
        };
      }

      // Kirim ke backend Laravel
      final response = await http.post(
        Uri.parse(ApiConfig.googleAuth),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "nama_pengguna": firebaseUser.displayName ?? "Pengguna Google",
          "email": firebaseUser.email,
          "fcm_token": "",
        }),
      );

      debugPrint("DEBUG Google Auth Status: ${response.statusCode}");
      debugPrint("DEBUG Google Auth Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        var responseData = data['data'];

        String? token =
            data['token'] ??
            (responseData != null
                ? responseData['token']?.toString()
                : null);

        if (token != null) {
          await prefs.setString("token", token);
          await prefs.setBool("isLoggedIn", true);

          if (responseData != null) {
            if (responseData['id_pengguna'] != null) {
              int? idInt =
                  int.tryParse(responseData['id_pengguna'].toString());
              if (idInt != null) await prefs.setInt("user_id", idInt);
            }
            await prefs.setString(
                "user_name", responseData['nama_pengguna'] ?? '');
            await prefs.setString(
                "userName", responseData['nama_pengguna'] ?? '');
            await prefs.setString("userEmail", responseData['email'] ?? '');
            await prefs.setString(
                "userRole", responseData['peran'] ?? 'Pelamar');
          }

          return {
            "status": true,
            "message": data["message"] ?? "Berhasil masuk dengan Google",
            "token": token,
            "user": responseData,
          };
        } else {
          return {
            "status": false,
            "message":
                "Sinkronisasi berhasil, namun token session tidak ditemukan.",
          };
        }
      } else {
        return {
          "status": false,
          "message": data["message"] ??
              "Gagal mensinkronisasikan data ke database utama.",
        };
      }
    } catch (e) {
      debugPrint("CRITICAL GOOGLE AUTH ERROR: $e");

      String pesanError = "Terjadi kesalahan saat login dengan Google.";
      final errStr = e.toString();

      if (errStr.contains('network_error') ||
          errStr.contains('NetworkException')) {
        pesanError = "Tidak ada koneksi internet. Periksa jaringan Anda.";
      } else if (errStr.contains('sign_in_canceled') ||
          errStr.contains('canceled')) {
        pesanError = "Login Google dibatalkan.";
      } else if (errStr.contains('sign_in_failed')) {
        pesanError =
            "Login Google gagal. Pastikan Google Play Services aktif.";
      } else if (e is FirebaseAuthException) {
        pesanError = "Firebase Error: ${e.message}";
      }

      return {"status": false, "message": pesanError};
    }
  }

  // ================= LOGIN MANUAL =================
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

        String? token = responseData != null ? responseData['token']?.toString() : null;

        if (token != null) {
          var userProfile = responseData['pengguna'] ?? {};

          await prefs.setString("token", token);
          await prefs.setBool("isLoggedIn", true);

          if (userProfile['id_pengguna'] != null) {
            int? idInt = int.tryParse(userProfile['id_pengguna'].toString());
            if (idInt != null) {
              await prefs.setInt("user_id", idInt);
            }
          }

          await prefs.setString("user_name", userProfile['nama_pengguna'] ?? '');
          await prefs.setString("userName", userProfile['nama_pengguna'] ?? '');
          await prefs.setString("userEmail", userProfile['email'] ?? '');
          await prefs.setString("userRole", userProfile['peran'] ?? '');

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

  // ================= REGISTER PELAMAR MANUAL =================
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