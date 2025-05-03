// lib/screens/chat_screen.dart (corrected)
import 'dart:math';
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
import 'package:voice_chatbot_assistant/constant/languages.dart';
import 'package:voice_chatbot_assistant/constant/messages.dart';
import 'package:voice_chatbot_assistant/screens/tts.dart';
import 'package:voice_chatbot_assistant/models/chat_history.dart';
import 'package:voice_chatbot_assistant/services/chat_history_service.dart';
import 'package:voice_chatbot_assistant/screens/chat_history_screen.dart';
import 'dart:async';

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

class _ChatScreenState extends State<ChatScreen> {
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

  // Gemini Pro model instance
  late final GenerativeModel model;

  List<Map<String, String>> messages = [];
  bool isLoading = false;
  bool isRecording = false;

  String selectedLanguageCode = 'en';
  List<Map<String, String>> languages = language;
  Map<String, Map<String, String>> voiceSettings = voiceSetting;

  var _assistantResponse = "";
  String errorMessage = "";

  @override
  void initState() {
    super.initState();

    // Initialize messages from history or use dummy messages
    if (widget.chatHistory != null && widget.isFromHistory) {
      messages = List<Map<String, String>>.from(widget.chatHistory!.messages);
    } else {
      messages = List.from(dummyMessages);
    }

    // Initialize Gemini model
    try {
      model = GenerativeModel(
        model: 'gemini-2.0-flash-thinking-exp-1219', // Updated model name
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
  }

  void speakDummyMessages() async {
    for (var message in messages) {
      if (message['role'] == 'assistant') {
        await ttsService.setLanguage('en-IN');
        // await ttsService.setVoice(voiceSettings['en']!);
        await ttsService.setSpeechRate(
            0.4 + Random().nextDouble() * 5.5); // Adjust speech rate if needed
        await ttsService
            .setPitch(2.3 + Random().nextDouble() * 0.4); // Adjust pitch
        await ttsService.setVolume(2.0);
        await ttsService.speak(message['content']!);
      }
    }
  }

  Future<void> _checkAndRequestPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isDenied) {
      // Request permission if denied
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      // If permission is granted, check for camera availability
      _checkCameraAvailability();
    } else if (status.isPermanentlyDenied) {
      // If permission is permanently denied, show error
      setState(() {
        _errorMessage =
            "Camera permission is permanently denied. Please enable it in settings.";
      });
      openAppSettings(); // Direct user to app settings if permission is permanently denied
    } else {
      // Handle other permission states (denied, restricted, etc.)
      setState(() {
        _errorMessage = "Camera permission is required to use this feature.";
      });
    }
  }

  Future<void> _checkCameraAvailability() async {
    try {
      final cameras = await availableCameras(); // Check available cameras
      if (cameras.isNotEmpty) {
        setState(() {
          _isCameraAvailable = true; // Camera is available
          _errorMessage = ''; // Clear error message if camera is available
        });
      } else {
        setState(() {
          _isCameraAvailable = false; // No camera available
          _errorMessage = 'No camera available on this device.';
        });
      }
    } catch (e) {
      setState(() {
        _isCameraAvailable =
            false; // Error handling in case camera access fails
        _errorMessage = 'Failed to access the camera. Please try again.';
      });
    }
  }

