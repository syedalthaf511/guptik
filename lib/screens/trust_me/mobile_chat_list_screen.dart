import 'package:flutter/material.dart';
import '../../services/trustme/trust_me_service.dart';
import 'mobile_active_chat_screen.dart';

class MobileChatListScreen extends StatefulWidget {
  const MobileChatListScreen({super.key});

  @override
  State<MobileChatListScreen> createState() => _MobileChatListScreenState();
}

class _MobileChatListScreenState extends State<MobileChatListScreen> {
  List<ConversationSummary> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final chats = await TrustMeService.instance.getConversations();
      if (mounted) setState(() { _conversations = chats; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        backgroundColor:  Color.fromARGB(255, 115, 11, 134), 
        iconTheme:  IconThemeData(color: Colors.white),
        // 🚀 THE FIX: No custom back arrow code needed! Flutter automatically detects it is on top of the Connection Screen and will give you a back arrow that pops perfectly.
        title:  Text("Trust Me", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF128C7E)))
          : _conversations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final chat = _conversations[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MobileActiveChatScreen(chat: chat))).then((_) => _loadChats());
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const CircleAvatar(radius: 24, backgroundColor: Color(0xFFDFDFDF), child: Icon(Icons.person, color: Colors.white, size: 30)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(chat.displayName, style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(chat.lastMessagePreview ?? "Start a conversation", style: const TextStyle(color: Colors.black54, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(chat.lastMessageAt != null ? "${chat.lastMessageAt!.hour}:${chat.lastMessageAt!.minute.toString().padLeft(2, '0')}" : "", style: TextStyle(color: chat.unreadCount > 0 ? Color.fromARGB(255, 115, 11, 134) : Colors.black54, fontSize: 12)),
                                const SizedBox(height: 6),
                                if (chat.unreadCount > 0)
                                  CircleAvatar(
                                    radius: 10, 
                                    backgroundColor: Color.fromARGB(255, 115, 11, 134), 
                                    child: Text(chat.unreadCount.toString(), 
                                    style: const TextStyle(color: Colors.white,
                                     fontSize: 10, 
                                     fontWeight: FontWeight.bold))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 115, 11, 134),
        child: const Icon(Icons.person_add, color: Colors.white), // Changed to an 'Add Contact' icon
        onPressed: () {
          // 🚀 THE FIX: This just pops the Chat List to reveal the Connection Screen underneath it!
          Navigator.pop(context);
        }, 
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text("No chats yet", style: TextStyle(color: Colors.black87, fontSize: 18)),
          const SizedBox(height: 8),
          const Text("Use the button below to link a new contact.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}