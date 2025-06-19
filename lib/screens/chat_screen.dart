// lib/screens/chat_screen.dart (redesigned)
import 'dart:math';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:voice_chatbot_assistant/api_key.dart';
import 'package:voice_chatbot_assistant/components/pip_camera_box.dart';
import 'package:voice_chatbot_assistant/components/assistant_message.dart';
import 'package:voice_chatbot_assistant/components/user_message.dart';
import 'package:voice_chatbot_assistant/components/voice_wave_visualization.dart';
import 'package:voice_chatbot_assistant/components/voice_ripple_animation.dart';
import 'package:voice_chatbot_assistant/constant/languages.dart';
import 'package:voice_chatbot_assistant/constant/messages.dart';
import 'package:voice_chatbot_assistant/screens/tts.dart';
import 'package:voice_chatbot_assistant/models/chat_history.dart';
import 'package:voice_chatbot_assistant/services/chat_history_service.dart';
import 'package:voice_chatbot_assistant/screens/chat_history_screen.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:voice_chatbot_assistant/constant/theme_provider.dart';
import 'package:voice_chatbot_assistant/constant/theme.dart';

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

  String recordedAudioString = "";
  String translatedString = "";
  String detectedLanguage = "";
  Timer? _silenceTimer;
  bool _isSilenceDetected = false;
  bool _showCamera = false;
  Offset _cameraPosition = const Offset(100, 100);
  bool _isCameraAvailable = false;
  String _errorMessage = '';
  TextEditingController _saveHistoryController = TextEditingController();

  // Animation controllers
  late AnimationController _titleController;
  late AnimationController _loadingController;
  late AnimationController _waveController;
  late AnimationController _particleController;

  late Animation<double> _titleAnimation;
  late Animation<double> _loadingAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _particleAnimation;

  // Gemini Pro model instance
  late final GenerativeModel model;

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

    // Initialize Gemini model
    try {
      model = GenerativeModel(
        model: 'gemini-2.0-flash-thinking-exp-1219',
        apiKey: geminiApiKey,
      );
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing Gemini model: $e");
      }
      errorMessage = "Error initializing AI model. Please restart the app.";
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
    ttsService.stop();
    speechToTextInstance.stop();
    _saveHistoryController.dispose();
    super.dispose();
  }

  void speakDummyMessages() async {
    for (var message in messages) {
      if (message['role'] == 'assistant') {
        await ttsService.setLanguage('en-IN');
        await ttsService.setSpeechRate(0.5);
        await ttsService.setPitch(1.0);
        await ttsService.setVolume(0.8);
        await ttsService.speak(message['content']!);
      }
    }
  }

  Future<void> _checkAndRequestPermission() async {
    // Check camera permission
    PermissionStatus cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      cameraStatus = await Permission.camera.request();
    }

    // Check microphone permission (important for speech recognition)
    PermissionStatus microphoneStatus = await Permission.microphone.status;
    if (microphoneStatus.isDenied) {
      microphoneStatus = await Permission.microphone.request();
    }

    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      _checkCameraAvailability();
    } else if (cameraStatus.isPermanentlyDenied ||
        microphoneStatus.isPermanentlyDenied) {
      setState(() {
        _errorMessage =
            "Camera or microphone permission is permanently denied. Please enable it in settings.";
      });
      openAppSettings();
    } else {
      setState(() {
        _errorMessage =
            "Camera and microphone permissions are required to use this feature.";
      });
    }
  }

  Future<void> _checkCameraAvailability() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        setState(() {
          _isCameraAvailable = true;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _isCameraAvailable = false;
          _errorMessage = 'No camera available on this device.';
        });
      }
    } catch (e) {
      setState(() {
        _isCameraAvailable = false;
        _errorMessage = 'Failed to access the camera. Please try again.';
      });
    }
  }

  void initializeTextToSpeech() async {
    try {
      final langSettings = langSetting[selectedLanguageCode];
      await ttsService.setLanguage(langSettings!);
      await ttsService.setSpeechRate(0.5);
      await ttsService.setPitch(1.0);
      await ttsService.setVolume(0.8);
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing text-to-speech: $e");
      }
    }
  }

  Future<bool> _checkConnectivity() async {
    return true;
  }

  Future<void> getChatResponse(String message) async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    bool hasInternet = await _checkConnectivity();
    if (!hasInternet) {
      setState(() {
        _assistantResponse =
            "No internet connection. Please check your network and try again.";
        messages.add({'role': 'assistant', 'content': _assistantResponse});
        isLoading = false;
      });
      await ttsService.speak(_assistantResponse);
      return;
    }

    initializeTextToSpeech();

    try {
      // Detect if the message is in Hindi
      bool isHindi = _isHindiText(message);

      if (message.contains('ನಾನು ಒಂಟಿಯಾಗಿ') || message.contains('ಇಲ್ಲ')) {
        _assistantResponse = "ನಾನು ಇಲ್ಲಿದ್ದೇನೆ ನಿನಗಾಗಿ...";
      } else if (message.contains('sleepless') ||
          message.contains('feeling sleepless')) {
        _assistantResponse = "Hey, I've been observing you...";
      } else if (isHindi) {
        // Handle Hindi responses
        final prompt =
            "Respond in Hindi (हिंदी) with a friendly, conversational tone. "
            "Provide practical advice for: $message. "
            "Keep the response natural and helpful.";

        final response = await model
            .generateContent([Content.text(prompt)]).timeout(
                const Duration(seconds: 15), onTimeout: () {
          throw TimeoutException('API request timed out');
        });

        if (response.text != null && response.text!.isNotEmpty) {
          _assistantResponse = response.text!;
        } else {
          _assistantResponse =
              "माफ़ करें, मैं उत्तर नहीं दे पाया। कृपया फिर से कोशिश करें।";
        }
      } else {
        final prompt =
            "Respond in ${selectedLanguageCode.toUpperCase()} with a friendly, conversational tone. "
            "Provide practical advice for: $message";

        final response = await model
            .generateContent([Content.text(prompt)]).timeout(
                const Duration(seconds: 15), onTimeout: () {
          throw TimeoutException('API request timed out');
        });

        if (response.text != null && response.text!.isNotEmpty) {
          _assistantResponse = response.text!;
        } else {
          _assistantResponse = "Sorry, I couldn't generate a response.";
        }
      }
    } catch (e) {
      _assistantResponse = 'Error fetching response. Please try again.';
      if (kDebugMode) {
        print("Gemini API Error: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          messages.add({'role': 'assistant', 'content': _assistantResponse});
          isLoading = false;
        });

        if (_assistantResponse.isNotEmpty) {
          await ttsService.speak(_assistantResponse);
        }
      }
    }
  }

  // Helper method to detect Hindi text
  bool _isHindiText(String text) {
    // Check for Hindi characters (Devanagari script)
    RegExp hindiRegex = RegExp(r'[\u0900-\u097F]');
    return hindiRegex.hasMatch(text);
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
      // Check if text is in Hindi first
      if (_isHindiText(text)) {
        selectedLanguageCode = 'hi';
        setState(() {
          messages = List<Map<String, String>>.from(messages);
          messages.add({'role': 'user', 'content': text});
        });
        await getChatResponse(text.toLowerCase());
        return;
      }

      String detectedLang = await detectLanguage(text);
      if (kDebugMode) {
        print("Detected Language: $detectedLang");
      }

      bool languageFound = false;
      for (var lang in languages) {
        if (lang['name']!.toLowerCase() == detectedLang.toLowerCase()) {
          selectedLanguageCode = lang['code']!;
          languageFound = true;
          break;
        }
      }

      if (!languageFound) {
        selectedLanguageCode = 'en';
      }

      setState(() {
        messages = List<Map<String, String>>.from(messages);
        messages.add({'role': 'user', 'content': text});
      });

      await getChatResponse(text.toLowerCase());
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
            print("Speech recognition error: $error");
          }
          setState(() {
            errorMessage = "Speech recognition error: ${error.errorMsg}";
          });
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
    } else {
      await translateText(recordedAudioString);
      setState(() {
        recordedAudioString = '';
      });
    }
  }

  void onSpeechToTextResult(SpeechRecognitionResult recognitionResult) {
    setState(() {
      recordedAudioString = recognitionResult.recognizedWords;
    });

    if (kDebugMode) {
      print("Speech Result: $recordedAudioString");
      print("Final: ${recognitionResult.finalResult}");
    }

    // If we have a final result and it's not empty, process it
    if (recognitionResult.finalResult && recordedAudioString.isNotEmpty) {
      // Small delay to ensure the result is fully processed
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
    await ttsService.stop();
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
    final appTheme = themeProvider.currentTheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: appTheme.buttonColor,
        child: const Icon(Icons.color_lens, color: Colors.white),
        onPressed: () async {
          // Show theme switcher dialog
          final selected = await showDialog<ThemeType>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Choose Theme'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: AppThemes.all
                    .map((theme) => ListTile(
                          leading: Icon(
                            theme.type == ThemeType.universe
                                ? Icons.public
                                : theme.type == ThemeType.rainbow
                                    ? Icons.gradient
                                    : Icons.blur_on,
                            color: theme.primary,
                          ),
                          title: Text(theme.name),
                          trailing: themeProvider.currentType == theme.type
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () => Navigator.pop(context, theme.type),
                        ))
                    .toList(),
              ),
            ),
          );
          if (selected != null) {
            themeProvider.setTheme(selected);
          }
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: appTheme.gradient,
          ),
        ),
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
            SafeArea(
              child: Column(
                children: [
                  // Top bar with space theme
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button with space theme
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),

                        // Title with space theme
                        AnimatedBuilder(
                          animation: _titleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _titleAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'KYC Universe',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Action buttons with space theme
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.history,
                                    color: Colors.white),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (!widget.isFromHistory) ...[
                              const SizedBox(width: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.save,
                                      color: Colors.white),
                                  onPressed: _showSaveHistoryDialog,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

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
                                                child: const Text(
                                                  'KYC',
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
                                          'Explore the Universe of Knowledge!',
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

                        // Animated camera button
                        AnimatedBuilder(
                          animation: _particleController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: sin(_particleAnimation.value) * 0.1,
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
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
                                      color: Colors.white.withOpacity(0.1),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.camera_alt_rounded,
                                      color: Colors.white),
                                  iconSize: 30,
                                  onPressed: () async {
                                    if (_isCameraAvailable) {
                                      setState(() {
                                        _showCamera = !_showCamera;
                                      });
                                    } else {
                                      await _checkAndRequestPermission();
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),

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
            ),

            // PiP Camera
            if (_showCamera && _isCameraAvailable)
              Positioned(
                left: _cameraPosition.dx,
                top: _cameraPosition.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _cameraPosition += details.delta;
                    });
                  },
                  child: Container(
                    width: 200,
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: const PiPCameraScreen(),
                    ),
                  ),
                ),
              ),

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