  // Initialize text-to-speech and log available voices
  void initializeTextToSpeech() async {
    try {
      // Get the voice settings for the selected language
      final langSettings = langSetting[selectedLanguageCode];
      // Set the language, speech rate, pitch, and volume for the selected language
      await ttsService.setLanguage(langSettings!);
      await ttsService.setSpeechRate(0.9); // Adjust speech rate if needed
      await ttsService.setPitch(1.1); // Adjust pitch
      await ttsService.setVolume(1.0); // Adjust volume
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing text-to-speech: $e");
      }
    }
  }

  Future<bool> _checkConnectivity() async {
    // Simple connectivity check - you may need to add the connectivity_plus package
    // For now, we'll just return true to avoid adding a new dependency
    return true;
  }

  Future<void> getChatResponse(String message) async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    // Check connectivity before making API call
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

    // Add timeout to prevent indefinite loading
    try {
      // Custom hardcoded responses
      if (message.contains('ನಾನು ಒಂಟಿಯಾಗಿ') || message.contains('ಇಲ್ಲ')) {
        _assistantResponse = "ನಾನು ಇಲ್ಲಿದ್ದೇನೆ ನಿನಗಾಗಿ...";
      } else if (message.contains('sleepless') ||
          message.contains('feeling sleepless')) {
        _assistantResponse = "Hey, I've been observing you...";
      } else {
        // Gemini API call with timeout
        final prompt =
            "Respond in ${selectedLanguageCode.toUpperCase()} with a friendly, conversational tone. "
            "Provide practical advice for: $message";

        // Add timeout to prevent indefinite loading
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
      // Ensure loading state is always updated
      if (mounted) {
        setState(() {
          messages.add({'role': 'assistant', 'content': _assistantResponse});
          isLoading = false;
        });

        // Only speak if there's content to speak
        if (_assistantResponse.isNotEmpty) {
          await ttsService.speak(_assistantResponse);
        }
      }
    }
  }

  Future<String> detectLanguage(String text) async {
    try {
      // Translate the text to a known language (e.g., English) to infer the source language
      var translation = await translator.translate(text, to: 'en');
      // If the text is not in English, the source language is detected by translation
      return translation.sourceLanguage
          .toString(); // This will give you the detected language
    } catch (e) {
      if (kDebugMode) {
        print("Error detecting language: $e");
      }
      return 'en'; // Default to English on error
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
      // First, detect the language
      String detectedLang = await detectLanguage(text);
      if (kDebugMode) {
        print("Detected Language: $detectedLang");
      }

      // Set the language code based on detection
      bool languageFound = false;
      for (var lang in languages) {
        if (lang['name']!.toLowerCase() == detectedLang.toLowerCase()) {
          selectedLanguageCode = lang['code']!;
          languageFound = true;
          break;
        }
      }

      if (!languageFound) {
        selectedLanguageCode = 'en'; // Default to English if not found
      }

      // Update UI with user message immediately
      setState(() {
        messages = List<Map<String, String>>.from(messages);
        messages.add({'role': 'user', 'content': text});
      });

      // Process the response based on detected language
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
      bool available = await speechToTextInstance.initialize();
      if (kDebugMode) {
        print("Speech to text initialized: $available");
      }
      setState(() {});
    } catch (e) {
      if (kDebugMode) {
        print("Error initializing speech to text: $e");
      }
    }
  }

  void startListeningNow() async {
    FocusScope.of(context).unfocus();
    setState(() {
      recordedAudioString = ""; // Clear previous recordings
      isRecording = true;
      errorMessage = "";
      _isSilenceDetected = false;
      _silenceTimer?.cancel();
    });

    try {
      await speechToTextInstance.listen(
        onResult: onSpeechToTextResult,
        listenFor: const Duration(seconds: 30), // Increased from 15
        pauseFor: const Duration(seconds: 3), // Reduced from 10
        onSoundLevelChange: (level) {
          // Debug logging
          if (kDebugMode && level > 1) {
            print("Sound level: $level");
          }

          // Sound threshold logic improvement
          if (level > 0.3) {
            // Lower threshold to be more sensitive
            _silenceTimer?.cancel();
            _isSilenceDetected = false;
          } else if (!_isSilenceDetected) {
            _silenceTimer?.cancel();
            _silenceTimer = Timer(const Duration(seconds: 2), () {
              if (kDebugMode) {
                print("Silence detected, stopping recording...");
              }

              // Only stop if we have some recorded text
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
        errorMessage = "Failed to start speech recognition";
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
    });

    if (recordedAudioString.isEmpty) {
      setState(() {
        errorMessage =
            "No speech detected. Please try again."; // Show error if no speech
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
    }
  }

  void clear() async {
    setState(() {
      messages = List.from(dummyMessages);
      errorMessage = "";
    });
    await ttsService.stop();
  }

  // Show dialog to save current chat as history
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

    // Set initial title based on conversation
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

  @override
  void dispose() {
    // Clean up resources
    _silenceTimer?.cancel();
    ttsService.stop();
    speechToTextInstance.stop();
    _saveHistoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chat"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/homeScreen');
          },
        ),
        actions: [
          // History button
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatHistoryScreen(),
                ),
              );
            },
          ),
          // Save button
          if (!widget.isFromHistory)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _showSaveHistoryDialog,
            ),
        ],
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (errorMessage.isNotEmpty) // Show error if exists
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Start a conversation!',
                          style: TextStyle(fontSize: 18, color: Colors.blue),
                        ),
                      )
                    : Expanded(
                        child: Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 1.0),
                              child: Image.asset(
                                'images/botImage.png',
                                height: 160,
                                width: 160,
                              ),
                            ),
                            Flexible(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: messages.map((message) {
                                            if (message['role'] ==
                                                'assistant') {
                                              return Column(
                                                children: [
                                                  AssistantMessage(
                                                    messageContent:
                                                        message['content']!,
                                                  ),
                                                  const SizedBox(height: 2),
                                                ],
                                              );
                                            } else {
                                              return UserMessage(
                                                messageContent:
                                                    message['content']!,
                                              );
                                            }
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                    if (isLoading)
                                      const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    // Add debug info for speech recognition
                                    if (kDebugMode && isRecording)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "Recording: $recordedAudioString\nLanguage: $selectedLanguageCode",
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (isRecording) {
                            stopListeningNow();
                          } else {
                            startListeningNow();
                          }
                        },
                        child: Image.asset(
                          isRecording
                              ? 'images/recordingLogo.gif'
                              : 'images/recordingIcon.png',
                          height: 60,
                          width: 60,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt_rounded),
                        iconSize: 40,
                        color: Colors.blueAccent,
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
                      IconButton(
                        icon: const Icon(Icons.delete),
                        iconSize: 40,
                        color: Colors.redAccent,
                        onPressed: clear,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                child: const SizedBox(
                  width: 200,
                  height: 150,
                  child: PiPCameraScreen(),
                ),
              ),
            ),
          if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
