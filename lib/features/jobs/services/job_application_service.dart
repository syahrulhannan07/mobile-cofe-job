import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/job_application_start.dart';

class JobApplicationService {
  static Future<String> _requireToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Sesi login tidak ditemukan. Silakan login kembali.',
      );
    }

    return token;
  }

  static Map<String, String> _jsonHeaders(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> _authHeaders(String token) {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _decode(http.Response response) {
    if (response.body.trim().isEmpty) return {};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw const ApiException('Respons server tidak valid.');
    }

    throw const ApiException('Respons server tidak valid.');
  }

  static String _messageOf(
    Map<String, dynamic> data,
    String fallback,
  ) {
    final message = data['message']?.toString();
    if (message != null && message.isNotEmpty) return message;

    final error = data['error']?.toString();
    if (error != null && error.isNotEmpty) return error;

    return fallback;
  }

  static Future<JobApplicationStart> startApplication(String jobId) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse(ApiConfig.mulaiLamaran),
      headers: _jsonHeaders(token),
      body: jsonEncode({'id_lowongan': jobId}),
    );
    final data = _decode(response);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['status'] == 'success' &&
        data['data'] is Map) {
      final payload = Map<String, dynamic>.from(data['data'] as Map);
      final rawId = payload['id_lamaran'];
      final idLamaran = rawId is List
          ? (rawId.isNotEmpty ? rawId.first.toString() : null)
          : rawId?.toString();
      final documents =
          payload['dokumen_wajib'] is List ? payload['dokumen_wajib'] as List : <dynamic>[];

      return JobApplicationStart(
        idLamaran: idLamaran,
        documents: documents,
      );
    }

    throw ApiException(
      _messageOf(data, 'Gagal memulai lamaran.'),
      statusCode: response.statusCode,
    );
  }

  static Future<List<dynamic>> fetchSelectionQuestions(String jobId) async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/lowongan/$jobId'),
      headers: _authHeaders(token),
    );
    final data = _decode(response);

    if (response.statusCode != 200) {
      throw ApiException(
        _messageOf(data, 'Gagal memuat pertanyaan seleksi.'),
        statusCode: response.statusCode,
      );
    }

    List<dynamic>? questions;
    final payload = data['data'];

    if (payload is Map) {
      final detail = Map<String, dynamic>.from(payload);

      if (detail['pertanyaan_seleksi'] is List) {
        questions = detail['pertanyaan_seleksi'] as List;
      } else if (detail['lowongan'] is Map &&
          (detail['lowongan'] as Map)['pertanyaan_seleksi'] is List) {
        questions =
            (detail['lowongan'] as Map)['pertanyaan_seleksi'] as List;
      } else if (detail['data'] is Map &&
          (detail['data'] as Map)['pertanyaan_seleksi'] is List) {
        questions = (detail['data'] as Map)['pertanyaan_seleksi'] as List;
      }
    } else if (data['pertanyaan_seleksi'] is List) {
      questions = data['pertanyaan_seleksi'] as List;
    }

    return questions ?? const [];
  }

  static Future<Map<String, dynamic>> fetchProfile() async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse(ApiConfig.profile),
      headers: _authHeaders(token),
    );
    final data = _decode(response);

    if (response.statusCode != 200) {
      throw ApiException(
        _messageOf(data, 'Gagal memuat profil pelamar.'),
        statusCode: response.statusCode,
      );
    }

    final payload = data['data'];
    if (payload is Map) return Map<String, dynamic>.from(payload);

    return data;
  }

  static Future<void> updateMasterProfile({
    required Map<String, String> fields,
    Uint8List? photoBytes,
    String? photoFileName,
  }) async {
    final token = await _requireToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.updateProfile),
    )
      ..headers.addAll(_authHeaders(token))
      ..fields.addAll(fields);

    if (photoBytes != null &&
        photoFileName != null &&
        photoFileName.isNotEmpty) {
      final extension = photoFileName.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'foto_profil',
          photoBytes,
          filename: photoFileName,
          contentType: MediaType.parse(mimeType),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decode(response);

    if (response.statusCode != 200) {
      throw ApiException(
        _messageOf(data, 'Gagal memperbarui profil utama.'),
        statusCode: response.statusCode,
      );
    }
  }

  static Future<void> saveEducation({
    String? id,
    required Map<String, dynamic> body,
  }) {
    return _saveProfileItem(
      endpoint: ApiConfig.pendidikan,
      id: id,
      body: body,
      fallbackMessage: 'Gagal menyimpan data pendidikan.',
    );
  }

  static Future<void> saveSkill({
    required Map<String, dynamic> body,
  }) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse(ApiConfig.skill),
      headers: _jsonHeaders(token),
      body: jsonEncode(body),
    );
    final data = _decode(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        _messageOf(data, 'Gagal menyimpan data keahlian.'),
        statusCode: response.statusCode,
      );
    }
  }

  static Future<void> saveExperience({
    String? id,
    required Map<String, dynamic> body,
  }) {
    return _saveProfileItem(
      endpoint: ApiConfig.pengalaman,
      id: id,
      body: body,
      fallbackMessage: 'Gagal menyimpan data pengalaman kerja.',
    );
  }

  static Future<void> _saveProfileItem({
    required String endpoint,
    required Map<String, dynamic> body,
    required String fallbackMessage,
    String? id,
  }) async {
    final token = await _requireToken();
    final hasId = id != null && id.isNotEmpty;
    final uri = Uri.parse(hasId ? '$endpoint/$id' : endpoint);
    final headers = _jsonHeaders(token);
    final encodedBody = jsonEncode(body);

    final response = hasId
        ? await http.put(uri, headers: headers, body: encodedBody)
        : await http.post(uri, headers: headers, body: encodedBody);
    final data = _decode(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        _messageOf(data, fallbackMessage),
        statusCode: response.statusCode,
      );
    }
  }

  static Future<void> deleteProfileItem({
    required String type,
    required String id,
  }) async {
    final endpoint = switch (type) {
      'pendidikan' => ApiConfig.pendidikan,
      'skill' => ApiConfig.skill,
      'pengalaman' => ApiConfig.pengalaman,
      _ => throw const ApiException('Tipe data profil tidak dikenal.'),
    };
    final token = await _requireToken();
    final response = await http.delete(
      Uri.parse('$endpoint/$id'),
      headers: _authHeaders(token),
    );
    final data = _decode(response);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException(
        _messageOf(data, 'Gagal menghapus data profil.'),
        statusCode: response.statusCode,
      );
    }
  }

  static Future<void> uploadDocument({
    required String idLamaran,
    required String idJenisDokumen,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final token = await _requireToken();
    final extension = fileName.split('.').last.toLowerCase();
    final mimeType = extension == 'pdf'
        ? 'application/pdf'
        : (extension == 'png' ? 'image/png' : 'image/jpeg');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/lamaran/$idLamaran/dokumen'),
    )
      ..headers.addAll(_authHeaders(token))
      ..fields['id_jenis_dokumen[]'] = idJenisDokumen;

    request.files.add(
      http.MultipartFile.fromBytes(
        'dokumen[]',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decode(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        _messageOf(data, 'Gagal mengunggah dokumen.'),
        statusCode: response.statusCode,
      );
    }
  }

  static Future<void> submitAnswers({
    required String idLamaran,
    required List<Map<String, dynamic>> answers,
  }) async {
    if (answers.isEmpty) return;

    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/lamaran/$idLamaran/jawaban'),
      headers: _jsonHeaders(token),
      body: jsonEncode({'jawaban': answers}),
    );
    final data = _decode(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        _messageOf(data, 'Gagal menyimpan jawaban seleksi.'),
        statusCode: response.statusCode,
      );
    }
  }

  static Future<void> submitApplication(String idLamaran) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/lamaran/$idLamaran/kirim'),
      headers: _jsonHeaders(token),
    );
    final data = _decode(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        _messageOf(data, 'Gagal menyelesaikan pengiriman lamaran.'),
        statusCode: response.statusCode,
      );
    }
  }
}
