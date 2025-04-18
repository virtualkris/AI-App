import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import 'package:permission_handler/permission_handler.dart';  // Import permission_handler

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final SpeechService _speechService = SpeechService();
  final TtsService _ttsService = TtsService();

  @override
  void initState() {
    super.initState();
    _ttsService.initTts(); // TTS setup
    Future.microtask(() =>
        Provider.of<ChatProvider>(context, listen: false).loadChatHistory());
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ollama Chat'),
        actions: [
          IconButton(
            onPressed: () => chatProvider.clearChat(), // Clear messages
            icon: const Icon(Icons.delete_outline),
            tooltip: "Clear chat",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // Show newest at bottom
              padding: const EdgeInsets.all(12),
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                final message = chatProvider.messages[chatProvider.messages.length - 1 - index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Colors.blueGrey.shade200
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.text.isEmpty && !message.isUser ? '...' : message.text,
                      style: const TextStyle(fontSize: 16),
                      softWrap: true,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                // Speech-to-text (mic)
                IconButton(
                  icon: Icon(_speechService.isListening ? Icons.mic_off : Icons.mic),
                  onPressed: () async {
                    // Check if microphone permission is granted
                    var status = await Permission.microphone.status;
                    if (!status.isGranted) {
                      // Request permission if not granted
                      status = await Permission.microphone.request();
                      if (!status.isGranted) {
                        print('❌ Microphone permission denied');
                        return;
                      }
                    }

                    final available = await _speechService.initSpeech();
                    if (available) {
                      await _speechService.startListening((spokenText) {
                        setState(() {
                          _controller.text = spokenText;
                        });
                      });
                    }
                  },
                ),
                // Input field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(chatProvider),
                    decoration: const InputDecoration(hintText: 'Type your message...'),
                  ),
                ),
                // Text-to-speech (speaker)
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () {
                    final lastMessage = chatProvider.messages.isNotEmpty
                        ? chatProvider.messages.last.text
                        : '';
                    if (lastMessage.isNotEmpty) {
                      _ttsService.speak(lastMessage);
                    }
                  },
                ),
                // Send button
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _send(chatProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _send(ChatProvider provider) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    provider.sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
