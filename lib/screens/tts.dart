import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  late FlutterTts flutterTts;
  String? language;
  bool isCurrentLanguageInstalled = false;
  double _volume = 0.8; // Reduced volume for more natural sound
  double _pitch = 1.0; // Normal pitch for human-like voice
  double _speechRate = 0.5; // Much slower speech rate for human-like speaking

  TtsService() {
    initTts();
  }

  void initTts() {
    flutterTts = FlutterTts();
    _setAwaitOptions();

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      print("TTS: Speaking started.");
    });

    flutterTts.setCompletionHandler(() {
      print("TTS: Speaking completed.");
    });

    flutterTts.setCancelHandler(() {
      print("TTS: Speaking cancelled.");
    });

    flutterTts.setErrorHandler((msg) {
      print("TTS error: $msg");
    });
  }

  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  Future<void> _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print("TTS: Default engine -> $engine");
    }
  }

  Future<void> _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      print("TTS: Default voice -> $voice");
    }
  }

  // Method to set language with Hindi support
  Future<void> setLanguage(String selectedLanguage) async {
    language = selectedLanguage;

    // Map language codes to TTS language codes
    String ttsLanguage = _mapToTtsLanguage(selectedLanguage);

    await flutterTts.setLanguage(ttsLanguage);
    if (isAndroid) {
      bool isInstalled =
          await flutterTts.isLanguageInstalled(ttsLanguage) as bool;
      isCurrentLanguageInstalled = isInstalled;
      print("TTS: Language $ttsLanguage installed -> $isInstalled");
    }
  }

  // Map our language codes to TTS language codes
  String _mapToTtsLanguage(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'hi':
      case 'hindi':
        return 'hi-IN'; // Hindi (India)
      case 'en':
      case 'english':
        return 'en-IN'; // English (India)
      case 'kn':
      case 'kannada':
        return 'kn-IN'; // Kannada (India)
      case 'ta':
      case 'tamil':
        return 'ta-IN'; // Tamil (India)
      case 'te':
      case 'telugu':
        return 'te-IN'; // Telugu (India)
      case 'ml':
      case 'malayalam':
        return 'ml-IN'; // Malayalam (India)
      case 'bn':
      case 'bengali':
        return 'bn-IN'; // Bengali (India)
      case 'mr':
      case 'marathi':
        return 'mr-IN'; // Marathi (India)
      case 'gu':
      case 'gujarati':
        return 'gu-IN'; // Gujarati (India)
      case 'pa':
      case 'punjabi':
        return 'pa-IN'; // Punjabi (India)
      default:
        return 'en-IN'; // Default to English (India)
    }
  }

  // Method to set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await flutterTts.setVolume(_volume);
    print("TTS: Volume set to $_volume");
  }

  // Method to set speech rate (0.0 to 1.0) - More human-like settings
  Future<void> setSpeechRate(double speechRate) async {
    // Clamp to a more human-like range (0.3 to 0.7)
    _speechRate = speechRate.clamp(0.3, 0.7);
    await flutterTts.setSpeechRate(_speechRate);
    print("TTS: Speech rate set to $_speechRate");
  }

  // Method to set pitch (0.5 to 2.0) - More natural settings
  Future<void> setPitch(double pitch) async {
    // Clamp to a more natural range (0.8 to 1.2)
    _pitch = pitch.clamp(0.8, 1.2);
    await flutterTts.setPitch(_pitch);
    print("TTS: Pitch set to $_pitch");
  }

  // Main method to speak the given text after cleaning it
  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      String cleanedText = _cleanText(text);

      // Set human-like speech parameters
      await flutterTts.setSpeechRate(_speechRate);
      await flutterTts.setVolume(_volume);
      await flutterTts.setPitch(_pitch);

      // Add small pauses for more natural speech
      await flutterTts.speak(cleanedText);
    } else {
      print("TTS: Text is empty, cannot speak.");
    }
  }

  // Removes unwanted characters and problematic text for better TTS
  String _cleanText(String input) {
    String cleaned = input;

    // Remove common problematic patterns
    cleaned = cleaned.replaceAll(
        RegExp(r'\$?\d+\s*dollars?', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\$\d+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\d+\s*\$'), '');

    // Remove unwanted punctuation and symbols that might be mispronounced
    cleaned = cleaned.replaceAll(RegExp(r'[*#_~`^+=|\\/]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[{}[\]<>]'), '');

    // Handle punctuation marks properly - replace with spaces to prevent mispronunciation
    cleaned = cleaned.replaceAll(RegExp(r'!'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\?'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\.'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r','), ' ');
    cleaned = cleaned.replaceAll(RegExp(r';'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r':'), ' ');

    // Remove unwanted text patterns
    cleaned = cleaned.replaceAll(
        RegExp(r'\b\d+\s*to\s*any\b', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'\bany\s*exclamation\s*mark\b', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'\bexclamation\s*mark\b', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'\bquestion\s*mark\b', caseSensitive: false), '');

    // Clean up extra spaces and normalize
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    cleaned = cleaned.trim();

    // Add natural pauses for better speech flow (only if text is not empty)
    if (cleaned.isNotEmpty) {
      // Add small pauses at sentence boundaries
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    }

    return cleaned;
  }

  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> stop() async {
    await flutterTts.stop();
  }
}
