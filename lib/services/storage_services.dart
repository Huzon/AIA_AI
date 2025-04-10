import 'dart:convert';

import 'package:aia/models/chat_message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  Future<void> saveSessions(
    Map<String, List<ChatMessage>> sessions,
    String currentKey,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('session_keys', sessions.keys.toList());

    for (final key in sessions.keys) {
      final sessionJson =
          sessions[key]!.map((msg) => jsonEncode(msg.toMap())).toList();
      await prefs.setStringList(key, sessionJson);
    }
  }

  Future<void> loadSessions(Map<String, List<ChatMessage>> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList('session_keys') ?? [];

    for (final key in keys) {
      final chatJson = prefs.getStringList(key) ?? [];
      sessions[key] =
          chatJson
              .map((item) => ChatMessage.fromMap(jsonDecode(item)))
              .toList();
    }
  }
}

final storageServiceProvider = Provider((ref) => StorageService());
