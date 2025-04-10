import 'package:aia/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key, required this.chatNotifier});
  final ChatNotifier chatNotifier;
  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.deepPurple),
            child: Text(
              'Chat Sessions',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ...widget.chatNotifier.sessionKeys.map(
            (sessionKey) => ListTile(
              title: Text(
                sessionKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing:
                  sessionKey == widget.chatNotifier.currentSessionKey
                      ? const Icon(Icons.check)
                      : null,
              onTap: () {
                widget.chatNotifier.switchSession(sessionKey);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
