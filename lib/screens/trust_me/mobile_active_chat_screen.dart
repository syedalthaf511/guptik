// ─── IMPORTS ─────────────────────────────────────────────────────────────
import 'dart:async'; 
import 'dart:io'; 
import 'dart:math'; 
import 'package:flutter/material.dart'; 
import 'package:flutter/services.dart'; // 🚀 ADDED: Required for Clipboard (Copy text)
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:video_player/video_player.dart'; 
import 'package:http/http.dart' as http; 
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; 
import '../../services/trustme/trust_me_service.dart'; 

// ─── HELPER FUNCTIONS ────────────────────────────────────────────────────
String _formatTime(DateTime dt) {
  final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $ampm';
}

String _formatDateLabel(DateTime dt) {
  final now = DateTime.now(); 
  final today = DateTime(now.year, now.month, now.day); 
  final msgDay = DateTime(dt.year, dt.month, dt.day); 
  final diff = today.difference(msgDay).inDays; 
  
  if (diff == 0) return 'Today'; 
  if (diff == 1) return 'Yesterday'; 
  
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

// ─── MAIN SCREEN WIDGET ──────────────────────────────────────────────────

class MobileActiveChatScreen extends StatefulWidget {
  final ConversationSummary chat; 
  const MobileActiveChatScreen({super.key, required this.chat});

  @override
  State<MobileActiveChatScreen> createState() => _MobileActiveChatScreenState();
}

class _MobileActiveChatScreenState extends State<MobileActiveChatScreen> {
  final TextEditingController _messageController = TextEditingController(); 
  final ScrollController _scrollController = ScrollController(); 
  final ImagePicker _picker = ImagePicker(); 
  
  final FocusNode _focusNode = FocusNode();
  bool _showEmojiPicker = false; 
  
  List<Map<String, dynamic>> _activeMessages = []; 
  Timer? _messageTimer; 
  String _myUserId = ''; 
  int _previousMessageCount = 0; 
  bool _isUploading = false; 

  String _displayName = ''; 
  
  // Tracks which message we are currently editing
  String? _editingMessageId; 

  @override
  void initState() {
    super.initState();
    _myUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _displayName = widget.chat.displayName; 
    
    TrustMeService.instance.markConversationAsRead(widget.chat.id);
    _loadMessages();
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showEmojiPicker = false);
      }
    });
    
    _messageTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      _loadMessages(); 
      TrustMeService.instance.markConversationAsRead(widget.chat.id); 
      if (timer.tick % 4 == 0) _checkPeerOnlineStatus();
    });
  }

  Future<void> _checkPeerOnlineStatus() async {
    try {
      final contact = await TrustMeService.instance.getContactForConversation(widget.chat.id);
      if (contact != null && contact['url'] != null) {
        var url = contact['url'].toString();
        if (!url.startsWith('http')) url = 'https://$url'; 
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
        if (mounted) setState(() => widget.chat.isOnline = (res.statusCode == 200));
      }
    } catch (e) {
      if (mounted) setState(() => widget.chat.isOnline = false);
    }
  }

  Future<void> _loadMessages() async {
    try {
      final dbMessages = await TrustMeService.instance.getMessages(widget.chat.id);
      if (!mounted) return;

      final formatted = dbMessages.map<Map<String, dynamic>>((msg) {
        final rawContent = msg['content']?.toString() ?? '';
        String type = msg['content_type']?.toString() ?? 'text';

        if (rawContent.startsWith('[media]') || rawContent.startsWith('[vault]')) {
          final lower = rawContent.toLowerCase();
          if (lower.endsWith('.mp4') || lower.endsWith('.mov')) type = 'video';
          else if (lower.endsWith('.pdf') || lower.endsWith('.doc') || lower.endsWith('.zip')) type = 'document';
          else type = 'image';
        } else if (rawContent.startsWith('[document]')) {
          type = 'document';
        }

        final isDeleted = msg['is_deleted_for_everyone'] == true || msg['is_deleted'] == true;

        // 🚀 THE FIX: Convert DB time (UTC) to Local Device Time (IST)
        String rawTime = msg['created_at']?.toString() ?? '';
        if (rawTime.isNotEmpty && !rawTime.endsWith('Z') && !rawTime.contains('+')) {
          rawTime += 'Z'; // Force Flutter to recognize this as UTC time
        }
        DateTime parsedTime = DateTime.tryParse(rawTime)?.toLocal() ?? DateTime.now();

        return {
          'id': msg['id']?.toString() ?? '',
          'content': rawContent,
          'isMe': msg['sender_id'] == _myUserId, 
          'time': parsedTime, // 🚀 Converted time injected here!
          'type': isDeleted ? 'deleted' : type,
          'is_read': msg['is_read'] == true, 
          'is_delivered': msg['is_delivered'] == true, 
          'media_file_size': msg['media_file_size'],
          'media_mime_type': msg['media_mime_type']?.toString(),
        };
      }).toList();

      setState(() => _activeMessages = formatted);

      if (formatted.length > _previousMessageCount) {
        _previousMessageCount = formatted.length;
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }
    } catch (e) { debugPrint("Load error: $e"); }
  }

  // Handles both Sending NEW messages and EDITING existing ones
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return; 

    if (_editingMessageId != null) {
      // --- WE ARE EDITING A MESSAGE ---
      final msgId = _editingMessageId!;
      
      setState(() {
        // Optimistically update the UI instantly
        final index = _activeMessages.indexWhere((m) => m['id'] == msgId);
        if (index != -1) _activeMessages[index]['content'] = text;
        
        _editingMessageId = null; // Exit edit mode
        _messageController.clear();
      });

      // Send the edit command to the backend
      await TrustMeService.instance.editMessage(conversationId: widget.chat.id, messageId: msgId, newContent: text);
      
    } else {
      // --- WE ARE SENDING A NEW MESSAGE ---
      setState(() {
        _activeMessages.add({'content': text, 'isMe': true, 'type': 'text', 'is_read': false, 'is_delivered': false, 'time': DateTime.now()});
        _previousMessageCount++;
        _messageController.clear(); 
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });

      await TrustMeService.instance.sendMessage(conversationId: widget.chat.id, content: text);
    }
  }

  // Shows the Bottom Sheet menu when you long-press a message
  void _showMessageOptions(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] as bool;
    final type = msg['type'] as String;

    if (type == 'deleted') return; // Cannot edit or copy a deleted message

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            // Option 1: Copy Text
            if (type == 'text')
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.black87),
                title: const Text('Copy'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg['content']));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
                },
              ),
              
            // Option 2: Edit Message (Only if you sent it, and it's text)
            if (isMe && type == 'text')
              ListTile(
                leading: const Icon(Icons.edit, color: Color.fromARGB(255, 115, 11, 134)),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _editingMessageId = msg['id'];
                    _messageController.text = msg['content'];
                    _focusNode.requestFocus(); // Pop open the keyboard
                  });
                },
              ),
              
            // Option 3: Delete Message
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(msg);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Delete Confirmation Dialog
  void _showDeleteDialog(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] as bool;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text("Delete message?", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        content: const Text("This action cannot be undone.", style: TextStyle(color: Colors.black54)),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          
          TextButton(
            child: const Text("Delete for me", style: TextStyle(color: Color.fromARGB(255, 115, 11, 134))),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() => _activeMessages.removeWhere((m) => m['id'] == msg['id'])); // Optimistic UI update
              await TrustMeService.instance.deleteMessage(conversationId: widget.chat.id, messageId: msg['id'], forEveryone: false);
            },
          ),
          
          if (isMe) // You can only delete for everyone if YOU sent it
            TextButton(
              child: const Text("Delete for everyone", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                setState(() {
                  final index = _activeMessages.indexWhere((m) => m['id'] == msg['id']);
                  if (index != -1) _activeMessages[index]['type'] = 'deleted'; // Optimistic UI update
                });
                await TrustMeService.instance.deleteMessage(conversationId: widget.chat.id, messageId: msg['id'], forEveryone: true);
              },
            ),
        ],
      ),
    );
  }

  Future<void> _pickAndSendMedia(ImageSource source, {bool isVideo = false}) async {
    try {
      final XFile? pickedFile = isVideo ? await _picker.pickVideo(source: source) : await _picker.pickImage(source: source, imageQuality: 70); 
      if (pickedFile == null) return; 

      setState(() => _isUploading = true);
      await TrustMeService.instance.streamMediaFile(conversationId: widget.chat.id, filePath: pickedFile.path, contentType: isVideo ? 'video/mp4' : 'image/jpeg');
      _loadMessages(); 
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload Failed: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(leading: const Icon(Icons.image, color: Color.fromARGB(255, 115, 11, 134)), title: const Text('Send Photo'), onTap: () { Navigator.pop(context); _pickAndSendMedia(ImageSource.gallery, isVideo: false); }),
            ListTile(leading: const Icon(Icons.videocam, color: Color.fromARGB(255, 115, 11, 134)), title: const Text('Send Video'), onTap: () { Navigator.pop(context); _pickAndSendMedia(ImageSource.gallery, isVideo: true); }),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog() {
    final originalName = widget.chat.contactUsername ?? 'Unknown';
    final currentCustom = widget.chat.customUsername ?? '';
    final controller = TextEditingController(text: currentCustom.isNotEmpty ? currentCustom : originalName);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color.fromARGB(255, 115, 11, 134), size: 20),
            SizedBox(width: 10),
            Text('Rename Contact', style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Original name: $originalName', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Enter a custom name...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color.fromARGB(255, 115, 11, 134)), borderRadius: BorderRadius.circular(8)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                    onPressed: () => controller.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Clear the field to revert to the original name.', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 115, 11, 134)),
            onPressed: () async {
              final newName = controller.text.trim();
              Navigator.pop(dialogCtx); 

              final success = await TrustMeService.instance.renameContact(
                conversationId: widget.chat.id,
                customName: newName,
              );

              if (success && mounted) {
                setState(() {
                  _displayName = newName.isEmpty ? originalName : newName;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newName.isEmpty ? 'Name reverted to "$originalName"' : 'Contact renamed to "$newName"'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel(); 
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), 
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 115, 11, 134), 
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(radius: 18, backgroundColor: Color(0xFFDFDFDF), child: Icon(Icons.person, color: Colors.white)),
                if (widget.chat.isOnline)
                  Positioned(bottom: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: const Color.fromARGB(255, 115, 11, 134), width: 2)))),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_displayName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500)),
                  Row(
                    children: [
                      Icon(Icons.lock, color: Colors.white70, size: 10),
                      const SizedBox(width: 4),
                      Text(widget.chat.isOnline ? "Online" : "Offline", style: TextStyle(color: widget.chat.isOnline ? Colors.greenAccent : Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () {}), 
          IconButton(icon: const Icon(Icons.call), onPressed: () {}), 
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            onSelected: (value) {
              if (value == 'rename') _showRenameDialog(); 
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Color.fromARGB(255, 115, 11, 134), size: 18),
                    SizedBox(width: 12),
                    Text('Rename Contact', style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: PopScope(
        canPop: !_showEmojiPicker,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_showEmojiPicker) {
            setState(() => _showEmojiPicker = false);
          }
        },
        child: Column(
          children: [
            Expanded(child: _buildMessageList()), 
            _buildInputBar(), 
            
            if (_showEmojiPicker)
              SizedBox(
                height: 250, 
                child: EmojiPicker(
                  textEditingController: _messageController,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── MESSAGE LIST & BUBBLES ──────────────────────────────────────────────

  Widget _buildMessageList() {
    if (_activeMessages.isEmpty) {
      return Center(child: Text("Send a message to start the secure chat.", style: TextStyle(color: Colors.grey[600])));
    }

    final List<Widget> items = [];
    for (int i = 0; i < _activeMessages.length; i++) {
      final msg = _activeMessages[i];
      final msgTime = msg['time'] as DateTime;

      if (i == 0 || !_isSameDay(msgTime, _activeMessages[i - 1]['time'] as DateTime)) {
        items.add(_buildDateSeparator(_formatDateLabel(msgTime)));
      }
      items.add(_buildMessageBubble(msg));
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      children: items,
    );
  }

  Widget _buildDateSeparator(String label) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFD4EAF7), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 1)]),
        child: Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] as bool; 
    final type = msg['type'] as String; 
    final time = msg['time'] as DateTime; 
    final ipBase = TrustMeService.instance.gatewayUrl; 

    Widget content;
    if (type == 'deleted') content = _buildDeletedBubble();
    else if (type == 'image') content = _buildImageContent(msg, ipBase);
    else if (type == 'video') content = _buildVideoContent(msg, ipBase);
    else if (type == 'document') content = _buildDocumentContent(msg, ipBase);
    else content = _buildTextContent(msg['content'].toString());

    final isMedia = (type == 'image' || type == 'video');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, 
      // Detects long presses for the Edit/Delete menu!
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(msg),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), 
          decoration: BoxDecoration(
            color: isMedia ? Colors.transparent : (isMe ? const Color.fromARGB(255, 235, 187, 245) : Colors.white), 
            borderRadius: BorderRadius.only(topLeft: const Radius.circular(12), topRight: const Radius.circular(12), bottomLeft: Radius.circular(isMe ? 12 : 4), bottomRight: Radius.circular(isMe ? 4 : 12)),
            boxShadow: isMedia ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 1, offset: const Offset(0, 1))],
          ),
          child: Stack(
            children: [
              Padding(
                padding: isMedia ? EdgeInsets.zero : const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: content,
              ),
              Positioned(
                bottom: 4, right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: isMedia ? BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)) : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatTime(time), style: TextStyle(color: isMedia ? Colors.white : Colors.grey[700], fontSize: 10)),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildStatusTick(msg['is_read'] as bool? ?? false, msg['is_delivered'] as bool? ?? false),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTick(bool isRead, bool isDelivered) {
    if (isRead) return const Icon(Icons.done_all, size: 14, color: Colors.blue); 
    if (isDelivered) return const Icon(Icons.done_all, size: 14, color: Colors.grey); 
    return const Icon(Icons.access_time, size: 12, color: Colors.grey); 
  }

  Widget _buildDeletedBubble() => Padding(padding: const EdgeInsets.only(right: 48, bottom: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.block, color: Colors.grey, size: 14), const SizedBox(width: 6), Text('This message was deleted', style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontStyle: FontStyle.italic))]));

  Widget _buildTextContent(String content) => Padding(padding: const EdgeInsets.only(right: 64, bottom: 8), child: Text(content, style: TextStyle(color: Colors.grey[900], fontSize: 15)));

  Widget _buildImageContent(Map<String, dynamic> msg, String ipBase) {
    final url = msg['content'].toString().replaceFirst('[media]', ipBase).replaceFirst('[vault]', ipBase);
    return GestureDetector(
      onTap: () => showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.transparent, child: InteractiveViewer(child: Image.network(url)))),
      child: Column(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(url, width: 260, height: 220, fit: BoxFit.cover)),
          const SizedBox(height: 20), 
        ],
      ),
    );
  }

  Widget _buildVideoContent(Map<String, dynamic> msg, String ipBase) {
    final url = msg['content'].toString().replaceFirst('[media]', ipBase).replaceFirst('[vault]', ipBase);
    return GestureDetector(
      onTap: () {
        showGeneralDialog(
          context: context,
          barrierDismissible: true, 
          barrierLabel: "SecureVideoViewer",
          barrierColor: Colors.black.withOpacity(0.95), 
          transitionDuration: const Duration(milliseconds: 800), 
          pageBuilder: (context, animation, secondaryAnimation) {
            return _MobileVideoPlayerDialog(url: url); 
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015) 
                ..rotateZ(pi * 2 * (1 - curvedAnimation.value)) 
                ..rotateX(pi * (1 - curvedAnimation.value)) 
                ..scale(curvedAnimation.value), 
              child: FadeTransition(
                opacity: curvedAnimation, 
                child: child,
              ),
            );
          },
        );
      },
      child: Column(
        children: [
          Container(width: 260, height: 200, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 60)),
          const SizedBox(height: 20), 
        ],
      ),
    );
  }

  Widget _buildDocumentContent(Map<String, dynamic> msg, String ipBase) {
    final fileName = msg['content'].toString().replaceAll(RegExp(r'^\[(document|media|vault)\]'), '').split('/').last;
    return Container(
      width: 220, padding: const EdgeInsets.fromLTRB(4, 4, 12, 24),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Color.fromARGB(255, 115, 11, 134), size: 30), const SizedBox(width: 8),
          Expanded(child: Text(fileName, style: TextStyle(color: Colors.grey[900], fontSize: 14, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The "Editing Message" Banner that appears above the keyboard
        if (_editingMessageId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade200,
            child: Row(
              children: [
                const Icon(Icons.edit, color: Color.fromARGB(255, 115, 11, 134), size: 18),
                const SizedBox(width: 8),
                const Expanded(child: Text("Editing message...", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500))),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () {
                    setState(() {
                      _editingMessageId = null; // Cancel editing
                      _messageController.clear();
                    });
                  }
                ),
              ],
            ),
          ),

        // The normal input bar
        Container(
          padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8), color: Colors.transparent,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 1, offset: const Offset(0, 1))]),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(_showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined, color: Colors.black54), 
                        onPressed: () {
                          if (_showEmojiPicker) {
                            _focusNode.requestFocus(); 
                          } else {
                            _focusNode.unfocus(); 
                            setState(() => _showEmojiPicker = true);
                          }
                        }
                      ),
                      
                      Expanded(
                        child: TextField(
                          controller: _messageController, 
                          focusNode: _focusNode, 
                          style: const TextStyle(color: Colors.black, fontSize: 16), 
                          maxLines: 5, minLines: 1, 
                          decoration: const InputDecoration(hintText: "Message", hintStyle: TextStyle(color: Colors.black38, fontSize: 16), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12))
                        )
                      ),
                      
                      // Hide camera/attachment icons if we are editing text
                      if (_editingMessageId == null) ...[
                        IconButton(icon: const Icon(Icons.attach_file, color: Colors.black54), onPressed: _showAttachmentMenu),
                        IconButton(icon: const Icon(Icons.camera_alt, color: Colors.black54), onPressed: () => _pickAndSendMedia(ImageSource.camera, isVideo: false)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(bottom: 4), decoration: const BoxDecoration(color: Color.fromARGB(255, 115, 11, 134), shape: BoxShape.circle),
                child: _isUploading 
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))) 
                  : IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _sendMessage),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── FULLSCREEN VIDEO PLAYER DIALOG ───────────────────────────────────────
class _MobileVideoPlayerDialog extends StatefulWidget {
  final String url;
  const _MobileVideoPlayerDialog({required this.url});
  @override
  State<_MobileVideoPlayerDialog> createState() => _MobileVideoPlayerDialogState();
}

class _MobileVideoPlayerDialogState extends State<_MobileVideoPlayerDialog> {
  late VideoPlayerController _controller; 
  bool _init = false; 
  
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))..initialize().then((_) { 
      if (mounted) setState(() => _init = true); 
      _controller.play(); 
    });
  }
  
  @override
  void dispose() { 
    _controller.dispose(); 
    super.dispose(); 
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black, 
      insetPadding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end, 
            children: [
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))
            ]
          ),
          if (!_init) 
            const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color.fromARGB(255, 115, 11, 134)))
          else 
            Flexible(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio, 
                child: VideoPlayer(_controller)
              ),
            ),
          if (_init) 
            VideoProgressIndicator(_controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Color.fromARGB(255, 115, 11, 134))),
          if (_init) 
            IconButton(
              icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 50), 
              onPressed: () => setState(() { _controller.value.isPlaying ? _controller.pause() : _controller.play(); })
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}