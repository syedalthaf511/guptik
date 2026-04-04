import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';

class AutoReplyDialog extends StatefulWidget {
  final String postId;
  final SocialPlatform platform;

  const AutoReplyDialog({
    super.key,
    required this.postId,
    required this.platform,
  });

  @override
  State<AutoReplyDialog> createState() => _AutoReplyDialogState();
}

class _AutoReplyDialogState extends State<AutoReplyDialog> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Form Controllers
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _dmResponseController = TextEditingController();
  final TextEditingController _commentReplyController = TextEditingController();
  final TextEditingController _aiPromptController = TextEditingController();

  // Toggles & Dropdowns
  String _autoCommentStatus = 'M';
  bool _allComments = false;
  String? _selectedAiAgentId;
  String _selectedAgentTab = 'Name';

  // Data Lists
  List<Map<String, dynamic>> _aiAgents = [];
  List<Map<String, dynamic>> _postComments = [];
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🔍 AutoReplyDialog - Platform received: ${widget.platform}');
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    // Determine table name based on platform
    final String configTableName = widget.platform == SocialPlatform.instagram
        ? 'ig_auto_comment_posts'
        : 'fb_auto_comment_posts';
    final String commentsTableName = widget.platform == SocialPlatform.instagram
        ? 'ig_comments_responces'
        : 'fb_comments_responces';

    debugPrint(
      '📊 Using Table: $configTableName for platform ${widget.platform}',
    );

    // 1. Fetch AI Agents
    try {
      final agentsResponse = await Supabase.instance.client
          .from('ai_agents')
          .select('id, name, model, system_prompt');
      setState(() {
        _aiAgents = List<Map<String, dynamic>>.from(agentsResponse);
      });
    } catch (e) {
      debugPrint("Warning: Could not load AI Agents: $e");
    }

    // 2. Fetch Existing Post Config
    try {
      final response = await Supabase.instance.client
          .from(configTableName)
          .select()
          .eq('post_id', widget.postId)
          .maybeSingle();

      if (response != null) {
        Map<String, dynamic> autoReplyData = {};
        final rawAutoReply = response['auto_reply'];

        if (rawAutoReply != null) {
          if (rawAutoReply is String) {
            try {
              autoReplyData = json.decode(rawAutoReply);
            } catch (e) {
              debugPrint("JSON Decode Error: $e");
            }
          } else if (rawAutoReply is Map) {
            autoReplyData = Map<String, dynamic>.from(rawAutoReply);
          }
        }

        _keywordController.text = autoReplyData['keywords']?.toString() ?? '';
        _dmResponseController.text = autoReplyData['respond']?.toString() ?? '';
        _commentReplyController.text =
            response['comment_respond']?.toString() ?? '';
        _aiPromptController.text =
            response['ai_agent_prompt']?.toString() ?? '';

        _allComments = response['all_comments'] ?? false;
        _selectedAiAgentId = response['ai_agent_id']?.toString();
        _autoCommentStatus = (response['comment_ai_response'] == true)
            ? 'AI'
            : 'M';

        if (_allComments) {
          _fetchCommentsForPost(commentsTableName);
        }
      }
    } catch (e) {
      debugPrint("Error loading existing config: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCommentsForPost(String commentsTableName) async {
    setState(() => _isLoadingComments = true);
    try {
      final commentsResponse = await Supabase.instance.client
          .from(commentsTableName)
          .select('sender_name, context, direction')
          .eq('post_id', widget.postId)
          .order('created_at', ascending: false);

      setState(() {
        _postComments = List<Map<String, dynamic>>.from(commentsResponse);
      });
    } catch (e) {
      debugPrint("Error fetching comments: $e");
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      setState(() => _isSaving = false);
      return;
    }

    // Determine table name based on platform
    final String configTableName = widget.platform == SocialPlatform.instagram
        ? 'ig_auto_comment_posts'
        : 'fb_auto_comment_posts';

    debugPrint(
      '💾 Saving to table: $configTableName (platform: ${widget.platform})',
    );

    try {
      if (_autoCommentStatus == 'X') {
        await Supabase.instance.client
            .from(configTableName)
            .delete()
            .eq('post_id', widget.postId);
      } else {
        final autoReplyJson = {
          "keywords": _keywordController.text.trim(),
          "respond": _dmResponseController.text.trim(),
        };

        await Supabase.instance.client.from(configTableName).upsert({
          'user_id': userId,
          'post_id': widget.postId,
          'auto_reply': autoReplyJson,
          'comment_respond': _commentReplyController.text.trim(),
          'ai_agent_prompt': _aiPromptController.text.trim(),
          'comment_ai_response': _autoCommentStatus == 'AI',
          'all_comments': _allComments,
          'ai_agent_id': _selectedAiAgentId,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'post_id');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error saving config: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildBoxTab(String title) {
    final isSelected = _selectedAgentTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedAgentTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF1877F2) : Colors.blueGrey,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final selectedAgent = _aiAgents
        .where((a) => a['id'].toString() == _selectedAiAgentId)
        .firstOrNull;
    String detailTextToShow = "";
    if (selectedAgent != null) {
      if (_selectedAgentTab == 'Name') {
        detailTextToShow = "Name: ${selectedAgent['name'] ?? 'N/A'}";
      } else if (_selectedAgentTab == 'Model') {
        detailTextToShow = "Model: ${selectedAgent['model'] ?? 'N/A'}";
      } else if (_selectedAgentTab == 'Prompt') {
        detailTextToShow = "Prompt: ${selectedAgent['system_prompt'] ?? 'N/A'}";
      }
    }

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          Text(
            'Post ID: ${widget.postId}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField("Keyword Secret", _keywordController),
            _buildTextField("DM Response", _dmResponseController, lines: 2),
            _buildTextField("Comment Reply", _commentReplyController, lines: 2),
            _buildTextField("AI Agent Prompt", _aiPromptController, lines: 2),

            const SizedBox(height: 10),
            const Text(
              "AUTO COMMENT STATUS",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                _statusButton('M', 'Manual'),
                const SizedBox(width: 8),
                _statusButton('AI', 'AI Mode'),
                const SizedBox(width: 8),
                _statusButton('X', 'Off', color: Colors.red),
              ],
            ),

            // ---------------------------------------------------------
            // ✅ UPDATED: "All Comments" Label + Toggle Switch Row
            // ---------------------------------------------------------
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "All Comments",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Switch(
                  value: _allComments,
                  activeThumbColor: const Color(0xFF1877F2),
                  onChanged: (val) {
                    setState(() => _allComments = val);
                    if (val && _postComments.isEmpty) {
                      _fetchCommentsForPost(
                        widget.platform == SocialPlatform.instagram
                            ? 'ig_comments_responces'
                            : 'fb_comments_responces',
                      );
                    }
                  },
                ),
              ],
            ),

            if (_allComments) ...[
              Container(
                height: 120,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoadingComments
                    ? const Center(child: CircularProgressIndicator())
                    : _postComments.isEmpty
                    ? const Center(
                        child: Text(
                          "No comments found.",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _postComments.length,
                        itemBuilder: (context, index) {
                          final comment = _postComments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        "${comment['sender_name'] ?? 'User'}: ",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: comment['context'] ?? ''),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],

            const SizedBox(height: 16),

            if (_aiAgents.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: "AI Agent ID",
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedAiAgentId,
                items: _aiAgents
                    .map(
                      (agent) => DropdownMenuItem<String>(
                        value: agent['id'].toString(),
                        child: Text(agent['id'].toString()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedAiAgentId = val),
              ),

              if (selectedAgent != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueGrey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade100.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildBoxTab('Name'),
                            _buildBoxTab('Model'),
                            _buildBoxTab('Prompt'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          detailTextToShow,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blueGrey[800],
                            fontStyle: _selectedAgentTab == 'Prompt'
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveConfig,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE1306C),
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text("Save"),
        ),
      ],
    );
  }

  Widget _statusButton(
    String status,
    String label, {
    Color color = const Color(0xFF1877F2),
  }) {
    final isSelected = _autoCommentStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _autoCommentStatus = status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : Colors.grey[400]!),
          ),
          child: Center(
            child: Text(
              status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}