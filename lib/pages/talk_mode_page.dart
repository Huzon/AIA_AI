import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aia/pages/chat_page.dart';
import 'package:aia/services/stt_services.dart';
import 'package:aia/services/tts_services.dart';
import 'package:aia/providers/chat_provider.dart';

class TalkModePage extends ConsumerStatefulWidget {
  const TalkModePage({super.key});

  @override
  ConsumerState<TalkModePage> createState() => _TalkModePageState();
}

class _TalkModePageState extends ConsumerState<TalkModePage> {
  bool _isListening = false;
  bool _isBotSpeaking = false;
  String _spokenText = '';
  Timer? _silenceTimer;
  final _silenceTimeout = const Duration(seconds: 2);
  final List<Map<String, dynamic>> _conversation = [];
  late final TTSService ttsService;
  late final STTService sttService;

  @override
  void initState() {
    super.initState();
    ttsService = ref.read(ttsServiceProvider);
    sttService = ref.read(sttServiceProvider);
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    ttsService.stop();
    sttService.stopListening();
    super.dispose();
  }

  Future<void> _processUserInput() async {
    if (_spokenText.isEmpty) return;
    _updateConversation(_spokenText, true);
    _spokenText = '';
    _isListening = false;

    await ref
        .read(chatProvider.notifier)
        .sendMessage(_conversation.last['text']);
    final messages = ref.read(chatProvider);

    if (messages.isNotEmpty && !messages.last.isUser) {
      final botResponse = messages.last.text;
      _updateConversation(botResponse, false);
      _isBotSpeaking = true;
      await ttsService.speak(botResponse);
      _isBotSpeaking = false;
      if (mounted) await _startListening();
    }
    if (mounted) setState(() {});
  }

  void _updateConversation(String text, bool isUser) {
    _conversation.add({
      'text': text,
      'isUser': isUser,
      'timestamp': DateTime.now(),
    });
  }

  Future<void> _startListening() async {
    if (!await Permission.microphone.request().isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required.')),
        );
      }
      return;
    }

    if (!await sttService.initSTT()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
      }
      return;
    }

    _isListening = true;
    if (mounted) setState(() {});

    sttService.startListening((text) {
      _spokenText = text;
      _silenceTimer?.cancel();
      _silenceTimer = Timer(_silenceTimeout, _processUserInput);
      if (mounted) setState(() {});
    });
  }

  Future<void> _stopListening() async {
    _silenceTimer?.cancel();
    _isListening = false;
    sttService.stopListening();
    await _processUserInput();
    if (mounted) setState(() {});
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else if (!_isBotSpeaking) {
      await _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talk Mode'),
        backgroundColor: const Color(0xFF000910),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed:
                () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatPage()),
                ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/female_ai_silhouette_bright.png',
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: _conversation.length,
                  itemBuilder: (context, index) {
                    final message = _conversation.reversed.toList()[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              if (_spokenText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _spokenText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              _buildMicSection(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    return Align(
      alignment:
          message['isUser'] ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              message['isUser']
                  ? Colors.blue.withAlpha(190)
                  : Colors.grey.withAlpha(190),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft:
                message['isUser'] ? const Radius.circular(12) : Radius.zero,
            bottomRight:
                message['isUser'] ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                message['text'],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (!message['isUser'])
              IconButton(
                icon: const Icon(Icons.volume_up, size: 20),
                color: Colors.white,
                onPressed: () async {
                  await ttsService.speak(message['text']);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicSection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isBotSpeaking)
            const Text(
              'AI is speaking...',
              style: TextStyle(color: Colors.white),
            ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isListening ? 120 : 100,
              height: _isListening ? 120 : 100,
              decoration: BoxDecoration(
                color:
                    _isListening
                        ? Colors.red
                        : _isBotSpeaking
                        ? Colors.grey
                        : Colors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(32),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isListening
                ? 'Listening...'
                : _isBotSpeaking
                ? 'AI is responding...'
                : 'Tap to speak',
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
