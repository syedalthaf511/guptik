import 'package:flutter/material.dart';
import 'package:guptik/widgets/home/animated_nebula_background.dart';


// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class QuickRepliesScreen extends StatefulWidget {
  const QuickRepliesScreen({super.key});

  @override
  State<QuickRepliesScreen> createState() => _QuickRepliesScreenState();
}

class _QuickRepliesScreenState extends State<QuickRepliesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  
  // Quick replies data - starts empty, will be populated from database
  final List<Map<String, dynamic>> _quickReplies = [];

  List<String> get _categories {
    final categories = _quickReplies.map((reply) => reply['category'] as String).toSet().toList();
    categories.sort();
    // Provide default categories even when no replies exist
    final defaultCategories = ['Greetings', 'Information', 'Support', 'Orders', 'Other'];
    final allCategories = <String>{...categories, ...defaultCategories}.toList();
    allCategories.sort();
    return ['All', ...allCategories];
  }

  List<Map<String, dynamic>> get _filteredReplies {
    var filtered = _quickReplies.where((reply) {
      final matchesSearch = _searchController.text.isEmpty ||
          reply['title'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
          reply['content'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'All' || reply['category'] == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
    
    // Sort by usage count (most used first)
    filtered.sort((a, b) => (b['usage_count'] as int).compareTo(a['usage_count'] as int));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Quick Replies',
          style: TextStyle(
            color: _ancientGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: _ancientGold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _ancientGold),
            onPressed: () => _showCreateQuickReplyDialog(),
            tooltip: 'Create New Quick Reply',
          ),
        ],
      ),
      // THE FIX: Full screen box ensures the background stretches safely
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // The Shared Cinematic Nebula Background
            const Positioned.fill(child: AnimatedNebulaBackground()),
            
            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight), // Push content below transparent AppBar
                
                // Header Stats
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: _buildStatCard('Total Replies', _quickReplies.length.toString(), Icons.reply)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Categories', (_categories.length - 1).toString(), Icons.category)), // -1 to exclude 'All'
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Most Used', _quickReplies.isNotEmpty ? _quickReplies.reduce((a, b) => (a['usage_count'] as int) > (b['usage_count'] as int) ? a : b)['usage_count'].toString() : '0', Icons.trending_up)),
                    ],
                  ),
                ),
                
                // Search and Filter Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search quick replies...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.search, color: _ancientGold),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.5),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white54),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _ancientGold, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Category Filter
                      Row(
                        children: [
                          const Text(
                            'Category: ',
                            style: TextStyle(fontWeight: FontWeight.bold, color: _ancientGold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              dropdownColor: Colors.black,
                              icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
                              style: const TextStyle(color: Colors.white),
                              isExpanded: true, // THE FIX: Prevents text overflow in dropdown
                              initialValue: _selectedCategory,
                              onChanged: (value) => setState(() => _selectedCategory = value!),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.black.withValues(alpha: 0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: _ancientGold),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Quick Replies List
                Expanded(
                  child: _filteredReplies.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          itemCount: _filteredReplies.length,
                          itemBuilder: (context, index) {
                            final reply = _filteredReplies[index];
                            return _buildQuickReplyCard(reply);
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // THE FIX: Wrapped empty state in SingleChildScrollView to avoid bottom overflow on small screens
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _ancientGold.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Icon(
                Icons.reply_outlined,
                size: 64,
                color: _ancientGold.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchController.text.isEmpty && _selectedCategory == 'All' 
                  ? 'No quick replies created yet'
                  : 'No quick replies found',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _ancientGold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isEmpty && _selectedCategory == 'All'
                  ? 'Create your first quick reply to get started'
                  : 'Try adjusting your search or filter criteria',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isEmpty && _selectedCategory == 'All') ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showCreateQuickReplyDialog(),
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('Create First Quick Reply', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ancientGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _ancientGold.withValues(alpha: 0.1),
        border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _ancientGold, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplyCard(Map<String, dynamic> reply) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reply['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _ancientGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _ancientGold.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    reply['category'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: _ancientGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                reply['content'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.trending_up, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Used ${reply['usage_count']} times',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Created: ${reply['created_date']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // THE FIX: Flexible row prevents button overflow on narrow screens
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyReply(reply['content']),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ancientGold,
                      side: BorderSide(color: _ancientGold.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editQuickReply(reply),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ancientGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: IconButton(
                    onPressed: () => _deleteQuickReply(reply['id']),
                    icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                    tooltip: 'Delete',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyReply(String content) {
    // In a real app, you'd use Clipboard.setData(ClipboardData(text: content))
    // For now, we'll show a helpful message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Quick reply ready to copy: "${content.length > 50 ? '${content.substring(0, 50)}...' : content}"',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _ancientGold,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _editQuickReply(Map<String, dynamic> reply) {
    _showCreateQuickReplyDialog(editingReply: reply);
  }

  void _deleteQuickReply(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Quick Reply', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to delete this quick reply? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _quickReplies.removeWhere((reply) => reply['id'] == id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quick reply deleted successfully', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.greenAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCreateQuickReplyDialog({Map<String, dynamic>? editingReply}) {
    final titleController = TextEditingController(text: editingReply?['title'] ?? '');
    final contentController = TextEditingController(text: editingReply?['content'] ?? '');
    String selectedCategory = editingReply?['category'] ?? 'Greetings';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          editingReply != null ? 'Edit Quick Reply' : 'Create Quick Reply',
          style: const TextStyle(color: _ancientGold, fontWeight: FontWeight.bold),
        ),
        // THE FIX: SingleChildScrollView prevents keyboard overflow inside the dialog
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _ancientGold, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Content',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _ancientGold, width: 2),
                  ),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                dropdownColor: Colors.black,
                icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
                style: const TextStyle(color: Colors.white),
                initialValue: selectedCategory,
                isExpanded: true, // Prevents text overflow
                onChanged: (value) => selectedCategory = value!,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _ancientGold, width: 2),
                  ),
                ),
                items: ['Greetings', 'Information', 'Support', 'Orders', 'Other']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                setState(() {
                  if (editingReply != null) {
                    // Update existing reply
                    final index = _quickReplies.indexWhere((reply) => reply['id'] == editingReply['id']);
                    if (index != -1) {
                      _quickReplies[index] = {
                        ..._quickReplies[index],
                        'title': titleController.text,
                        'content': contentController.text,
                        'category': selectedCategory,
                      };
                    }
                  } else {
                    // Create new reply
                    final newReply = {
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleController.text,
                      'content': contentController.text,
                      'category': selectedCategory,
                      'usage_count': 0,
                      'created_date': DateTime.now().toString().split(' ')[0], // YYYY-MM-DD format
                    };
                    _quickReplies.add(newReply);
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      editingReply != null ? 'Quick reply updated successfully' : 'Quick reply created successfully',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.greenAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _ancientGold,
              foregroundColor: Colors.black,
            ),
            child: Text(editingReply != null ? 'Update' : 'Create', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}