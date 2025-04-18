import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/message.dart';

class StorageService {
  static const _fileName = 'chat_history.json';

  /// Get the full path to the saved file
  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Save messages to file
  static Future<void> saveMessages(List<Message> messages) async {
    final file = await _getFile();
    final jsonData = messages.map((m) => m.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonData));
  }

  /// Load messages from file
  static Future<List<Message>> loadMessages() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];

      final contents = await file.readAsString();
      final data = jsonDecode(contents) as List;
      return data.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete chat history
  static Future<void> clearMessages() async {
    final file = await _getFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
