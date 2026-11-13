import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_config.dart';
import '../models/face_verification_outcome.dart';

class FaceVerificationService {
  const FaceVerificationService();

  Future<FaceVerificationOutcome> verifyApplication({
    required int idLamaran,
    required String imageBase64,
  }) {
    return _post(
      endpoint: ApiConfig.verifikasiWajah(idLamaran),
      payload: {'image_base64': imageBase64},
    );
  }

  Future<FaceVerificationOutcome> confirmAttendance({
    required int idLamaran,
    required int idWawancara,
    required String imageBase64,
  }) {
    return _post(
      endpoint: ApiConfig.konfirmasiWawancara(idLamaran),
      payload: {'image_base64': imageBase64, 'id_wawancara': idWawancara},
    );
  }

  Future<FaceVerificationOutcome> _post({
    required String endpoint,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));

      Map<String, dynamic> body = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          body = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}

      if (response.statusCode == 429) {
        return FaceVerificationOutcome.failure(
          'Terlalu banyak percobaan verifikasi. Tunggu satu menit sebelum mencoba lagi.',
          statusCode: 429,
        );
      }

      return FaceVerificationOutcome.fromResponse(response.statusCode, body);
    } catch (_) {
      return FaceVerificationOutcome.failure(
        'Tidak dapat terhubung ke layanan verifikasi wajah. Periksa koneksi internet Anda lalu coba lagi.',
      );
    }
  }
}
