import 'package:flutter/material.dart';
import 'package:voice_chatbot_assistant/models/chat_history.dart';
import 'package:voice_chatbot_assistant/services/chat_history_service.dart';
import 'package:voice_chatbot_assistant/screens/chat_screen.dart';
import 'dart:math' as math;

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen>
    with TickerProviderStateMixin {
  final ChatHistoryService _historyService = ChatHistoryService();
  List<ChatHistory> chatHistories = [];
  bool isLoading = true;

  // Animation controllers
  late AnimationController _titleController;
  late AnimationController _listController;
  late AnimationController _particleController;

  late Animation<double> _titleAnimation;
  late Animation<double> _listAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadChatHistories();
  }

  void _initializeAnimations() {
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _listAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listController,
      curve: Curves.easeInOut,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    _titleController.forward();
    _listController.forward();
    _particleController.repeat();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _listController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistories() async {
    final histories = await _historyService.getAllChatHistories();
    setState(() {
      chatHistories = histories;
      isLoading = false;
    });
  }

  Future<void> _deleteChatHistory(ChatHistory history) async {
    await _historyService.deleteChatHistory(history.id!);
    await _loadChatHistories();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4F46E5),
              Color(0xFF7C3AED),
              Color(0xFFEC4899),
              Color(0xFFF59E0B),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background waves (matching profile screen)
            ...List.generate(5, (index) {
              return AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(screenWidth, screenHeight),
                    painter: WavePainter(
                      animation: _particleAnimation,
                      waveHeight: 30 + (index * 15),
                      waveColor:
                          Colors.white.withOpacity(0.05 - (index * 0.01)),
                      waveSpeed: 1.0 + (index * 0.2),
                    ),
                  );
                },
              );
            }),

            SafeArea(
              child: Column(
                children: [
                  // Modern app bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    child: Row(
                      children: [
                        // Back button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Animated KYC title
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _titleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _titleAnimation.value,
                                child: const Text(
                                  'KYC',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 4,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(2, 2),
                                        blurRadius: 10,
                                        color: Colors.black26,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Subtitle
                        const Text(
                          'History',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main content
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _listAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - _listAnimation.value)),
                          child: Opacity(
                            opacity: _listAnimation.value,
                            child: Container(
                              margin: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : chatHistories.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.history,
                                                size: 80,
                                                color: Colors.white
                                                    .withOpacity(0.5),
                                              ),
                                              const SizedBox(height: 20),
                                              const Text(
                                                'No chat history yet',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              const Text(
                                                'Your conversations will appear here',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white54,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.all(16),
                                          itemCount: chatHistories.length,
                                          itemBuilder: (context, index) {
                                            final history =
                                                chatHistories[index];
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 12),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  width: 1,
                                                ),
                                              ),
                                              child: ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 12,
                                                ),
                                                leading: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF4F46E5)
                                                            .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                  ),
                                                  child: const Icon(
                                                    Icons.chat_bubble_outline,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                ),
                                                title: Text(
                                                  history.title,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  '${history.messages.length} messages',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                trailing: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    // Open button
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                                0xFF4F46E5)
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: IconButton(
                                                        icon: const Icon(
                                                          Icons.open_in_new,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (context) =>
                                                                      ChatScreen(
                                                                chatHistory:
                                                                    history,
                                                                isFromHistory:
                                                                    true,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),

                                                    const SizedBox(width: 8),

                                                    // Delete button
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.red
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: IconButton(
                                                        icon: const Icon(
                                                          Icons.delete_outline,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (context) =>
                                                                    AlertDialog(
                                                              backgroundColor:
                                                                  const Color(
                                                                      0xFF1E293B),
                                                              title: const Text(
                                                                'Delete Chat',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                              content: Text(
                                                                'Are you sure you want to delete "${history.title}"?',
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .white70),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          context),
                                                                  child:
                                                                      const Text(
                                                                    'Cancel',
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white70),
                                                                  ),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed:
                                                                      () {
                                                                    _deleteChatHistory(
                                                                        history);
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red,
                                                                    foregroundColor:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                  child: const Text(
                                                                      'Delete'),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
            math.sin((x / size.width * 2 * math.pi) +
                    (animation.value * waveSpeed)) *
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
