import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  // Use the API Key provided by the user
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // Using the specific model requested by the user
  // List of models to try in order
  static const List<String> _modelNames = [
    'gemini-2.5-flash',
  ];

  GeminiService() {
    // No specific init needed for dynamic model creation
  }

  Future<String> generateResponse(String prompt) async {
    List<String> errors = [];

    for (String modelName in _modelNames) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: _apiKey,
          systemInstruction: Content.system("You are KIRA, an AI assistant for United Institute of Technology. Keep your answers concise, short, and to the point. Only elaborate if explicitly asked."),
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 8192,
          ),
        );

        if (kDebugMode) {
          print("Gemini: Trying model $modelName...");
        }

        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);
        
        if (response.text != null && response.text!.isNotEmpty) {
           if (kDebugMode) print("Gemini: Success with $modelName");
           return response.text!;
        }
      } catch (e) {
        if (kDebugMode) {
          print("Gemini Error ($modelName): $e");
        }
        errors.add("$modelName: $e");
        // Continue to next model
      }
    }

    // If we get here, all models failed
    return "I'm having trouble connecting. All my brains are tired! (Error: ${errors.lastOrNull})";
  }
}
