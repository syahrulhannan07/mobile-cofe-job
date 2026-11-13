import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_config.dart';
import '../models/chat_message.dart';

class ChatbotService {
  static Future<ChatMessage> sendMessage(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan. Silakan login kembali.');
    }

    final response = await http
        .post(
          Uri.parse(ApiConfig.chatbotAsk),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'messages': messages.map((message) => message.toJson()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 60));

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Respons server tidak valid.');
    }

    if (response.statusCode == 200 && data['status'] == 'success') {
      final result = data['data'];

      if (result is Map<String, dynamic>) {
        final content = result['content']?.toString() ?? '';
        if (content.isNotEmpty) {
          return ChatMessage(
            role: result['role']?.toString() ?? 'assistant',
            content: content,
          );
        }
      }

      throw Exception('Respons chatbot tidak valid.');
    }

    if (response.statusCode == 401) {
      throw Exception('Sesi login berakhir. Silakan login kembali.');
    }

    throw Exception(
      data['message']?.toString() ?? 'Gagal memproses pesan.',
    );
  }
}
