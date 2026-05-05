import 'package:flutter/material.dart';
import '../../services/trustme/trust_me_service.dart';
import 'mobile_active_chat_screen.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

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
      backgroundColor: _darkBg, 
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7), 
        elevation: 0,
        iconTheme: const IconThemeData(color: _ancientGold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
        ),
        // 🚀 THE FIX: No custom back arrow code needed! Flutter automatically detects it is on top of the Connection Screen and will give you a back arrow that pops perfectly.
        title: const Text("Trust Me", style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt_outlined, color: _ancientGold), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search, color: _ancientGold), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: _ancientGold), onPressed: () {}),
        ],
      ),
      // THE FIX: Full screen box ensures the background stretches safely without bottom overflow
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // The Shared Cinematic Nebula Background
            const Positioned.fill(child: DynamicAppBackground()),
            
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: _ancientGold))
                : _conversations.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 110, 16, 100), // Padded top for AppBar, bottom for FAB
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final chat = _conversations[index];
                          final bool hasUnread = chat.unreadCount > 0;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: hasUnread ? _ancientGold : _ancientGold.withValues(alpha: 0.2), 
                                width: hasUnread ? 1.5 : 1.0
                              ),
                              boxShadow: hasUnread ? [
                                BoxShadow(
                                  color: _ancientGold.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ] : [],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => MobileActiveChatScreen(chat: chat))).then((_) => _loadChats());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: Row(
                                    children: [
                                      // Styled Avatar
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: _ancientGold.withValues(alpha: 0.5), width: 2),
                                          color: _ancientGold.withValues(alpha: 0.15),
                                        ),
                                        child: const CircleAvatar(
                                          radius: 26, 
                                          backgroundColor: Colors.transparent, 
                                          child: Icon(Icons.person, color: _ancientGold, size: 30)
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              chat.displayName, 
                                              style: TextStyle(
                                                color: Colors.white, 
                                                fontSize: 18, 
                                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600
                                              )
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              chat.lastMessagePreview ?? "Start a conversation", 
                                              style: TextStyle(
                                                color: hasUnread ? Colors.white : Colors.grey[400], 
                                                fontSize: 14,
                                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                              ), 
                                              maxLines: 1, 
                                              overflow: TextOverflow.ellipsis
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            chat.lastMessageAt != null ? "${chat.lastMessageAt!.hour}:${chat.lastMessageAt!.minute.toString().padLeft(2, '0')}" : "", 
                                            style: TextStyle(
                                              color: hasUnread ? _ancientGold : Colors.grey[500], 
                                              fontSize: 12,
                                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                            )
                                          ),
                                          const SizedBox(height: 8),
                                          if (hasUnread)
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: const BoxDecoration(
                                                color: _ancientGold,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _ancientGold,
                                                    blurRadius: 4,
                                                    spreadRadius: 1,
                                                  )
                                                ]
                                              ),
                                              child: Text(
                                                chat.unreadCount.toString(), 
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 12, 
                                                  fontWeight: FontWeight.bold
                                                )
                                              )
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _ancientGold,
        foregroundColor: Colors.black,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: const Icon(Icons.person_add, size: 28), // Changed to an 'Add Contact' icon
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _ancientGold.withValues(alpha: 0.1),
              border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(Icons.chat_bubble_outline, size: 64, color: _ancientGold.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 24),
          const Text("No chats yet", style: TextStyle(color: _ancientGold, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            "Use the button below to link a new contact.", 
            textAlign: TextAlign.center, 
            style: TextStyle(color: Colors.grey[400], fontSize: 16)
          ),
        ],
      ),
    );
  }
}