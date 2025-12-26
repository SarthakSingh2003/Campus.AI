import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  late FlutterTts flutterTts;
  String? language;
  bool isCurrentLanguageInstalled = false;
  double _volume = 0.8; // Reduced volume for more natural sound
  double _pitch = 1.45; // Higher pitch for feminine voice
  double _speechRate = 1.0; // Will be normalized per platform
  bool _cancelRequested = false; // for barge-in cancellation
  bool _isSpeaking = false; // track real speaking state

  TtsService() {
    initTts();
  }

  /// Platform-aware base rate (FlutterTTS scales differently per platform).
  double get _platformBaseRate {
    if (kIsWeb) return 1.0; // Web uses browser speech API (1.0 = normal)
    if (Platform.isAndroid) return 0.4; // Android normal is ~0.5–0.6, reducing to 0.4 per user request
    if (Platform.isIOS) return 0.65; // iOS normal is slightly higher
    return 0.85; // Fallback for other platforms
  }

  // Expose a safe base rate for callers (e.g., UI code).
  double get platformBaseRate => _platformBaseRate;

  void initTts() {
    flutterTts = FlutterTts();
    _setAwaitOptions();
    // Normalize the starting rate per platform to avoid "chipmunk" speed on devices.
    _speechRate = _platformBaseRate;

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      _isSpeaking = true;
      print("TTS: Speaking started.");
    });

    flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      print("TTS: Speaking completed.");
    });

    flutterTts.setCancelHandler(() {
      _isSpeaking = false;
      print("TTS: Speaking cancelled.");
    });

    flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      print("TTS error: $msg");
    });

    // Set feminine voice after initialization
    Future.delayed(const Duration(milliseconds: 500), () {
      setFeminineVoiceIfAvailable();
    });
  }

  void setCompletionHandler(Function() callback) {
    flutterTts.setCompletionHandler(callback);
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

  // Preferred female voices by locale (Android Google TTS typical names)
  static const Map<String, List<String>> _preferredFemaleVoicesByLocale = {
    'en-IN': [
      'en-in-x-end-network', // Network voices are higher quality
      'en-in-x-ene-network',
      'en-in-x-enc-network', 
      'en-in-x-end-local', 
      'en-in-x-ene-local',
      'en-in-x-ahp-network', // Often high quality
      'en-in-x-cxx-network',
      'en-in-x-cxx-local'
    ],
    'en-US': ['en-us-x-tpf-local', 'en-us-x-sfg-local', 'en-us-x-sfg-network'],
    'hi-IN': [
      'hi-in-x-hie-network', 
      'hi-in-x-hic-network',
      'hi-in-x-hie-local', 
      'hi-in-x-hif-local',
      'hi-in-x-cxx-network'
    ],
    // ... other languages
  };

  // Method to set feminine voice settings
  Future<void> setFeminineVoice() async {
    // Adjust pitch based on language - lower for Hindi to avoid sharp/shrill
    final isHindi = language?.toLowerCase().contains('hi') ?? false;
    
    // If we have a good female voice, we don't need extreme pitch
    // If we are forcing a male voice to sound female, we need higher pitch.
    // For now, let's assume we might have failed to get a female voice if it sounds "manly".
    // But if we DID get a female voice, natural pitch is better.
    
    // We'll set a moderate pitch that works for both cases (1.1 - 1.2 is usually safe for female voices)
    // 1.45 is very high (chipmunk territory often).
    // On Web, pitch shifting often glitches, so we keep it natural (1.0)
    await setPitch(isHindi ? 1.0 : (kIsWeb ? 1.0 : 1.1)); 
    
    // Keep a slightly brisk pace but normalize for device-specific scaling
    final targetRate = _platformBaseRate; // Standard rate is usually better for clarity
    await setSpeechRate(targetRate);
    await setVolume(1.0); // Full volume
    print("TTS: Feminine voice settings applied (pitch: ${isHindi ? 1.0 : 1.1})");
  }

  // Method to get available voices and set a feminine one if available
  Future<void> setFeminineVoiceIfAvailable() async {
    if (isAndroid) {
      try {
        List<dynamic>? voices = await flutterTts.getVoices;
        if (voices != null) {
          // 1) Try preferred female voices for current locale
          final String locale = language ?? 'en-IN';
          final preferred = _preferredFemaleVoicesByLocale[locale] ?? const [];
          
          for (final preferredName in preferred) {
            final match = voices.firstWhere(
              (v) {
                if (v is! Map) return false;
                final name = v['name']?.toString().toLowerCase() ?? '';
                return name == preferredName.toLowerCase();
              },
              orElse: () => null,
            );
            if (match != null) {
              final voiceMap = Map<String, String>.from(
                (match as Map).map((key, value) => MapEntry(key.toString(), value.toString()))
              );
              await flutterTts.setVoice(voiceMap);
              print("TTS: Set preferred feminine voice -> ${match['name']}");
              // Reset pitch to natural since we found a real female voice
              await setPitch(1.0); 
              return;
            }
          }

          // 2) Otherwise pick any female-looking voice for the locale
          for (var voice in voices) {
            if (voice is! Map) continue;
            final name = (voice['name']?.toString() ?? '').toLowerCase();
            final loc = (voice['locale']?.toString() ?? '').toLowerCase();
            final gender = (voice['gender']?.toString() ?? '').toLowerCase();
            
            // Check broad matching
            if (loc.contains((language ?? 'en-IN').toLowerCase().split('-')[0]) && // Loose locale match (en-IN vs en_IN)
                (gender.contains('female') ||
                 name.contains('female') ||
                 name.contains('-f') ||
                 name.contains('girl') ||
                 name.contains('woman'))) {
              final voiceMap = Map<String, String>.from(
                voice.map((key, value) => MapEntry(key.toString(), value.toString()))
              );
              await flutterTts.setVoice(voiceMap);
              print("TTS: Set generic feminine voice -> ${voice['name']}");
              await setPitch(1.0);
              return;
            }
          }
        }
      } catch (e) {
        print("TTS: Error setting feminine voice: $e");
      }
    } else if (kIsWeb) {
      // Specialized logic for Web (Chrome/Edge on Windows often has "Microsoft Zira" or "Google US English")
      try {
        var voices = await flutterTts.getVoices;
        if (voices != null) {
          for (var voice in voices) {
            final name = (voice['name']?.toString() ?? '').toLowerCase();
            // "Zira" is the best standard female voice on Windows
            // "Google US English" is female by default on Chrome
            if (name.contains('zira') || 
                name.contains('google us english') || 
                name.contains('female')) {
              await flutterTts.setVoice(voice);
              print("TTS: Set Web feminine voice -> ${voice['name']}");
              await setPitch(1.0);
              return;
            }
          }
        }
      } catch (e) {
        print("TTS: Error Web voice search: $e");
      }
    }
    
    // Fallback: Apply feminine usage settings if no specific voice found
    // This will boost pitch to try and make a male voice sound female-ish
    // But force natural on Web to avoid artifacts
    await setPitch(kIsWeb ? 1.0 : 1.4); 
    print("TTS: No specific female voice found, using fallback pitch");
  }

  // Method to set language with Hindi support
  Future<void> setLanguage(String selectedLanguage) async {
    language = selectedLanguage;

    // Map language codes to TTS language codes
    String ttsLanguage = _mapToTtsLanguage(selectedLanguage);
    
    print("TTS: Input language: $selectedLanguage -> Mapped to: $ttsLanguage");
    
      // Force Hindi if input contains Hindi characters or is explicitly Hindi
      bool isHindi = selectedLanguage.toLowerCase().contains('hi') || 
          selectedLanguage.toLowerCase().startsWith('hi');
      if (isHindi) {
        ttsLanguage = 'hi-IN';
        print("TTS: Forcing Hindi (hi-IN) for input: $selectedLanguage");
      }

    await flutterTts.setLanguage(ttsLanguage);
    
    // Adjust pitch based on language - lower for Hindi to avoid sharp/shrill
    if (isHindi || ttsLanguage.startsWith('hi')) {
      await setPitch(1.2);
      print("TTS: Set pitch to 1.2 for Hindi (less sharp/shrill)");
      await setSpeechRate(_platformBaseRate + 0.05); // keep Hindi slower
    } else {
      await setPitch(kIsWeb ? 1.0 : 1.1); // Reduced from 1.45 (too high) to 1.1 (slightly feminine but natural)
      print("TTS: Set pitch to 1.1 for non-Hindi language");
      await setSpeechRate(_platformBaseRate + 0.05);
    }
    
    if (isAndroid) {
      bool isInstalled =
          await flutterTts.isLanguageInstalled(ttsLanguage) as bool;
      isCurrentLanguageInstalled = isInstalled;
      print("TTS: Language $ttsLanguage installed -> $isInstalled");

      // For Hindi, don't fallback - use hi-IN even if not perfectly installed
      // The engine can still speak Hindi text
      if (!isInstalled && ttsLanguage.startsWith('hi')) {
        print("TTS: Hindi language not fully installed, but will attempt to speak Hindi");
        // Keep hi-IN as it can still work
      } else if (!isInstalled) {
        // Fallbacks for non-Hindi languages only
        final fallbacks = ['en-US', 'en-GB'];
        for (final fb in fallbacks) {
          await flutterTts.setLanguage(fb);
          final ok = await flutterTts.isLanguageInstalled(fb) as bool? ?? true;
          print("TTS: Fallback language $fb installed -> $ok");
          if (ok) {
            language = fb;
            break;
          }
        }
      }
    }
  }

  // Map our language codes to TTS language codes
  String _mapToTtsLanguage(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'hi':
      case 'hindi':
      case 'hi-in':
        return 'hi-IN'; // Hindi (India)
      case 'en':
      case 'english':
      case 'en-in':
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
    // Clamp to a human-like range; Android/iOS expect ~0.3–1.0
    _speechRate = speechRate.clamp(0.3, 1.0);
    await flutterTts.setSpeechRate(_speechRate);
    print("TTS: Speech rate set to $_speechRate");
  }

  // Method to set pitch (0.5 to 2.0) - More natural settings
  Future<void> setPitch(double pitch) async {
    // Clamp to a more natural range (1.0 to 1.6) for feminine voice
    _pitch = pitch.clamp(1.0, 1.6);
    await flutterTts.setPitch(_pitch);
    print("TTS: Pitch set to $_pitch");
  }

  // Main method to speak the given text after cleaning it
  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      String cleanedText = _cleanText(text);
      _cancelRequested = false;

      print("TTS: Speaking text (length: ${cleanedText.length}), language: $language");
      if (kDebugMode && cleanedText.length < 100) {
        print("TTS: Text preview: ${cleanedText.substring(0, cleanedText.length > 50 ? 50 : cleanedText.length)}...");
      }

      // Set human-like speech parameters
      await flutterTts.setSpeechRate(_speechRate);
      await flutterTts.setVolume(_volume);
      await flutterTts.setPitch(_pitch);
      
      // Speak entire reply at once for maximum reliability
      await flutterTts.speak(cleanedText);
    } else {
      print("TTS: Text is empty, cannot speak.");
    }
  }

  // Cleans input to remove Markdown symbols (*, #) and Emojis that TTS might read aloud
  String _cleanText(String input) {
    if (input.isEmpty) return "";
    String cleaned = input;

    // 1. Remove Markdown formatting
    // Remove individual asterisks (*)
    cleaned = cleaned.replaceAll('*', ''); 
    // Remove hashtags (#) often used for headers
    cleaned = cleaned.replaceAll('#', '');
    // Remove underscores (_) often used for italics
    cleaned = cleaned.replaceAll('_', '');

    // 2. Remove Emojis (Robust Regex)
    try {
      // Basic ranges for common emojis
      cleaned = cleaned.replaceAll(RegExp(r'[\u{1F600}-\u{1F64F}]', unicode: true), ''); // Emoticons
      cleaned = cleaned.replaceAll(RegExp(r'[\u{1F300}-\u{1F5FF}]', unicode: true), ''); // Simbols & Pictographs
      cleaned = cleaned.replaceAll(RegExp(r'[\u{1F680}-\u{1F6FF}]', unicode: true), ''); // Transport & Map
      cleaned = cleaned.replaceAll(RegExp(r'[\u{1F1E0}-\u{1F1FF}]', unicode: true), ''); // Flags
      cleaned = cleaned.replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '');   // Misc symbols
      cleaned = cleaned.replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), '');   // Dingbats
    } catch (e) {
      if (kDebugMode) print("TTS: Emoji removal warning: $e");
    }

    // 3. Clean up whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.trim();
  }

  Future<void> _setAwaitOptions() async {
    // Await completion causes issues on some Web browsers/versions, leading to "breaking" voice
    // Disable it for Web to ensure smooth playback
    if (!kIsWeb) {
      await flutterTts.awaitSpeakCompletion(true);
    }
  }

  Future<void> stop() async {
    _cancelRequested = true;
    await flutterTts.stop();
  }
}
