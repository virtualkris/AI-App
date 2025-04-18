import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/storage_service.dart';

class ChatProvider with ChangeNotifier {
  final List<Message> _messages = []; // In-memory chat history

  List<Message> get messages => _messages; // Expose read-only list

  final _uuid = const Uuid();

  /// Loads previous chat messages from local storage
  Future<void> loadChatHistory() async {
    final savedMessages = await StorageService.loadMessages();
    _messages.clear();
    _messages.addAll(savedMessages);
    notifyListeners(); // Refresh UI
  }

  /// Clears the current chat history
  Future<void> clearChat() async {
    _messages.clear();
    await StorageService.clearMessages();
    notifyListeners(); // Refresh UI
  }

  /// Adds a user message and sends it to Ollama
  Future<void> sendMessage(String userInput) async {
    if (userInput
        .trim()
        .isEmpty) return;

    final userMsg = Message(
      id: _uuid.v4(),
      text: userInput,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);
    notifyListeners();
    await StorageService.saveMessages(_messages);

    // Create empty AI message and add it now for live updates
    final aiMsg = Message(
      id: _uuid.v4(),
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(aiMsg);
    notifyListeners();

    await _streamAIResponse(userInput, aiMsg);
    await StorageService.saveMessages(_messages);
  }

  /// Sends the user's message to Ollama and returns the AI's response
  Future<void> _streamAIResponse(String prompt, Message aiMsg) async {
    final client = http.Client();

    try {
      final request = http.Request(
        'POST',
        Uri.parse('http://192.168.1.17:11434/api/generate'),
      );

      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        "model": "llama3",
        "prompt": prompt,
        "stream": true
      });

      final response = await client.send(request);

      final stream = response.stream.transform(utf8.decoder);
      await for (final chunk in stream) {
        for (final line in LineSplitter.split(chunk)) {
          if (line
              .trim()
              .isEmpty) continue;

          final jsonData = jsonDecode(line);
          if (jsonData.containsKey('response')) {
            aiMsg.text += jsonData['response'];
            notifyListeners(); // update UI as text comes in
          }
        }
      }
    } catch (e) {
      aiMsg.text = '[Error streaming from Ollama]';
      notifyListeners();
    } finally {
      client.close();
    }
  }
}
