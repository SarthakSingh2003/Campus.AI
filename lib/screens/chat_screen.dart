import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
import 'package:kira_college_ai/services/gemini_service.dart';
import 'package:kira_college_ai/components/assistant_message.dart';
import 'package:kira_college_ai/components/user_message.dart';

import 'package:kira_college_ai/components/voice_ripple_animation.dart';
import 'package:kira_college_ai/constant/languages.dart';
import 'package:kira_college_ai/constant/messages.dart';
import 'package:kira_college_ai/screens/tts.dart';
import 'package:kira_college_ai/models/chat_history.dart';
import 'package:kira_college_ai/services/chat_history_service.dart';
import 'package:kira_college_ai/screens/chat_history_screen.dart';
import 'package:kira_college_ai/services/college_data_service.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:kira_college_ai/constant/theme_provider.dart';
import 'package:kira_college_ai/components/space_scaffold.dart';

import 'package:kira_college_ai/services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatHistory? chatHistory;
  final bool isFromHistory;

  const ChatScreen({
    super.key,
    this.chatHistory,
    this.isFromHistory = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  TtsService ttsService = TtsService();
  final SpeechToText speechToTextInstance = SpeechToText();
  final GoogleTranslator translator = GoogleTranslator();
  final ChatHistoryService _historyService = ChatHistoryService();
  final GeminiService _geminiService = GeminiService();

  String recordedAudioString = "";
  String translatedString = "";
  String detectedLanguage = "";
  Timer? _silenceTimer;
  bool _isSilenceDetected = false;
  String _errorMessage = '';
  TextEditingController _saveHistoryController = TextEditingController();

  // Wake word detection
  bool _isWakeWordListening = false;
  Timer? _wakeWordWatchdog;
  String _wakeWordBuffer = "";
  static const List<String> _wakeWords = [
    'hello',
    'hi',
    'namaste',
    'hey',
    'stop', // Added STOP command
  ];
  // Animation controllers
  late AnimationController _titleController;
  late AnimationController _loadingController;
  late AnimationController _waveController;
  late AnimationController _particleController;

  late Animation<double> _titleAnimation;
  late Animation<double> _loadingAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _particleAnimation;

  List<Map<String, String>> messages = [];
  bool isLoading = false;
  bool isRecording = false;
  double currentSoundLevel = 0.0;

  String selectedLanguageCode = 'en';
  List<Map<String, String>> languages = language;
  Map<String, Map<String, String>> voiceSettings = voiceSetting;

  var _assistantResponse = "";
  String errorMessage = "";

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _initializeAnimations();

    // Initialize messages from history or use dummy messages
    if (widget.chatHistory != null && widget.isFromHistory) {
      messages = List<Map<String, String>>.from(widget.chatHistory!.messages);
    } else {
      messages = List.from(dummyMessages);
    }

    initializeSpeechToText();
    initializeTextToSpeech();
    _checkAndRequestPermission();

    // Only speak messages if not from history
    if (!widget.isFromHistory) {
      speakDummyMessages();
    }

    // Debug speech recognition status
    _debugSpeechRecognitionStatus();

    // Start wake-word listening after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !isRecording && !isLoading) {
        _startWakeWordListening();
      }
    });
  }

  void _initializeAnimations() {
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _titleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.elasticOut,
    ));

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.linear,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    _titleController.forward();
    _loadingController.repeat(reverse: true);
    _waveController.repeat();
    _particleController.repeat();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _loadingController.dispose();
    _waveController.dispose();
    _particleController.dispose();
    _silenceTimer?.cancel();
    _stopWakeWordListening();
    ttsService.stop();
    speechToTextInstance.stop();
    _saveHistoryController.dispose();
    super.dispose();
  }

  void speakDummyMessages() async {
    for (var message in messages) {
      if (message['role'] == 'assistant') {
        await ttsService.setLanguage('en-IN');
        await ttsService.setFeminineVoiceIfAvailable();
        await ttsService.setSpeechRate(ttsService.platformBaseRate + 0.1);
        await ttsService.setPitch(1.45);
        await ttsService.setVolume(0.8);
        await ttsService.speak(message['content']!);
      }
    }
  }

  Future<void> _checkAndRequestPermission() async {
    // Check microphone permission (important for speech recognition)
    PermissionStatus microphoneStatus = await Permission.microphone.status;
    if (microphoneStatus.isDenied) {
      microphoneStatus = await Permission.microphone.request();
    }

    if (microphoneStatus.isPermanentlyDenied) {
      setState(() {
        _errorMessage = "Microphone permission is permanently denied. Please enable it in settings.";
      });
      openAppSettings();
    } else {
      setState(() {
        _errorMessage = "Microphone permission is required to use this feature.";
      });
    }
  }

  void initializeTextToSpeech() async {
    try {
      final langSettings = langSetting[selectedLanguageCode];
      await ttsService.setLanguage(langSettings!);
      await ttsService.setFeminineVoiceIfAvailable();
      await ttsService.setSpeechRate(ttsService.platformBaseRate + 0.1);
      await ttsService.setPitch(1.45);
      await ttsService.setVolume(0.8);
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing text-to-speech: $e");
      }
    }
  }

  Future<bool> _checkConnectivity() async {
    return true; // We assume local connectivity for Ollama, but user might be offline. 
  }

  Future<void> getChatResponse(String message) async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    // Check connectivity - even for local Ollama, we need network stack (localhost)
    // but we can skip valid internet check if we want offline. 
    // However, if using emulator 10.0.2.2, it requires network.
    bool hasInternet = await _checkConnectivity();
    if (!hasInternet) {
      setState(() {
        _assistantResponse =
            "No connection. Please check your network and try again.";
        messages.add({'role': 'assistant', 'content': _assistantResponse});
        isLoading = false;
      });
      await ttsService.speak(_assistantResponse);
      return;
    }

    initializeTextToSpeech();

    try {
      // Detect if the message is in Hindi (both Devanagari and Romanized)
      bool isHindi = _isHindiText(message);
      
      // IMPORTANT: Set language code based on user's input language
      if (isHindi) {
        selectedLanguageCode = 'hi';
      } else {
        selectedLanguageCode = 'en';
      }

      // 1. Prepare Query for Backend (Translate to English if needed for RAG)
      String queryForBackend = message;
      if (isHindi) {
         try {
           var translation = await translator.translate(message, to: 'en');
           queryForBackend = translation.text;
         } catch (e) {
           if (kDebugMode) print("Translation error (Input): $e");
         }
      }

      // 2. Call Backend (RAG Logic)
      // The backend uses English knowledge base, so it returns English.
      String responseText = await _geminiService.generateResponse(queryForBackend);
      
      // 3. Process Response (Translate back to Hindi if needed)
      if (isHindi) {
         try {
           var translation = await translator.translate(responseText, to: 'hi');
           responseText = translation.text;
         } catch (e) {
           if (kDebugMode) print("Translation error (Output): $e");
         }
      }

      _assistantResponse = responseText;
    } catch (e) {
      String friendly = "I'm having trouble reaching the AI brain right now. Please check your connection.";
      if (kDebugMode) {
        print("Gemini Error: $e");
      }
      _assistantResponse = friendly;
    } finally {
      if (mounted) {
        setState(() {
          messages.add({'role': 'assistant', 'content': _assistantResponse});
          isLoading = false;
        });

        if (_assistantResponse.isNotEmpty) {
          try { await speechToTextInstance.stop(); } catch (_) {}
          await Future.delayed(const Duration(milliseconds: 200));
          
          final bool speakHindi = selectedLanguageCode == 'hi';
          try {
            final langToUse = speakHindi ? 'hi-IN' : (langSetting[selectedLanguageCode] ?? 'en-IN');
            await ttsService.setLanguage(langToUse);
            await Future.delayed(const Duration(milliseconds: 150));
            await ttsService.setFeminineVoiceIfAvailable();
            await Future.delayed(const Duration(milliseconds: 150));
          } catch (e) {
            if (kDebugMode) {
              print("TTS setup error: $e");
            }
          }
          // Start speaking but DO NOT await it, so we can listen for barge-in immediately
          // TtsService is configured to await completion, so using .then() lets us handle post-speech logic
          ttsService.speak(_assistantResponse.trim()).then((_) {
             // Logic to run after speech finishes successfully (if not interrupted)
             // We can ensure listening is active here too
          });
          
          // Restart wake-word listening PROACTIVELY to allow barge-in
          // We wait a brief moment for TTS to initialize
          Future.delayed(const Duration(milliseconds: 500), () async {
            if (mounted && !isRecording && !isLoading && !_isWakeWordListening) {
              if (kDebugMode) {
                print("Starting barge-in listener...");
              }
              _startWakeWordListening();
            }
          });
        }
      }
    }
  }

  // Helper method to check if response is complete
  bool _isResponseComplete(String response) {
    if (response.isEmpty) return false;
    final trimmed = response.trim();
    if (trimmed.isEmpty) return false;
    final lastChar = trimmed[trimmed.length - 1];
    if (lastChar == '.' || lastChar == '!' || lastChar == '?' || 
        lastChar == '।' || lastChar == '!' || lastChar == '?') {
      return true;
    }
    return true; // Default true for Ollama for now
  }

  // Helper method to detect Hindi text (both Devanagari and Romanized)
  bool _isHindiText(String text) {
    RegExp hindiRegex = RegExp(r'[\u0900-\u097F]');
    if (hindiRegex.hasMatch(text)) {
      return true;
    }
    
    final romanizedHindiWords = [
      'kaun', 'kahan', 'kab', 'kaise', 'kyun', 'hain', 'hai', 'hoga', 'hogi',
      'tum', 'aap', 'hum', 'unka', 'unke', 'uska', 'uski', 'mera', 'meri',
      'namaste', 'dhanyavad', 'shukriya', 'kripya', 'mujhe', 'tujhe', 'ko', 'se',
      'mein', 'tak', 'bhi', 'aur', 'lekin', 'magar', 'phir',
       'aaj', 'parson', 'pehle', 'baad', 'sab', 'sabse', 'kuch', 'koi'
    ];
    
    final lowerText = text.toLowerCase();
    for (final word in romanizedHindiWords) {
      if (lowerText.contains(word)) {
        return true;
      }
    }
    
    return false;
  }

  Future<String> detectLanguage(String text) async {
    try {
      var translation = await translator.translate(text, to: 'en');
      return translation.sourceLanguage.toString();
    } catch (e) {
      if (kDebugMode) {
        print("Error detecting language: $e");
      }
      return 'en';
    }
  }

  Future<void> translateText(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        errorMessage = "No speech detected. Please try again.";
        isLoading = false;
      });
      return;
    }

    try {
      if (_isHindiText(text)) {
        selectedLanguageCode = 'hi';
        setState(() {
          messages = List<Map<String, String>>.from(messages);
          messages.add({'role': 'user', 'content': text});
        });
        await getChatResponse(text.toLowerCase());
        _autoSaveConversation();
        return;
      }

      selectedLanguageCode = 'en';
      setState(() {
        messages = List<Map<String, String>>.from(messages);
        messages.add({'role': 'user', 'content': text});
      });

      await getChatResponse(text.toLowerCase());
      _autoSaveConversation();
    } catch (e) {
      if (kDebugMode) {
        print("Translation error: $e");
      }
      setState(() {
        errorMessage = "Translation error. Please try again.";
        isLoading = false;
      });
    }
  }

  void initializeSpeechToText() async {
    try {
      bool available = await speechToTextInstance.initialize(
        onError: (error) {
          if (kDebugMode) {
            print("Speech recognition error: ${error.errorMsg}");
          }
          
          // Fix for Samsung Tablets: Suppress timeout errors during wake word listening
          if (error.errorMsg == 'error_speech_timeout' || error.errorMsg == 'error_no_match') {
            if (_isWakeWordListening && !isRecording) {
               if (kDebugMode) print("Timeout detected. Restarting listener silently...");
               Future.delayed(const Duration(milliseconds: 100), () {
                 if (mounted) _startWakeWordListening();
               });
               return; // Skip showing error message
            }
          }

          if (mounted) {
            setState(() {
              errorMessage = "Speech recognition error: ${error.errorMsg}";
            });
          }
        },
        onStatus: (status) {
          if (kDebugMode) {
            print("Speech recognition status: $status");
          }
        },
      );

      if (kDebugMode) {
        print("Speech to text initialized: $available");
      }

      if (!available) {
        setState(() {
          errorMessage = "Speech recognition not available on this device";
        });
      }

      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing speech to text: $e");
      }
      setState(() {
        errorMessage = "Failed to initialize speech recognition";
      });
    }
  }

  void startListeningNow() async {
    FocusScope.of(context).unfocus();
    // Keep current TTS playing; do not force-stop on barge-in

    // Stop wake-word listening when manually starting
    if (_isWakeWordListening) {
      _stopWakeWordListening();
    }

    // Check if speech recognition is available
    if (!speechToTextInstance.isAvailable) {
      setState(() {
        errorMessage =
            "Speech recognition not available. Please restart the app.";
        isRecording = false;
      });
      return;
    }

    // Check microphone permission
    PermissionStatus microphoneStatus = await Permission.microphone.status;
    if (microphoneStatus.isDenied) {
      microphoneStatus = await Permission.microphone.request();
    }

    if (!microphoneStatus.isGranted) {
      setState(() {
        errorMessage =
            "Microphone permission is required for speech recognition.";
        isRecording = false;
      });
      return;
    }

    setState(() {
      recordedAudioString = "";
      isRecording = true;
      errorMessage = "";
      _isSilenceDetected = false;
      _silenceTimer?.cancel();
    });

    // Race condition check: If already checking or listening, stop first
    if (speechToTextInstance.isListening) {
      await speechToTextInstance.stop();
      // Brief delay to allow state cleanup
      await Future.delayed(const Duration(milliseconds: 50));
    }

    try {
      await speechToTextInstance.listen(
        onResult: onSpeechToTextResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
        onSoundLevelChange: (level) {
          setState(() {
            currentSoundLevel = level.clamp(0.0, 1.0);
          });

          if (kDebugMode && level > 1) {
            print("Sound level: $level");
          }

          if (level > 0.2) {
            // Lowered threshold for better sensitivity
            _silenceTimer?.cancel();
            _isSilenceDetected = false;
          } else if (!_isSilenceDetected) {
            _silenceTimer?.cancel();
            _silenceTimer = Timer(const Duration(seconds: 3), () {
              // Increased silence detection time
              if (kDebugMode) {
                print("Silence detected, stopping recording...");
              }

              if (recordedAudioString.isNotEmpty) {
                setState(() {
                  _isSilenceDetected = true;
                  isRecording = false;
                });
                stopListeningNow();
              }
            });
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print("Speech recognition error: $e");
      }
      setState(() {
        errorMessage = "Failed to start speech recognition. Please try again.";
        isRecording = false;
      });
    }
  }

  void stopListeningNow() async {
    await speechToTextInstance.stop();
    setState(() {
      isRecording = false;
      _isSilenceDetected = true;
      _silenceTimer?.cancel();
      currentSoundLevel = 0.0;
    });

    if (recordedAudioString.isEmpty) {
      setState(() {
        errorMessage = "No speech detected. Please try again.";
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            errorMessage = "";
          });
        }
      });
      // Restart wake-word listening if no speech detected
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && !isRecording && !isLoading && !_isWakeWordListening) {
          _startWakeWordListening();
        }
      });
    } else {
      await translateText(recordedAudioString);
      setState(() {
        recordedAudioString = '';
      });
    }
  }

  // Wake-word detection methods
  bool _checkForWakeWord(String text) {
    if (text.isEmpty) return false;
    
    String normalizedText = text.toLowerCase().trim();
    
    // Check if any wake word is contained in the text
    for (String wakeWord in _wakeWords) {
      if (normalizedText.contains(wakeWord)) {
        if (kDebugMode) {
          print("Wake word '$wakeWord' detected in: '$normalizedText'");
        }
        return true;
      }
    }
    
    return false;
  }

  Future<void> _startWakeWordListening() async {
    // If already recording user query or loading response, we usually don't want to restart wake word listening
    // UNLESS we want to support barge-in.
    // For barge-in, we need to allow wake word listening even if TTS is playing (though TTS usually requires mic focus).
    // Note: On many mobile devices, playing TTS and listening to Mic simultaneously is tricky (echo cancellation).
    
    if (_isWakeWordListening) return;
    if (isRecording) return; // Don't listen for wake word if already recording user input

    // Check if speech recognition is available
    if (!speechToTextInstance.isAvailable) {
      return;
    }

    // Check microphone permission
    PermissionStatus microphoneStatus = await Permission.microphone.status;
    if (microphoneStatus.isGranted) {
      setState(() {
        _isWakeWordListening = true;
        _wakeWordBuffer = "";
      });

      try {
        // Stop if already active to prevent state errors
        if (speechToTextInstance.isListening) {
           await speechToTextInstance.stop();
           await Future.delayed(const Duration(milliseconds: 50));
        }

        // Watchdog: Ensure listener is actually running
        _wakeWordWatchdog?.cancel();
        _wakeWordWatchdog = Timer.periodic(const Duration(seconds: 10), (timer) {
          if (!_isWakeWordListening) {
             timer.cancel();
             return;
          }
          if (!speechToTextInstance.isListening && !isRecording) {
            if (kDebugMode) print("Watchdog: Listener died, restarting...");
            _startWakeWordListening();
          }
        });

        await speechToTextInstance.listen(
          onResult: (result) async {
            if (_isWakeWordListening && !isRecording) {
              String text = result.recognizedWords.toLowerCase().trim();
              if (text.isNotEmpty) {
                _wakeWordBuffer = text;
                if (_checkForWakeWord(text)) {
                  // Check for STOP command specifically
                  if (text.contains('stop')) {
                     if (kDebugMode) print("Wake word: STOP detected");
                     await _stopWakeWordListening();
                     await ttsService.stop(); // Stop TTS
                     _safeRestartWakeWord(); // Just go back to listening
                     return;
                  }

                  // Wake word detected!
                  await _stopWakeWordListening(); // Stop detecting "Hello"
                  await ttsService.stop(); // Stop any previous speech
                   
                  // Play Greeting
                  await ttsService.setLanguage('en-IN');
                  await ttsService.setFeminineVoiceIfAvailable();
                  await ttsService.speak("Hello! I'm listening.");
                   
                  // Wait for greeting to finish (approx 1.5s)
                  await Future.delayed(const Duration(milliseconds: 1500));
                   
                  if (mounted && !isRecording) {
                    startListeningNow();
                  }
                }
              }
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 4), // Balanced pause duration
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
          onSoundLevelChange: (level) {},
        );
      } catch (e) {
        setState(() {
          _isWakeWordListening = false;
        });
        // Retry logic
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !isRecording && !isLoading && !_isWakeWordListening) {
            _startWakeWordListening();
          }
        });
      }
    }
  }

  void _safeRestartWakeWord() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !isRecording && !isLoading && !_isWakeWordListening) {
         if (kDebugMode) print("Restarting wake word listener...");
        _startWakeWordListening();
      }
    });
  }

  Future<void> _stopWakeWordListening() async {
    if (!_isWakeWordListening) return;
    
    try {
      await speechToTextInstance.stop();
    } catch (e) {
      if (kDebugMode) {
        print("Error stopping wake-word listening: $e");
      }
    }
    
    setState(() {
      _isWakeWordListening = false;
      _wakeWordBuffer = "";
    });
  }

  void onSpeechToTextResult(SpeechRecognitionResult recognitionResult) {
    // This handler is only for normal recording mode, not wake-word detection
    if (_isWakeWordListening) {
      return; 
    }
    
    setState(() {
      recordedAudioString = recognitionResult.recognizedWords;
    });

    if (recognitionResult.finalResult && recordedAudioString.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && isRecording) {
          stopListeningNow();
        }
      });
    }
  }

  void clear() async {
    setState(() {
      messages = List.from(dummyMessages);
      errorMessage = "";
    });
    // Do not stop TTS when clearing history
  }

  void _showSaveHistoryDialog() {
    if (messages.length <= dummyMessages.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No conversation to save yet!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    String initialTitle = 'Chat ';
    if (messages.length > dummyMessages.length) {
      initialTitle += messages[dummyMessages.length]['content']!
          .split(' ')
          .take(3)
          .join(' ');
      if (initialTitle.length > 30)
        initialTitle = initialTitle.substring(0, 30) + '...';
    }
    _saveHistoryController.text = initialTitle;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Conversation'),
        content: TextField(
          controller: _saveHistoryController,
          decoration: const InputDecoration(
            labelText: 'Chat Title',
            hintText: 'Enter a title for this conversation',
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              String title = _saveHistoryController.text.trim();
              if (title.isEmpty) {
                title = 'Chat ${DateTime.now().toString().substring(0, 16)}';
              }

              await _historyService.saveChatHistory(
                title,
                List<Map<String, String>>.from(messages),
              );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conversation saved to history!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Auto-save conversation when it gets long enough
  void _autoSaveConversation() async {
    // Only auto-save if there are meaningful conversations (more than 4 messages total)
    if (messages.length > dummyMessages.length + 4) {
      String title = 'Chat ${DateTime.now().toString().substring(0, 16)}';
      
      // Try to create a better title from the first user message
      if (messages.length > dummyMessages.length) {
        String firstUserMessage = messages[dummyMessages.length]['content'] ?? '';
        if (firstUserMessage.isNotEmpty) {
          List<String> words = firstUserMessage.split(' ').take(3).toList();
          if (words.isNotEmpty) {
            title = words.join(' ');
            if (title.length > 25) {
              title = title.substring(0, 25) + '...';
            }
          }
        }
      }
      
      await _historyService.saveChatHistory(
        title,
        List<Map<String, String>>.from(messages),
      );
    }
  }

  void _debugSpeechRecognitionStatus() async {
    // Check speech recognition status after a delay
    Future.delayed(const Duration(seconds: 2), () async {
      if (kDebugMode) {
        print(
            "Speech recognition available: ${speechToTextInstance.isAvailable}");
        print(
            "Speech recognition listening: ${speechToTextInstance.isListening}");

        // Check permissions
        PermissionStatus microphoneStatus = await Permission.microphone.status;
        print("Microphone permission: $microphoneStatus");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthService>(context);
    final appTheme = themeProvider.currentTheme;

    return SpaceScaffold(
      title: 'KIRA - UIT Assistant',
      floatingActionButton: !widget.isFromHistory
          ? FloatingActionButton(
              onPressed: _showSaveHistoryDialog,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.save, color: Colors.white),
              tooltip: 'Save Conversation',
            )
          : null,
      child: Stack(
          children: [
            // Universe elements
            if (appTheme.showSpaceElements) ...[
              ...List.generate(40, (index) {
                return AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    final starX = (index * 37) % screenWidth;
                    final starY = (index * 73) % screenHeight;
                    final starSize = (1.5 + (index % 4) * 1.2).clamp(0.5, 20.0);
                    final rawOpacity = 0.5 +
                        (sin(_particleAnimation.value + index) + 1) * 0.35;
                    final starOpacity = rawOpacity.clamp(0.0, 1.0);
                    return Positioned(
                      left: starX,
                      top: starY,
                      child: Container(
                        width: starSize,
                        height: starSize,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(starOpacity),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(
                                  (starOpacity * 0.7).clamp(0.0, 1.0)),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
              ...List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    final starX = (index * screenWidth / 3) + 60;
                    final starY = (index * screenHeight / 3) + 120;
                    final twinkle =
                        (0.7 + 0.3 * sin(_particleAnimation.value + index * 2))
                            .clamp(0.1, 2.0);
                    return Positioned(
                      left: starX,
                      top: starY,
                      child: Container(
                        width: 16 * twinkle,
                        height: 16 * twinkle,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity((0.8 * twinkle).clamp(0.0, 1.0)),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white
                                  .withOpacity((0.7 * twinkle).clamp(0.0, 1.0)),
                              blurRadius: 20,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
              ...List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    final lerpColor = Color.lerp(
                          [
                            const Color(0xFF4F46E5),
                            const Color(0xFF7C3AED),
                            const Color(0xFFEC4899)
                          ][index],
                          Colors.white,
                          (0.2 + 0.3 * sin(_waveAnimation.value + index))
                              .clamp(0.0, 1.0),
                        ) ??
                        Colors.white;
                    return Positioned(
                      left: (index * screenWidth / 3) +
                          (sin(_waveAnimation.value + index) * 50),
                      top: (index * 100) +
                          (cos(_waveAnimation.value + index) * 30),
                      child: Container(
                        width: 260,
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              lerpColor.withOpacity(0.22),
                              Colors.transparent,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
            // Rainbow elements
            if (appTheme.showRainbowElements) ...[
              // Animated rainbow background waves
              ...List.generate(5, (index) {
                return AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return Positioned(
                      left: 0,
                      top: screenHeight * 0.2 * index,
                      child: Container(
                        width: screenWidth,
                        height: screenHeight * 0.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.primaries[
                                  (index * 2) % Colors.primaries.length],
                              Colors.primaries[
                                  (index * 2 + 1) % Colors.primaries.length],
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
            // Main content
            Column(
                children: [
                  // Content area below SpaceScaffold header

                  // Error message with space theme
                  if (errorMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),

                  // Main chat area with space theme
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: messages.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Animated space-themed KYC text
                                        AnimatedBuilder(
                                          animation: _loadingAnimation,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: 1.0 +
                                                  (_loadingAnimation.value *
                                                      0.1),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(30),
                                                decoration: BoxDecoration(
                                                  gradient: RadialGradient(
                                                    colors: [
                                                      Colors.white
                                                          .withOpacity(0.1),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child:                                         const Text(
                                          'KIRA',
                                          style: TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 8,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(2, 2),
                                                blurRadius: 10,
                                                color: Colors.black26,
                                              ),
                                            ],
                                          ),
                                        ),
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 20),

                                        const Text(
                                          'Your AI Assistant for UIT Prayagraj!',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w300,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: [
                                      // Messages list
                                      Expanded(
                                        child: ListView.builder(
                                          padding: const EdgeInsets.all(16),
                                          itemCount: messages.length,
                                          itemBuilder: (context, index) {
                                            final message = messages[index];
                                            if (message['role'] ==
                                                'assistant') {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 12),
                                                child: AssistantMessage(
                                                  messageContent:
                                                      message['content']!,
                                                ),
                                              );
                                            } else {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 12),
                                                child: UserMessage(
                                                  messageContent:
                                                      message['content']!,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),

                                      // Loading indicator with space theme
                                      if (isLoading)
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Colors.white
                                                        .withOpacity(0.7),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              const Text(
                                                'AI is exploring the cosmos...',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom controls with animated space theme
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Animated voice button
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isRecording ? 1.1 : 1.0,
                              child: GestureDetector(
                                onTap: () {
                                  if (isRecording) {
                                    stopListeningNow();
                                  } else {
                                    startListeningNow();
                                  }
                                },
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isRecording
                                          ? [
                                              const Color(0xFF4F46E5),
                                              const Color(0xFF7C3AED),
                                            ]
                                          : [
                                              Colors.white.withOpacity(0.1),
                                              Colors.white.withOpacity(0.05),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(35),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isRecording
                                            ? const Color(0xFF4F46E5)
                                                .withOpacity(0.5)
                                            : Colors.white.withOpacity(0.1),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isRecording ? Icons.stop : Icons.mic,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Spacer to balance layout after removing camera button
                        const SizedBox(width: 70, height: 70),

                        // Animated delete button
                        AnimatedBuilder(
                          animation: _loadingController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_loadingAnimation.value * 0.05),
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.withOpacity(0.2),
                                      Colors.red.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(35),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.2),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.white),
                                  iconSize: 30,
                                  onPressed: clear,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            

            // Camera removed

            // Voice Ripple Animation (displayed on screen when recording)
            if (isRecording)
              Positioned.fill(
                child: Center(
                  child: VoiceRippleAnimation(
                    soundLevel: currentSoundLevel,
                    isActive: isRecording,
                    size: 300,
                    primaryColor: const Color(0xFF4F46E5),
                    secondaryColor: const Color.fromARGB(255, 166, 114, 255),
                  ),
                ),
              ),
          ],
        ),
      );
  }
}

// Wave painter for animated background
class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final double waveHeight;
  final Color waveColor;
  final double waveSpeed;

  WavePainter({
    required this.animation,
    required this.waveHeight,
    required this.waveColor,
    required this.waveSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final y = size.height * 0.5;
    path.moveTo(0, y);

    for (double x = 0; x <= size.width; x++) {
      path.lineTo(
        x,
        y +
            sin((x / size.width * 2 * pi) + (animation.value * waveSpeed)) *
                waveHeight,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}
