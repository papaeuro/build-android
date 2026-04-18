import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  /* IMPORTANT : Sur GitHub Codespaces, ne mets pas l'IP locale.
     Tu dois utiliser l'URL publique de ton port 3000 que Codespaces génère.
     Elle ressemble souvent à : https://nom-du-codespace-3000.app.github.dev
  */
  static const String baseUrl = 'https://TON_URL_CODESPACE_3000';

  static Future<Map<String, dynamic>> sendCode(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 400) {
        throw Exception(data['message'] ?? 'Erreur envoi code');
      }
      return data;
    } catch (e) {
      throw Exception('Impossible de contacter le serveur : $e');
    }
  }

  static Future<Map<String, dynamic>> verifyCode({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'code': code,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 400) {
        throw Exception(data['message'] ?? 'Erreur validation code');
      }
      return data;
    } catch (e) {
      throw Exception('Erreur de connexion : $e');
    }
  }
}
