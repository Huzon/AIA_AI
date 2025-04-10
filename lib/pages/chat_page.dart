import 'package:aia/elements/drawer.dart';
import 'package:aia/models/chat_message.dart';
import 'package:aia/pages/talk_mode_page.dart';
import 'package:aia/services/tts_services.dart';
import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../providers/chat_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, bool> _speakingStates = {};
  late final TTSService ttsService;
  @override
  void initState() {
    super.initState();
    ttsService = ref.read(ttsServiceProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    // Stop any ongoing speech when leaving the page
    ttsService.stop();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    await ref.read(chatProvider.notifier).sendMessage(text);

    // Speak the last bot response
    final messages = ref.read(chatProvider);
    if (messages.isNotEmpty && !messages.last.isUser) {
      await ttsService.speak(messages.last.text);
    }
  }

  void _toggleMessageSpeech(ChatMessage msg) async {
    final tts = ttsService;
    final isSpeaking = _speakingStates[msg.id] ?? false;

    if (isSpeaking) {
      await tts.stop();
    } else {
      await tts.speak(msg.text);
    }

    setState(() => _speakingStates[msg.id] = !isSpeaking);
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final chatMessages = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 9, 16),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              chatNotifier.startNewSession();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New session started!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TalkModePage()),
                ),
          ),
        ],
      ),
      drawer: AppDrawer(chatNotifier: chatNotifier),
      body: Stack(
        children: [
          _buildBackgroundImage(),
          SafeArea(child: _buildChatContent(chatMessages)),
        ],
      ),
    );
  }

  // Widget _buildSessionDrawer(ChatNotifier chatNotifier) {
  //   return Drawer(
  //     child: ListView(
  //       children: [
  //         const DrawerHeader(
  //           decoration: BoxDecoration(color: Colors.deepPurple),
  //           child: Text(
  //             'Chat Sessions',
  //             style: TextStyle(color: Colors.white, fontSize: 24),
  //           ),
  //         ),
  //         ...chatNotifier.sessionKeys.map(
  //           (sessionKey) => ListTile(
  //             title: Text(
  //               sessionKey,
  //               maxLines: 1,
  //               overflow: TextOverflow.ellipsis,
  //             ),
  //             trailing:
  //                 sessionKey == chatNotifier.currentSessionKey
  //                     ? const Icon(Icons.check)
  //                     : null,
  //             onTap: () {
  //               chatNotifier.switchSession(sessionKey);
  //               Navigator.pop(context);
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildBackgroundImage() {
    return SizedBox.expand(
      child: Image.asset(
        'assets/female_ai_silhouette_bright_smile.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildChatContent(List<ChatMessage> chatMessages) {
    return Column(
      children: [
        Expanded(child: _buildMessageList(chatMessages)),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isSpeaking = _speakingStates[msg.id] ?? false;

        return GestureDetector(
          onLongPress: () => _copyToClipboard(msg.text),
          child: Align(
            alignment:
                msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Bubble(
              borderColor: msg.isUser ? Colors.green : Colors.white,
              color: Colors.white.withAlpha(32),
              nip: msg.isUser ? BubbleNip.rightTop : BubbleNip.leftTop,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: msg.text,
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context),
                    ).copyWith(
                      p: const TextStyle(fontSize: 16, color: Colors.white),
                      a: const TextStyle(color: Colors.white),
                      code: const TextStyle(color: Colors.white),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.white.withAlpha(80),
                      ),
                      em: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${msg.timestamp.hour}:${msg.timestamp.minute}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      if (!msg.isUser)
                        IconButton(
                          onPressed: () => _toggleMessageSpeech(msg),
                          icon: Icon(
                            isSpeaking ? Icons.volume_off : Icons.volume_up,
                          ),
                          iconSize: 20,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: Colors.black12,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
              ),
              onFieldSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
        ],
      ),
    );
  }
}
