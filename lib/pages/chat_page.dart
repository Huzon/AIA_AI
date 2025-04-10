import 'package:aia/pages/talk_mode_page.dart';
import 'package:aia/services/tts_services.dart';
import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

import '../providers/chat_provider.dart';
import '../providers/stt_provider.dart';
import '../providers/tts_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final bool _isListening = false;
  final String _spokenText = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _controller.clear();
      await ref.read(chatProvider.notifier).sendMessage(text);

      // Speak the last bot message
      final messages = ref.read(chatProvider);
      if (messages.isNotEmpty && !messages.last.isUser) {
        await ref.read(ttsServiceProvider).speak(messages.last.text);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatMessages = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 9, 16),
        foregroundColor: Colors.white,
        // title: const Text('AIA Chat'),
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TalkModePage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'Chat Sessions',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ...chatNotifier.sessionKeys.map((sessionKey) {
              return ListTile(
                title: Text(
                  sessionKey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing:
                    sessionKey == chatNotifier.currentSessionKey
                        ? const Icon(Icons.check)
                        : null,
                onTap: () {
                  chatNotifier.switchSession(sessionKey);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Image.asset(
                'assets/female_ai_silhouette_bright_smile.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Use Expanded to wrap the ListView.builder properly
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: chatMessages.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final msg = chatMessages[index];
                      bool isSpeaking = false;
                      return GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: msg.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copied to clipboard')),
                          );
                        },
                        child: Align(
                          alignment:
                              msg.isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Bubble(
                            borderColor:
                                msg.isUser ? Colors.green : Colors.white,
                            color: Colors.white.withAlpha(32),
                            nip:
                                msg.isUser
                                    ? BubbleNip.rightTop
                                    : BubbleNip.leftTop,

                            // child: Container(
                            //   constraints: BoxConstraints(
                            //     maxWidth: size.width * 0.8,
                            //   ),
                            //   padding: const EdgeInsets.all(12),
                            //   margin: const EdgeInsets.symmetric(vertical: 6),
                            //   decoration: BoxDecoration(
                            //     color:
                            //     // msg.isUser
                            //     // ?
                            //     Colors.white.withAlpha(32),
                            //     // : Colors.black.withAlpha(64),
                            //     borderRadius: BorderRadius.circular(12),
                            //     border: Border.all(
                            //       width: 2,
                            //       color:
                            //           msg.isUser ? Colors.purple : Colors.grey,
                            //     ),
                            //   ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // SingleChildScrollView(
                                // constraints: BoxConstraints(
                                //   maxWidth: size.width * 0.8,
                                // ),
                                MarkdownBody(
                                  data:
                                      msg.text, // This is where your Gemini text goes
                                  styleSheet: MarkdownStyleSheet.fromTheme(
                                    Theme.of(context),
                                  ).copyWith(
                                    p: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                    a: TextStyle(
                                      // fontSize: 16,
                                      color: Colors.white,
                                    ),
                                    code: TextStyle(
                                      // fontSize: 16,
                                      color: Colors.white,
                                    ),
                                    codeblockDecoration: BoxDecoration(
                                      color: Colors.white.withAlpha(80),
                                    ),
                                    em: TextStyle(
                                      // fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                // ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                        onPressed: () {
                                          isSpeaking
                                              ? ref
                                                  .read(ttsServiceProvider)
                                                  .stop()
                                              : ref
                                                  .read(ttsServiceProvider)
                                                  .speak(msg.text);
                                          setState(
                                            () => isSpeaking = !isSpeaking,
                                          );
                                        },
                                        icon:
                                            isSpeaking
                                                ? Icon(Icons.volume_off)
                                                : Icon(Icons.volume_down),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // ),
                      );
                    },
                  ),
                ),
                if (_isListening)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _spokenText,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Container(
                  color: Colors.black12,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // IconButton(
                      //   icon: Icon(
                      //     _isListening ? Icons.mic_off : Icons.mic,
                      //     color: _isListening ? Colors.red : Colors.grey,
                      //   ),
                      //   onPressed: _toggleListening,
                      // ),
                      Expanded(
                        child: TextFormField(
                          controller: _controller,
                          style: TextStyle(color: Colors.white),
                          maxLength: 500,

                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                            border: OutlineInputBorder(),
                          ),

                          // onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
