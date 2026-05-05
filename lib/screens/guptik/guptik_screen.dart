import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:guptik/services/guptik/mobile_ollama_service.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class GuptikScreen extends StatefulWidget {
  final String tunnelUrl; // Pass this from Supabase when they click the icon

  const GuptikScreen({super.key, required this.tunnelUrl});

  @override
  State<GuptikScreen> createState() => _GuptikScreenState();
}

class _GuptikScreenState extends State<GuptikScreen> {
  late MobileOllamaService _ollamaService;

  final TextEditingController _textController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  // State

  String _sessionId = const Uuid().v4();

  List<Map<String, String>> _messages = [];

  List<Map<String, dynamic>> _sessions = []; // Stores history from desktop

  String _selectedModel = 'llama3'; // Default fallback

  List<String> _availableModels = [];

  bool _isLoading = false;

  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();

    _ollamaService = MobileOllamaService(tunnelUrl: widget.tunnelUrl);

    _loadModels();

    _loadSessions(); // Fetch history on startup
  }

  // --- API ROUTE: Get Installed Models ---

  Future<void> _loadModels() async {
    final models = await _ollamaService.getInstalledModels();

    if (models.isNotEmpty && mounted) {
      setState(() {
        _availableModels = models;

        _selectedModel = models.first;
      });
    }
  }

  // --- API ROUTE: Load Chat Sessions for Sidebar ---

  Future<void> _loadSessions() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.tunnelUrl}/api/sessions'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _sessions = List<Map<String, dynamic>>.from(data);
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading sessions: $e");
    }
  }

  // --- API ROUTE: Load Specific Chat History ---

  Future<void> _loadHistory(String sessionId) async {
    setState(() => _isLoadingHistory = true);

    try {
      final response = await http.get(
        Uri.parse('${widget.tunnelUrl}/api/history/$sessionId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _sessionId = sessionId;

          _messages = data
              .map(
                (m) => {
                  'role': m['role'].toString(),
                  'content': m['content'].toString(),
                },
              )
              .toList();
        });

        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  // --- API ROUTE: Save Message to Desktop ---

  Future<void> _saveMessageToDesktop(String role, String content) async {
    try {
      await http.post(
        Uri.parse('${widget.tunnelUrl}/api/chat/save'),

        headers: {'Content-Type': 'application/json'},

        body: jsonEncode({
          'sessionId': _sessionId,
          'role': role,
          'content': content,
          'model': _selectedModel,
        }),
      );
    } catch (e) {
      debugPrint("Error saving message: $e");
    }
  }

  void _createNewChat() {
    setState(() {
      _sessionId = const Uuid().v4();
      _messages = [];
    });

    Navigator.pop(context); // Close the drawer
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
    final text = _textController.text.trim();

    if (text.isEmpty || _isLoading) return;

    _textController.clear();

    // 1. Add User Message to UI

    setState(() {
      _messages.add({"role": "user", "content": text});
      _messages.add({"role": "assistant", "content": ""}); // Placeholder
      _isLoading = true;
    });

    _scrollToBottom();

    // 2. Save User Message to Desktop DB

    await _saveMessageToDesktop('user', text);

    // Prepare history for API (excluding the empty placeholder)

    final apiHistory = _messages.sublist(0, _messages.length - 1);

    try {
      final stream = _ollamaService.generateChatStream(
        model: _selectedModel,
        history: apiHistory,
      );

      await for (final chunk in stream) {
        if (!mounted) break;

        setState(() {
          _messages.last["content"] = _messages.last["content"]! + chunk;
        });

        _scrollToBottom();
      }

      // 3. Save Assistant Message to Desktop DB once streaming finishes

      await _saveMessageToDesktop('assistant', _messages.last["content"]!);

      // 4. Refresh the sidebar to show the new chat

      _loadSessions();
    } catch (e) {
      setState(() {
        _messages.last["content"] =
            "Connection error. Make sure your desktop tunnel is active.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,

      // 🛡️ The AppBar with the Hamburger Menu
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: _ancientGold,
        ), // Hamburger icon color
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
        ),
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _availableModels.contains(_selectedModel)
                ? _selectedModel
                : null,
            dropdownColor: Colors.black,
            style: const TextStyle(
              color: _ancientGold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            icon: const Icon(Icons.keyboard_arrow_down, color: _ancientGold),
            items: _availableModels.map((model) {
              return DropdownMenuItem(
                value: model, 
                child: Text(model, style: const TextStyle(color: Colors.white))
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedModel = val);
            },
            hint: Text(
              "Select Model",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ),
        centerTitle: true,
      ),

      // 🛡️ The Slide-out Sidebar for Chat History
      drawer: Drawer(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton.icon(
                  onPressed: _createNewChat,
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text(
                    "New Chat",
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ancientGold,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: _ancientGold, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Chat History",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(color: _ancientGold.withValues(alpha: 0.2)),

              Expanded(
                child: _sessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, color: _ancientGold.withValues(alpha: 0.5), size: 48),
                            const SizedBox(height: 16),
                            Text(
                              "No history yet.",
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final s = _sessions[index];
                          final isActive = s['id'] == _sessionId;

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? _ancientGold.withValues(alpha: 0.15) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isActive ? Border.all(color: _ancientGold.withValues(alpha: 0.5)) : Border.all(color: Colors.transparent),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              leading: Icon(
                                Icons.chat, 
                                color: isActive ? _ancientGold : Colors.grey[600],
                                size: 20,
                              ),
                              title: Text(
                                s['title'],
                                style: TextStyle(
                                  color: isActive ? _ancientGold : Colors.white70,
                                  fontSize: 14,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              selected: isActive,
                              onTap: () {
                                _loadHistory(s['id']);
                                Navigator.pop(context); // Close drawer
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),

      // THE FIX: Full screen box ensures the background stretches safely without bottom overflow
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // The Shared Cinematic Nebula Background
            const Positioned.fill(child: DynamicAppBackground()),
            
            Column(
              children: [
                // Messages Area
                Expanded(
                  child: _isLoadingHistory
                      ? const Center(
                          child: CircularProgressIndicator(color: _ancientGold),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 110, 16, 20), // Top padding for AppBar
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isUser = msg["role"] == "user";

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: isUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (!isUser) ...[
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: _ancientGold.withValues(alpha: 0.5), width: 1.5),
                                        color: _ancientGold.withValues(alpha: 0.15),
                                      ),
                                      child: const CircleAvatar(
                                        backgroundColor: Colors.transparent,
                                        radius: 16,
                                        child: Icon(
                                          Icons.smart_toy,
                                          color: _ancientGold,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],

                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isUser 
                                            ? _ancientGold.withValues(alpha: 0.15) 
                                            : Colors.black.withValues(alpha: 0.6),
                                        border: Border.all(
                                          color: isUser 
                                              ? _ancientGold.withValues(alpha: 0.4) 
                                              : Colors.white10,
                                        ),
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: Radius.circular(isUser ? 16 : 4),
                                          bottomRight: Radius.circular(isUser ? 4 : 16),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        msg["content"] ?? "",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                // Input Area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    border: Border(top: BorderSide(color: _ancientGold.withValues(alpha: 0.3), width: 1)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _textController,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 4,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: "Message Guptik...",
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: _isLoading ? Colors.grey[800] : _ancientGold,
                              shape: BoxShape.circle,
                              boxShadow: _isLoading ? null : [
                                BoxShadow(
                                  color: _ancientGold.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              radius: 24,
                              child: _isLoading 
                                  ? const SizedBox(
                                      width: 20, height: 20, 
                                      child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)
                                    ) 
                                  : const Icon(
                                      Icons.arrow_upward,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}