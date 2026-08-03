import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guptik/services/guptik/mobile_ollama_service.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class GuptikScreen extends StatefulWidget {
  final String tunnelUrl;

  const GuptikScreen({super.key, required this.tunnelUrl});

  @override
  State<GuptikScreen> createState() => _GuptikScreenState();
}

class _GuptikScreenState extends State<GuptikScreen> {
  late MobileOllamaService _ollamaService;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _sessionId = const Uuid().v4();
  List<Map<String, String>> _messages = [];
  List<Map<String, dynamic>> _sessions = [];
  
  String _aiProvider = 'OpenRouter';
  String _selectedModel = 'meta-llama/llama-3-8b-instruct';
  String _apiKey = '';
  String _endpointUrl = 'https://openrouter.ai/api/v1/chat/completions';
  List<String> _availableModels = [];

  bool _isLoading = false;
  bool _isLoadingHistory = false;
  bool _isFetchingModels = false;

  @override
  void initState() {
    super.initState();
    _ollamaService = MobileOllamaService(tunnelUrl: widget.tunnelUrl);
    _syncWithDesktopAndLoad();
    _loadSessions();
  }

  Future<void> _syncWithDesktopAndLoad() async {
    final desktopConfig = await _ollamaService.fetchDesktopAiConfig();
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      if (desktopConfig.isNotEmpty) {
        final serverProvider = desktopConfig['provider']?.toString() ?? '';
        final serverEndpoint = desktopConfig['endpoint_url']?.toString() ?? '';
        final serverModel = desktopConfig['model_name']?.toString() ?? '';
        final serverKey = desktopConfig['api_key']?.toString() ?? '';

        _aiProvider = serverProvider.isNotEmpty ? serverProvider : (prefs.getString('mobile_ai_provider') ?? 'OpenRouter');
        _endpointUrl = serverEndpoint.isNotEmpty ? serverEndpoint : (prefs.getString('mobile_ai_endpoint') ?? 'https://openrouter.ai/api/v1/chat/completions');
        _selectedModel = serverModel.isNotEmpty ? serverModel : (prefs.getString('mobile_ai_model') ?? 'meta-llama/llama-3-8b-instruct');
        _apiKey = serverKey.isNotEmpty ? serverKey : (prefs.getString('mobile_ai_api_key') ?? '');
      } else {
        _aiProvider = prefs.getString('mobile_ai_provider') ?? 'OpenRouter';
        _endpointUrl = prefs.getString('mobile_ai_endpoint') ?? 'https://openrouter.ai/api/v1/chat/completions';
        _apiKey = prefs.getString('mobile_ai_api_key') ?? '';
        _selectedModel = prefs.getString('mobile_ai_model') ?? 'meta-llama/llama-3-8b-instruct';
      }
    });

    _fetchModelsForProvider(_aiProvider);
  }

  Future<void> _fetchModelsForProvider(String provider) async {
    setState(() => _isFetchingModels = true);
    
    final models = await _ollamaService.getInstalledModels(provider);
    
    if (mounted) {
      setState(() {
        _availableModels = models;
        if (!_availableModels.contains(_selectedModel) && _selectedModel.isNotEmpty) {
          _availableModels.insert(0, _selectedModel);
        }
        _isFetchingModels = false;
      });
    }
  }

  Future<void> _saveSettings(String provider, String model, String key, String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mobile_ai_provider', provider);
    await prefs.setString('mobile_ai_model', model);
    await prefs.setString('mobile_ai_api_key', key);
    await prefs.setString('mobile_ai_endpoint', endpoint);

    setState(() {
      _aiProvider = provider;
      _selectedModel = model;
      _apiKey = key;
      _endpointUrl = endpoint;
    });

    await _ollamaService.updateDesktopAiConfig(
      provider: provider, 
      model: model, 
      apiKey: key, 
      endpointUrl: endpoint,
    );
  }

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
              .map((m) => {
                    'role': m['role'].toString(),
                    'content': m['content'].toString(),
                  })
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
    Navigator.pop(context);
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

    setState(() {
      _messages.add({"role": "user", "content": text});
      _messages.add({"role": "assistant", "content": ""});
      _isLoading = true;
    });

    _scrollToBottom();
    await _saveMessageToDesktop('user', text);

    final apiHistory = _messages.sublist(0, _messages.length - 1);

    try {
      final stream = _ollamaService.generateChatStream(
        provider: _aiProvider,
        model: _selectedModel,
        history: apiHistory,
        apiKey: _apiKey,
        endpointUrl: _endpointUrl,
      );

      await for (final chunk in stream) {
        if (!mounted) break;
        setState(() {
          _messages.last["content"] = _messages.last["content"]! + chunk;
        });
        _scrollToBottom();
      }

      await _saveMessageToDesktop('assistant', _messages.last["content"]!);
      _loadSessions();
    } catch (e) {
      setState(() {
        _messages.last["content"] = "Connection error. Check your API settings.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSettingsDialog() {
    String tempProvider = _aiProvider;
    String tempModel = _selectedModel;
    String tempKey = _apiKey;
    String tempEndpoint = _endpointUrl;
    List<String> tempModelsList = List.from(_availableModels);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Mobile AI Settings", style: TextStyle(color: Colors.white, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.sync, color: _ancientGold, size: 20),
                tooltip: "Sync from Desktop",
                onPressed: () async {
                  await _syncWithDesktopAndLoad();
                  setDialogState(() {
                    tempProvider = _aiProvider;
                    tempModel = _selectedModel;
                    tempKey = _apiKey;
                    tempEndpoint = _endpointUrl;
                    tempModelsList = List.from(_availableModels);
                  });
                },
              )
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Provider", style: TextStyle(color: Colors.grey, fontSize: 12)),
                DropdownButton<String>(
                  value: tempProvider,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0F172A),
                  style: const TextStyle(color: _ancientGold),
                  items: const [
                    DropdownMenuItem(value: "OpenRouter", child: Text("OpenRouter")),
                    DropdownMenuItem(value: "OpenAI", child: Text("OpenAI")),
                    DropdownMenuItem(value: "Anthropic", child: Text("Anthropic")),
                    DropdownMenuItem(value: "Gemini", child: Text("Google Gemini")),
                    DropdownMenuItem(value: "DeepSeek", child: Text("DeepSeek")),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      setDialogState(() {
                        tempProvider = val;
                        _isFetchingModels = true;
                      });
                      
                      final newModels = await _ollamaService.getInstalledModels(val);
                      
                      setDialogState(() {
                        tempModelsList = newModels;
                        _isFetchingModels = false;
                        if (!tempModelsList.contains(tempModel) && tempModelsList.isNotEmpty) {
                          tempModel = tempModelsList.first;
                        } else if (!tempModelsList.contains(tempModel)) {
                          tempModelsList.insert(0, tempModel);
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                const Text("Model ID", style: TextStyle(color: Colors.grey, fontSize: 12)),
                _isFetchingModels 
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(color: _ancientGold, backgroundColor: Colors.black45),
                    )
                  : DropdownButton<String>(
                      value: tempModelsList.contains(tempModel) ? tempModel : (tempModelsList.isNotEmpty ? tempModelsList.first : null),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white),
                      items: tempModelsList.map((modelString) {
                        return DropdownMenuItem(
                          value: modelString,
                          child: Text(
                            modelString, 
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            tempModel = val;
                          });
                        }
                      },
                    ),
                const SizedBox(height: 12),

                const Text("API Key", style: TextStyle(color: Colors.grey, fontSize: 12)),
                TextField(
                  controller: TextEditingController(text: tempKey),
                  onChanged: (val) => tempKey = val,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Enter API Key...", 
                    hintStyle: TextStyle(color: Colors.white24),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _ancientGold)),
                  ),
                ),
                const SizedBox(height: 12),

                const Text("Endpoint URL", style: TextStyle(color: Colors.grey, fontSize: 12)),
                TextField(
                  controller: TextEditingController(text: tempEndpoint),
                  onChanged: (val) => tempEndpoint = val,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: "https://openrouter.ai/api/v1/chat/completions", 
                    hintStyle: TextStyle(color: Colors.white24),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _ancientGold)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _ancientGold),
              onPressed: () {
                _saveSettings(tempProvider, tempModel, tempKey, tempEndpoint);
                Navigator.pop(ctx);
              },
              child: const Text("Save & Sync", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
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
        title: Column(
          children: [
            Text(_selectedModel, style: const TextStyle(color: _ancientGold, fontSize: 13, fontWeight: FontWeight.bold)),
            Text(_aiProvider, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: _ancientGold),
            onPressed: _showSettingsDialog,
          )
        ],
      ),
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
                  label: const Text("New Chat", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: _ancientGold, minimumSize: const Size(double.infinity, 50)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final s = _sessions[index];
                    final isActive = s['id'] == _sessionId;
                    return ListTile(
                      title: Text(s['title'], style: TextStyle(color: isActive ? _ancientGold : Colors.white70)),
                      onTap: () {
                        _loadHistory(s['id']);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            const Positioned.fill(child: DynamicAppBackground()),
            Column(
              children: [
                Expanded(
                  child: _isLoadingHistory
                      ? const Center(child: CircularProgressIndicator(color: _ancientGold))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 110, 16, 20),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isUser = msg["role"] == "user";
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isUser ? _ancientGold.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isUser ? _ancientGold.withValues(alpha: 0.4) : Colors.white10),
                                      ),
                                      child: Text(msg["content"] ?? "", style: const TextStyle(color: Colors.white, fontSize: 15)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    border: Border(top: BorderSide(color: _ancientGold.withValues(alpha: 0.3))),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 4,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: "Message Guptik...",
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: _ancientGold),
                          onPressed: _sendMessage,
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