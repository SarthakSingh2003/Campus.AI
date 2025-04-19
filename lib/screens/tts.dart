import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  late FlutterTts flutterTts;
  String? language;
  bool isCurrentLanguageInstalled = false;
  double _volume = 1.0; // Default volume
  double _pitch = 1.3;  // Default pitch
  double _speechRate = 1.75; // Increased speech rate for faster speaking

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

  // Method to set language
  Future<void> setLanguage(String selectedLanguage) async {
    language = selectedLanguage;
    await flutterTts.setLanguage(language!);
    if (isAndroid) {
      bool isInstalled = await flutterTts.isLanguageInstalled(language!) as bool;
      isCurrentLanguageInstalled = isInstalled;
      print("TTS: Language $language installed -> $isInstalled");
    }
  }

  // Method to set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await flutterTts.setVolume(_volume);
    print("TTS: Volume set to $_volume");
  }

  // Method to set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double speechRate) async {
    _speechRate = speechRate.clamp(0.0, 1.0);
    await flutterTts.setSpeechRate(_speechRate);
    print("TTS: Speech rate set to $_speechRate");
  }

  // Method to set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await flutterTts.setPitch(_pitch);
    print("TTS: Pitch set to $_pitch");
  }

  // Main method to speak the given text after cleaning it
  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      String cleanedText = _cleanText(text);
      await flutterTts.setSpeechRate(_speechRate);
      await flutterTts.setVolume(_volume);
      await flutterTts.setPitch(_pitch);
      await flutterTts.speak(cleanedText);
    } else {
      print("TTS: Text is empty, cannot speak.");
    }
  }

  // Removes unwanted characters like asterisks
  String _cleanText(String input) {
    return input.replaceAll(RegExp(r'[*#_~]'), '');
  }

  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> stop() async {
    await flutterTts.stop();
  }
}
