// lib/services/chat_history_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_history.dart';

class ChatHistoryService {
  static const String _storageKey = 'chat_history';
  final Uuid _uuid = const Uuid();

  // Get all chat histories
  Future<List<ChatHistory>> getAllChatHistories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? chatHistoryJson = prefs.getString(_storageKey);

    if (chatHistoryJson == null) {
      return [];
    }

    List<dynamic> historiesMap = jsonDecode(chatHistoryJson);
    return historiesMap
        .map((history) => ChatHistory.fromMap(history))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by newest first
  }

  // Save a new chat history
  Future<void> saveChatHistory(String title, List<Map<String, String>> messages) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<ChatHistory> histories = await getAllChatHistories();

    final ChatHistory newHistory = ChatHistory(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      title: title,
      messages: messages,
    );

    histories.add(newHistory);

    await prefs.setString(
      _storageKey,
      jsonEncode(histories.map((history) => history.toMap()).toList()),
    );
  }

  // Delete a chat history
  Future<void> deleteChatHistory(String id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<ChatHistory> histories = await getAllChatHistories();

    histories.removeWhere((history) => history.id == id);

    await prefs.setString(
      _storageKey,
      jsonEncode(histories.map((history) => history.toMap()).toList()),
    );
  }

  // Get a specific chat history
  Future<ChatHistory?> getChatHistory(String id) async {
    final List<ChatHistory> histories = await getAllChatHistories();
    try {
      return histories.firstWhere((history) => history.id == id);
    } catch (e) {
      return null;
    }
  }
}
