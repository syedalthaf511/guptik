import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guptik/models/whatsapp/wa_message.dart';
import 'package:guptik/services/whatsapp/wa_conversation_service.dart';
import 'package:guptik/services/whatsapp/wa_message_service.dart';
import 'package:guptik/widgets/whatsapp/chatwidgets/attachment_menu.dart';
import 'package:guptik/widgets/whatsapp/chatwidgets/chat_info_dialog.dart';
import 'package:guptik/widgets/whatsapp/chatwidgets/message_bubble.dart';
import 'package:guptik/widgets/whatsapp/chatwidgets/audio_recording_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String phoneNumber;
  final String contactName;
  final String? profilePic;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.phoneNumber,
    required this.contactName,
    this.profilePic,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  late MessageService _messageService;
  late ConversationService _conversationService;
  late StreamSubscription<List<Message>> _messageStreamSubscription;

  bool _aiEnabled = false;
  bool _isLoading = true;
  bool _isSending = false;
  bool _updatingAI = false;
  bool _isUploading = false;
  bool _showAttachmentMenu = false;
  String? _aiAgentId;
  final ImagePicker _imagePicker = ImagePicker();
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final List<Map<String, dynamic>> _selectedMedia = [];

  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _messageService = MessageService();
    _conversationService = ConversationService();
    _loadData();
    _subscribeToMessages();
    _loadAIAgentStatus();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load initial messages
      _messages = await _messageService.getMessages(
        widget.conversationId,
        ascending: true,
      );

      // Mark messages as read
      await _messageService.markMessagesAsRead(widget.conversationId);
    } catch (e) {
      debugPrint('Error loading chat data: $e');
      _showError('Failed to load chat: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _loadAIAgentStatus() async {
    try {
      final isEnabled = await _conversationService.getAIAgentStatus(
        widget.conversationId,
      );
      if (mounted) {
        setState(() {
          _aiEnabled = isEnabled;
          _aiAgentId = isEnabled
              ? '00000000-0000-0000-0000-000000000000'
              : null;
        });
      }
    } catch (e) {
      debugPrint('Error loading AI agent status: $e');

      if (mounted) {
        setState(() {
          _aiEnabled = false;
          _aiAgentId = null;
        });
      }
    }
  }

  Future<void> _toggleAIAssistant() async {
    if (_updatingAI) return;

    setState(() {
      _updatingAI = true;
    });

    try {
      final newAiEnabled = !_aiEnabled;
      final String? newAgentId = newAiEnabled
          ? '00000000-0000-0000-0000-000000000000'
          : null;

      await _conversationService.updateAIAgentStatus(
        conversationId: widget.conversationId,
        aiEnabled: newAiEnabled,
      );

      if (mounted) {
        setState(() {
          _aiAgentId = newAgentId;
          _aiEnabled = newAiEnabled;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newAgentId != null
                  ? '🤖 AI Assistant enabled for this chat'
                  : 'AI Assistant disabled for this chat',
            ),
            backgroundColor: newAgentId != null ? Colors.green : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling AI assistant: $e');

      if (mounted) {
        _showError('Failed to update AI status: ${e.toString()}');

        setState(() {
          _aiEnabled = !_aiEnabled;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingAI = false;
        });
      }
    }
  }

  void _subscribeToMessages() {
    _messageStreamSubscription = _messageService
        .subscribeToMessages(widget.conversationId)
        .listen(
          (messages) {
            if (mounted) {
              setState(() => _messages = messages);
              _scrollToBottom();
            }
          },
          onError: (error) {
            debugPrint('Error in message stream: $error');
          },
        );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();
    _messageFocusNode.unfocus();

    try {
      await _messageService.sendTextMessage(
        conversationId: widget.conversationId,
        content: text,
        toPhoneNumber: widget.phoneNumber,
        isAI: _aiEnabled,
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      _showError('Failed to send message');
      _messageController.text = text;
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showAttachmentOptions() {
    setState(() {
      _showAttachmentMenu = !_showAttachmentMenu;
    });
  }

  Future<bool> _requestMediaPermission() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          final Map<Permission, PermissionStatus> statuses = await [
            Permission.photos,
            Permission.videos,
            Permission.audio,
          ].request();

          return statuses[Permission.photos]?.isGranted == true ||
              statuses[Permission.videos]?.isGranted == true ||
              statuses[Permission.audio]?.isGranted == true;
        } else {
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      } catch (e) {
        debugPrint('Error requesting media permission: $e');
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 30) {
          final manageStatus = await Permission.manageExternalStorage.request();
          if (manageStatus.isGranted) {
            return true;
          }

          return await _requestMediaPermission();
        } else {
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      } catch (e) {
        debugPrint('Error requesting storage permission: $e');
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
  }

  Future<void> _pickFromGallery() async {
    _showAttachmentMenu = false;

    final hasPermission = await _requestMediaPermission();
    if (!hasPermission) {
      _showError('Permission denied to access gallery');
      return;
    }

    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1920,
      );

      if (images.isNotEmpty) {
        for (final image in images) {
          await _sendMediaMessage(
            filePath: image.path,
            messageType: 'image',
            fileName: image.name,
            mimeType: image.mimeType ?? 'image/jpeg',
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      _showError('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _takePhoto() async {
    _showAttachmentMenu = false;

    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      _showError('Camera permission denied');
      return;
    }

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1920,
      );

      if (photo != null) {
        await _sendMediaMessage(
          filePath: photo.path,
          messageType: 'image',
          fileName: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
          mimeType: photo.mimeType ?? 'image/jpeg',
        );
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      _showError('Failed to take photo: ${e.toString()}');
    }
  }

  Future<void> _pickVideo() async {
    _showAttachmentMenu = false;

    final hasPermission = await _requestMediaPermission();
    if (!hasPermission) {
      _showError('Permission denied to access videos');
      return;
    }

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );

      if (video != null) {
        await _sendMediaMessage(
          filePath: video.path,
          messageType: 'video',
          fileName: video.name,
          mimeType: video.mimeType ?? 'video/mp4',
        );
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      _showError('Failed to pick video: ${e.toString()}');
    }
  }

  Future<void> _recordAudio() async {
    _showAttachmentMenu = false;

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _showError('Microphone permission denied');
      return;
    }

    final storagePermission = await _requestStoragePermission();
    if (!storagePermission) {
      _showError('Storage permission denied to save recording');
      return;
    }

    _showAudioRecordingDialog();
  }

  void _showAudioRecordingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AudioRecordingDialog(
        onSendAudio: (filePath) async {
          if (filePath != null && File(filePath).existsSync()) {
            await _sendMediaMessage(
              filePath: filePath,
              messageType: 'audio',
              fileName:
                  'audio_message_${DateTime.now().millisecondsSinceEpoch}.m4a',
              mimeType: 'audio/m4a',
            );
          }
        },
      ),
    );
  }

  Future<void> _pickDocument() async {
    _showAttachmentMenu = false;

    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      _showError('Storage permission denied');
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        if (file.path == null) {
          _showError('Could not access the selected file');
          return;
        }

        String messageType = 'document';
        String? mimeType = file.extension;

        if (mimeType == null || mimeType.isEmpty) {
          mimeType = 'application/octet-stream';
        } else {
          mimeType = mimeType.toLowerCase();
          switch (mimeType) {
            case 'pdf':
              mimeType = 'application/pdf';
              break;
            case 'doc':
            case 'docx':
              mimeType = 'application/msword';
              break;
            case 'xls':
            case 'xlsx':
              mimeType = 'application/vnd.ms-excel';
              break;
            case 'ppt':
            case 'pptx':
              mimeType = 'application/vnd.ms-powerpoint';
              break;
            case 'txt':
              mimeType = 'text/plain';
              break;
            case 'zip':
            case 'rar':
            case '7z':
              mimeType = 'application/zip';
              break;
            case 'jpg':
            case 'jpeg':
              mimeType = 'image/jpeg';
              messageType = 'image';
              break;
            case 'png':
              mimeType = 'image/png';
              messageType = 'image';
              break;
            case 'gif':
              mimeType = 'image/gif';
              messageType = 'image';
              break;
            case 'mp4':
            case 'mov':
            case 'avi':
            case 'mkv':
              mimeType = 'video/mp4';
              messageType = 'video';
              break;
            case 'mp3':
            case 'wav':
            case 'm4a':
            case 'aac':
            case 'ogg':
              mimeType = 'audio/mpeg';
              messageType = 'audio';
              break;
            default:
              mimeType = 'application/octet-stream';
          }
        }

        final fileObj = File(file.path!);
        final fileSize = await fileObj.length();

        if (messageType == 'image' && fileSize > 5 * 1024 * 1024) {
          _showError('Image size too large (max 5MB)');
          return;
        } else if (messageType == 'video' && fileSize > 16 * 1024 * 1024) {
          _showError('Video size too large (max 16MB)');
          return;
        } else if (messageType == 'document' && fileSize > 100 * 1024 * 1024) {
          _showError('Document size too large (max 100MB)');

          return;
        } else if (messageType == 'audio' && fileSize > 16 * 1024 * 1024) {
          _showError('Audio size too large (max 16MB)');
          return;
        }

        await _sendMediaMessage(
          filePath: file.path!,
          messageType: messageType,
          fileName: file.name,
          mimeType: mimeType,
        );
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
      _showError('Failed to pick document: ${e.toString()}');
    }
  }

  Future<void> _sendMediaMessage({
    required String filePath,
    required String messageType,
    required String fileName,
    required String mimeType,
    String? caption,
  }) async {
    setState(() => _isUploading = true);

    try {
      final file = File(filePath);
      final fileSize = await file.length();

      if (messageType == 'image' && fileSize > 5 * 1024 * 1024) {
        _showError('Image size too large (max 5MB)');
        return;
      }

      if (messageType == 'video' && fileSize > 16 * 1024 * 1024) {
        _showError('Video size too large (max 16MB)');
        return;
      }

      final uploadResult = await _messageService.uploadMedia(
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType,
      );

      if (!uploadResult['success']) {
        throw Exception('Upload failed: ${uploadResult['message']}');
      }

      final mediaUrl = uploadResult['url'] as String;

      final mediaInfo = {
        'url': mediaUrl,
        'filename': fileName,
        'mime_type': mimeType,
        'size': fileSize.toString(),
        'caption': caption,
        'local_path': filePath,
      };

      await _messageService.sendMediaMessage(
        conversationId: widget.conversationId,
        mediaUrl: mediaUrl,
        messageType: messageType,
        toPhoneNumber: widget.phoneNumber,
        mediaInfo: mediaInfo,
        isAI: _aiEnabled,
      );

      debugPrint('✅ Media message sent successfully!');
    } catch (e) {
      debugPrint('❌ Error sending media: $e');
      _showError('Failed to send media: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'pending':
      case 'sending':
        return Icons.access_time;
      case 'sent':
        return Icons.check;
      case 'delivered':
        return Icons.done_all;
      case 'read':
      case 'seen':
        return Icons.done_all;
      case 'failed':
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.access_time;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showMessageOptions(Message message) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () => Navigator.pop(context, 'reply'),
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () => Navigator.pop(context, 'copy'),
              ),
              if (!message.isIncoming && message.isFailed)
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Retry'),
                  onTap: () => Navigator.pop(context, 'retry'),
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
            ],
          ),
        );
      },
    );

    switch (result) {
      case 'reply':
        _messageController.text = '${message.content}\n\n';
        _messageFocusNode.requestFocus();
        break;
      case 'copy':
        await Clipboard.setData(ClipboardData(text: message.content));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Message copied')));
        break;
      case 'retry':
        await _messageService.retryFailedMessage(message.messageId);
        break;
      case 'delete':
        await _messageService.deleteMessage(message.messageId);
        break;
    }
  }

  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => ChatInfoDialog(
        contactName: widget.contactName,
        phoneNumber: widget.phoneNumber,
        messagesCount: _messages.length,
        aiEnabled: _aiEnabled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.contactName),
            Text(widget.phoneNumber, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  _aiEnabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                  color: _aiEnabled ? Colors.yellow : Colors.white,
                ),
                onPressed: _updatingAI ? null : _toggleAIAssistant,
                tooltip: _aiEnabled
                    ? 'Disable AI Assistant'
                    : 'Enable AI Assistant',
              ),
              if (_updatingAI)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showChatInfo,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_aiEnabled)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  color: Colors.yellow.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Colors.yellow[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🤖 AI Assistant is active in this chat',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.yellow[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return MessageBubble(
                            message: message,
                            onLongPress: () => _showMessageOptions(message),
                            formatTime: _formatTime,
                            getStatusIcon: _getStatusIcon,
                          );
                        },
                      ),
              ),

              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _showAttachmentMenu ? Icons.close : Icons.attach_file,
                          color: Colors.grey[700],
                        ),
                        onPressed: _showAttachmentOptions,
                      ),
                    ),

                    const SizedBox(width: 8.0),

                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        decoration: InputDecoration(
                          hintText: _aiEnabled
                              ? 'Type a message (AI assisted)...'
                              : 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),

                    const SizedBox(width: 8.0),

                    Container(
                      decoration: BoxDecoration(
                        color: _aiEnabled ? Colors.purple : Colors.blue,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _aiEnabled ? Icons.auto_awesome : Icons.send,
                          color: Colors.white,
                        ),
                        onPressed: _isSending || _isUploading
                            ? null
                            : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          AttachmentMenu(
            showAttachmentMenu: _showAttachmentMenu,
            onPickGallery: _pickFromGallery,
            onTakePhoto: _takePhoto,
            onPickVideo: _pickVideo,
            onRecordAudio: _recordAudio,
            onPickDocument: _pickDocument,
          ),

          if (_isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Uploading media...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _messageStreamSubscription.cancel();
    super.dispose();
  }
}
