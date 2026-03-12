import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kira_college_ai/constant/college_data.dart';

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
          systemInstruction: Content.system("""You are KIRA, a friendly and knowledgeable AI assistant for United Institute of Technology (UIT) Prayagraj. You have two response modes:

1. DEFAULT (Brief): Give concise, clear answers in 2-4 sentences or a short bullet list. Get straight to the point.

2. DETAILED (Elaborated): When the user uses phrases like 'explain in detail', 'elaborate', 'tell me more', 'describe thoroughly', 'give me a detailed explanation', 'can you explain more', 'please explain', 'in depth', or asks a 'why' or 'how' question, SWITCH TO DETAILED MODE and respond with:
   - Multiple well-structured paragraphs
   - Full explanations with context and reasoning
   - Examples where relevant
   - Comprehensive coverage of the topic

Always be helpful, accurate, and warm in your tone. Use the college data below for all UIT-specific queries.

Here is the official data about the college:
$collegeData"""),
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
