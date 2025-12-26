import 'package:flutter/foundation.dart';

class AiConfig {
  static String get baseUrl {
    // 1. Check for Web first
    if (kIsWeb) {
      // For Web, we use localhost. 
      // NOTE: User MUST configure Ollama with OLLAMA_ORIGINS="*" to allow browser requests.
      return 'http://localhost:11434/api/generate';
    }

    // 2. Check for Android (Emulator)
    // On Android Emulator, localhost is 10.0.2.2
    if (defaultTargetPlatform == TargetPlatform.android) {
       return 'http://10.0.2.2:11434/api/generate';
    }
    
    // 3. iOS / Desktop / Others
    return 'http://localhost:11434/api/generate';
  }

  // Model to use with Ollama
  static const String modelName = 'gemma3:1b';
}
