import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:kira_college_ai/config/ai_config.dart';

class OllamaService {
  // --- REMOTE ACCESS CONFIGURATION ---
  // If you are 20km away, you MUST use a Public URL (e.g., from Ngrok or Pinggy).
  // Paste your generated URL here (e.g., 'https://rand-123.pinggy.io/chat')
  static const String publicUrl = ''; 
  
  static String get baseUrl {
    // 1. Priority: Public URL (if set)
    if (publicUrl.isNotEmpty) return publicUrl;
    
    // 2. Local Fallbacks
    if (kIsWeb) return 'http://127.0.0.1:8000/chat';
    if (Platform.isAndroid) return 'http://192.168.1.10:8000/chat'; // My Laptop IP
    return 'http://127.0.0.1:8000/chat'; 
  }

  Future<String> generateResponse(String prompt) async {
    try {
      final url = Uri.parse(baseUrl);
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': prompt, // Backend expects 'message', not 'prompt'
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] as String;
      } else {
        throw Exception('Failed to load response: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to Backend: $e');
    }
  }
}
