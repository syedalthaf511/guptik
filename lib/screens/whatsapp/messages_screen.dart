import 'package:flutter/material.dart';
import 'package:guptik/screens/whatsapp/wa_chat_detail_screen.dart';
import 'package:guptik/services/whatsapp/wa_conversation_service.dart';
import 'package:guptik/models/whatsapp/wa_conversation.dart';
import 'package:guptik/widgets/whatsapp/whtasappscreenwidget/conversation_card.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConversationService _conversationService;
  List<Conversation> _individualConversations = [];
  List<Conversation> _groupConversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _conversationService = ConversationService();
    _loadConversations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    
    try {
      final individual = await _conversationService.getIndividualConversations();
      final groups = await _conversationService.getGroupConversations();
      
      if (mounted) {
        setState(() {
          _individualConversations = individual;
          _groupConversations = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('Error loading conversations: $e');
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}';
    }
  }

  Widget _buildConversationList(List<Conversation> conversations) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 16,
                          color: Colors.grey[200],
                          margin: const EdgeInsets.only(bottom: 8),
                        ),
                        Container(
                          width: 150,
                          height: 12,
                          color: Colors.grey[200],
                          margin: const EdgeInsets.only(bottom: 4),
                        ),
                        Container(
                          width: 200,
                          height: 12,
                          color: Colors.grey[200],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading conversations',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadConversations,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              conversations == _individualConversations
                  ? Icons.person_outline
                  : Icons.group_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              conversations == _individualConversations
                  ? 'No individual conversations'
                  : 'No group conversations',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              conversations == _individualConversations
                  ? 'Start a new chat to see conversations here'
                  : 'Create a group to start chatting',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          return ConversationCard(
            conversation: conversations[index],
            onTap: () async {
              await _handleConversationTap(conversations[index]);
            },
            formatTime: _formatTime,
          );
        },
      ),
    );
  }

  Future<void> _handleConversationTap(Conversation conversation) async {
    // Mark as read
    await _conversationService.markAsRead(conversation.id);
    
    // Update local state
    setState(() {
      if (conversation.isGroup) {
        final index = _groupConversations.indexWhere((c) => c.id == conversation.id);
        if (index != -1) {
          _groupConversations[index] = conversation.copyWith(isUnread: false);
        }
      } else {
        final index = _individualConversations.indexWhere((c) => c.id == conversation.id);
        if (index != -1) {
          _individualConversations[index] = conversation.copyWith(isUnread: false);
        }
      }
    });
    
    // Navigate to chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          conversationId: conversation.id,
          phoneNumber: conversation.phoneNumber,
          contactName: conversation.displayName,
        ),
      ),
    ).then((_) {
      // Refresh when returning from chat
      _loadConversations();
    });
  }

  void _showClearMessagesDialog(bool isIndividualTab) {
    final conversations = isIndividualTab 
        ? _individualConversations 
        : _groupConversations;
    
    if (conversations.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Messages'),
          content: Text(
            'Are you sure you want to mark all ${isIndividualTab ? 'individual' : 'group'} messages as read?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                for (final convo in conversations) {
                  try {
                    await _conversationService.markAsRead(convo.id);
                  } catch (e) {
                    debugPrint('Error marking as read: $e');
                  }
                }
                _loadConversations();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
              child: const Text('Mark as Read'),
            ),
          ],
        );
      },
    );
  }

  void _showNewChatDialog(bool isGroup) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isGroup ? 'New Group' : 'New Chat'),
          content: Text(isGroup ? 'Group creation coming soon!' : 'Individual chat creation coming soon!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: const Text(
          'WhatsApp',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Implement search
            },
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearMessagesDialog(_tabController.index == 0);
              } else if (value == 'refresh') {
                _loadConversations();
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: const [
                      Icon(Icons.refresh, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('Refresh'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: const [
                      Icon(Icons.delete_outline, color: Colors.grey),
                      SizedBox(width: 12),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 8),
                  Text('Individual'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group, size: 20),
                  SizedBox(width: 8),
                  Text('Group'),
                ],
              ),
            ),
          ],
        ),
      ),
    
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationList(_individualConversations),
          _buildConversationList(_groupConversations),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showNewChatDialog(false);
          } else {
            _showNewChatDialog(true);
          }
        },
        backgroundColor: Colors.green,
        

        child: Icon(
          _tabController.index == 0 ? Icons.person_add : Icons.group_add,
          color: Colors.white,
        ),
      ),
    );
  }
}