import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../config/theme.dart';
import '../../../models/chat/chat_model.dart';
import '../../../providers/service_providers.dart';
import '../../../providers/user_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ChatModel>>(
              stream: ref.watch(chatServiceProvider).getMyChats(user.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final chats = snapshot.data ?? [];
                if (chats.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final title = _chatTitle(chat, user.userId);
                    final lastMessage = chat.lastMessage?['text']?.toString() ??
                        'Tap to open chat';
                    final time =
                        chat.lastMessage?['timestamp']?.toString() ?? '';

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(title),
                      subtitle: Text(lastMessage,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(time.isEmpty ? '' : time.split('T').first,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textTertiaryDark)),
                      onTap: () => context.push(AppRoutes.chatDetail,
                          extra: chat.chatId),
                    );
                  },
                );
              },
            ),
    );
  }

  String _chatTitle(ChatModel chat, String currentUserId) {
    final otherUserId = chat.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    final details = chat.participantDetails[otherUserId];
    return details?['name']?.toString() ??
        details?['fullName']?.toString() ??
        'Chat';
  }
}
