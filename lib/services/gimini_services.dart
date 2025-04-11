import 'dart:convert';
import 'package:aia/models/chat_message.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY']!;
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  Future<String> getResponse(List<ChatMessage> history) async {
    try {
      final contents = <Map<String, dynamic>>[];

      for (var message in history) {
        contents.add({
          "role": message.isUser ? "user" : "model",
          "parts": [
            {"text": message.text},
          ],
        });
      }
      print("contents: $contents");
      final response = await http.post(
        Uri.parse("$_baseUrl?key=$_apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": contents,
          "system_instruction": {
            "parts": [
              {
                "text":
                    "You are an emotional and compassionate AI assistant called AIA. Respond with care and empathy.",
              },
            ],
          },
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json["candidates"][0]["content"]["parts"][0]["text"].trim();
      } else {
        print(response.body);

        throw Exception('Gemini API Error: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to get Gemini response: $e');
    }
  }
}

final geminiServiceProvider = Provider((ref) => GeminiService());
