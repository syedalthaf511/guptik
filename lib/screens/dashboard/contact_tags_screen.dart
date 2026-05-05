import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
  

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class ContactTagsScreen extends StatefulWidget {
  const ContactTagsScreen({super.key});

  @override
  State<ContactTagsScreen> createState() => _ContactTagsScreenState();
}

class _ContactTagsScreenState extends State<ContactTagsScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Tags data - starts empty
  final List<Map<String, dynamic>> _tags = [];

  List<Map<String, dynamic>> get _filteredTags {
    if (_searchController.text.isEmpty) return _tags;
    
    return _tags.where((tag) {
      return tag['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
             tag['description'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Contact Tags',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _ancientGold,
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
            onPressed: () => _showCreateTagDialog(),
            tooltip: 'Create New Tag',
          ),
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
            
            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight), // Push below transparent AppBar
                
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
                      Expanded(child: _buildStatCard('Total Tags', _tags.length.toString(), Icons.local_offer, Colors.purpleAccent)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Tagged Contacts', _tags.fold(0, (sum, tag) => sum + (tag['contact_count'] as int)).toString(), Icons.people, Colors.blueAccent)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Most Used', _tags.isNotEmpty ? _tags.reduce((a, b) => (a['contact_count'] as int) > (b['contact_count'] as int) ? a : b)['contact_count'].toString() : '0', Icons.trending_up, Colors.greenAccent)),
                    ],
                  ),
                ),
                
                // Search Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search tags...',
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
                ),
                
                // Tags Grid
                Expanded(
                  child: _filteredTags.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredTags.length,
                          itemBuilder: (context, index) {
                            final tag = _filteredTags[index];
                            return _buildTagCard(tag);
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

  // THE FIX: Wrapped in SingleChildScrollView to prevent bottom overflow
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
                Icons.local_offer_outlined,
                size: 64,
                color: _ancientGold.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchController.text.isEmpty 
                  ? 'No tags created yet'
                  : 'No tags found',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _ancientGold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isEmpty
                  ? 'Create tags to organize and categorize contacts'
                  : 'Try adjusting your search criteria',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isEmpty) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showCreateTagDialog(),
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('Create First Tag', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
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
          Icon(icon, color: iconColor, size: 28),
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

  Widget _buildTagCard(Map<String, dynamic> tag) {
    final color = Color(tag['color'] ?? 0xFF17A2B8);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.2),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Icon(
                    Icons.local_offer,
                    color: color,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Theme(
                  data: Theme.of(context).copyWith(
                    cardColor: Colors.black,
                    iconTheme: const IconThemeData(color: Colors.white70),
                  ),
                  child: PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: _ancientGold.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editTag(tag);
                          break;
                        case 'delete':
                          _deleteTag(tag['id']);
                          break;
                        case 'view_contacts':
                          _viewTaggedContacts(tag);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view_contacts',
                        child: ListTile(
                          leading: Icon(Icons.people, color: Colors.blueAccent),
                          title: Text('View Contacts', style: TextStyle(color: Colors.white)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: _ancientGold),
                          title: Text('Edit', style: TextStyle(color: Colors.white)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.redAccent),
                          title: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tag['name'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (tag['description']?.isNotEmpty == true) ...[
              Expanded(
                child: Text(
                  tag['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else
              const Spacer(),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  '${tag['contact_count']} contacts',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[300],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTagDialog({Map<String, dynamic>? editingTag}) {
    final nameController = TextEditingController(text: editingTag?['name'] ?? '');
    final descriptionController = TextEditingController(text: editingTag?['description'] ?? '');
    int selectedColor = editingTag?['color'] ?? 0xFF17A2B8;

    final colors = [
      0xFF17A2B8, // Default blue
      0xFFE74C3C, // Red
      0xFF2ECC71, // Green
      0xFFF39C12, // Orange
      0xFF9B59B6, // Purple
      0xFF1ABC9C, // Teal
      0xFFD4AF37, // Ancient Gold
      0xFFE67E22, // Orange
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: _ancientGold, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            editingTag != null ? 'Edit Tag' : 'Create New Tag',
            style: const TextStyle(color: _ancientGold, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Tag Name *',
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
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
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
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose Color:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: colors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : Border.all(color: Colors.white24, width: 1),
                          boxShadow: isSelected
                              ? [BoxShadow(color: Color(color).withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 24)
                            : null,
                      ),
                    );
                  }).toList(),
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
                if (nameController.text.isNotEmpty) {
                  this.setState(() {
                    if (editingTag != null) {
                      final index = _tags.indexWhere((tag) => tag['id'] == editingTag['id']);
                      if (index != -1) {
                        _tags[index] = {
                          ..._tags[index],
                          'name': nameController.text,
                          'description': descriptionController.text,
                          'color': selectedColor,
                          'updated_date': DateTime.now().toString().split(' ')[0],
                        };
                      }
                    } else {
                      _tags.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': nameController.text,
                        'description': descriptionController.text,
                        'color': selectedColor,
                        'contact_count': 0,
                        'created_date': DateTime.now().toString().split(' ')[0],
                        'updated_date': DateTime.now().toString().split(' ')[0],
                      });
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        editingTag != null ? 'Tag updated successfully' : 'Tag created successfully',
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
              child: Text(editingTag != null ? 'Update' : 'Create', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _viewTaggedContacts(Map<String, dynamic> tag) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View contacts with tag "${tag['name']}" - Coming soon!', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _editTag(Map<String, dynamic> tag) {
    _showCreateTagDialog(editingTag: tag);
  }

  void _deleteTag(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Tag', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to delete this tag? It will be removed from all contacts.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _tags.removeWhere((tag) => tag['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tag deleted successfully', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.greenAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.black),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}