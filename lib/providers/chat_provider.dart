import 'package:aia/models/chat_message.dart';
import 'package:aia/services/gimini_services.dart';
import 'package:aia/services/storage_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final GeminiService _geminiService;
  final StorageService _storageService;
  List<String> get sessionKeys => _sessions.keys.toList();
  String get currentSessionKey => _currentSessionKey;
  final Map<String, List<ChatMessage>> _sessions = {};
  String _currentSessionKey = 'default_session';

  ChatNotifier(this._geminiService, this._storageService) : super([]) {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    await _storageService.loadSessions(_sessions);
    state = _sessions[_currentSessionKey] ?? [];
  }

  Future<void> _saveSessions() async {
    await _storageService.saveSessions(_sessions, _currentSessionKey);
  }

  void switchSession(String sessionKey) {
    _currentSessionKey = sessionKey;
    state = _sessions[sessionKey] ?? [];
  }

  void startNewSession() {
    _currentSessionKey = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _sessions[_currentSessionKey] = [];
    state = [];
    _saveSessions();
  }

  Future<void> sendMessage(String message) async {
    // Add user message
    final userMessage = ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _addMessage(userMessage);

    // Add loading indicator
    final loadingMessage = ChatMessage(
      text: '...',
      isUser: false,
      isLoading: true,
      timestamp: DateTime.now(),
    );
    _addMessage(loadingMessage);

    // Get response
    final reply = await _geminiService.getResponse(state);

    // Remove loading and add response
    state = state.where((msg) => !msg.isLoading).toList();
    final botMessage = ChatMessage(
      text: reply,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _addMessage(botMessage);
  }

  void _addMessage(ChatMessage message) {
    _sessions[_currentSessionKey] = [...state, message];
    state = [...state, message];
    _saveSessions();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((
  ref,
) {
  final geminiService = ref.read(geminiServiceProvider);
  final storageService = ref.read(storageServiceProvider);
  return ChatNotifier(geminiService, storageService);
});
