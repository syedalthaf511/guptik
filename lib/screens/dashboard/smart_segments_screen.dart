import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class SmartSegmentsScreen extends StatefulWidget {
  const SmartSegmentsScreen({super.key});

  @override
  State<SmartSegmentsScreen> createState() => _SmartSegmentsScreenState();
}

class _SmartSegmentsScreenState extends State<SmartSegmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Smart segments data - starts empty
  final List<Map<String, dynamic>> _segments = [];

  List<Map<String, dynamic>> get _filteredSegments {
    if (_searchController.text.isEmpty) return _segments;
    
    return _segments.where((segment) {
      return segment['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
             segment['description'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Smart Segments',
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
            onPressed: () => _showCreateSegmentDialog(),
            tooltip: 'Create New Segment',
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
                      Expanded(child: _buildStatCard('Total Segments', _segments.length.toString(), Icons.group, Colors.blueAccent)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Active Segments', _segments.where((s) => s['is_active'] == true).length.toString(), Icons.check_circle, Colors.greenAccent)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Total Contacts', _segments.fold(0, (sum, segment) => sum + (segment['contact_count'] as int)).toString(), Icons.people, Colors.purpleAccent)),
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
                      hintText: 'Search smart segments...',
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
                
                // Segments List
                Expanded(
                  child: _filteredSegments.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          itemCount: _filteredSegments.length,
                          itemBuilder: (context, index) {
                            final segment = _filteredSegments[index];
                            return _buildSegmentCard(segment);
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
                Icons.group_work_outlined,
                size: 64,
                color: _ancientGold.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchController.text.isEmpty 
                  ? 'No smart segments yet'
                  : 'No segments found',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _ancientGold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isEmpty
                  ? 'Create smart segments to automatically group contacts based on criteria'
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
                onPressed: () => _showCreateSegmentDialog(),
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('Create First Segment', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildSegmentCard(Map<String, dynamic> segment) {
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _ancientGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _ancientGold.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(
                    Icons.group_work,
                    color: _ancientGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              segment['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: segment['is_active'] == true ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: segment['is_active'] == true ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              segment['is_active'] == true ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: segment['is_active'] == true ? Colors.greenAccent : Colors.grey[400],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${segment['contact_count']} contacts',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (segment['description']?.isNotEmpty == true) ...[
              Text(
                segment['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Criteria Display (Styled like a terminal block)
            if (segment['criteria']?.isNotEmpty == true) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _ancientGold.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_alt, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        Text(
                          'Segment Criteria:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...((segment['criteria'] as List).map((criteria) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.chevron_right, size: 14, color: _ancientGold),
                            const SizedBox(width: 4),
                            Text(
                              '${criteria['field']} ',
                              style: const TextStyle(color: Colors.blueAccent, fontFamily: 'monospace', fontSize: 13),
                            ),
                            Text(
                              '${criteria['operator']} ',
                              style: const TextStyle(color: Colors.purpleAccent, fontFamily: 'monospace', fontSize: 13),
                            ),
                            Text(
                              '${criteria['value']}',
                              style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList()),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Created: ${segment['created_date']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(Icons.update, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Updated: ${segment['last_refresh']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // THE FIX: Flexible row prevents button overflow on narrow screens
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _refreshSegment(segment['id']),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ancientGold,
                      side: BorderSide(color: _ancientGold.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _viewSegmentContacts(segment),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _editSegment(segment),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ancientGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      onPressed: () => _deleteSegment(segment['id']),
                      icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                      tooltip: 'Delete',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSegmentDialog({Map<String, dynamic>? editingSegment}) {
    final nameController = TextEditingController(text: editingSegment?['name'] ?? '');
    final descriptionController = TextEditingController(text: editingSegment?['description'] ?? '');
    bool isActive = editingSegment?['is_active'] ?? true;

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
            editingSegment != null ? 'Edit Smart Segment' : 'Create New Smart Segment',
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
                    labelText: 'Segment Name *',
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
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Theme(
                  data: ThemeData(
                    unselectedWidgetColor: Colors.white54,
                  ),
                  child: CheckboxListTile(
                    activeColor: _ancientGold,
                    checkColor: Colors.black,
                    title: const Text('Active Segment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Automatically update contacts based on criteria', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    value: isActive,
                    onChanged: (value) => setState(() => isActive = value ?? true),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _ancientGold.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _ancientGold.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Segment Criteria:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _ancientGold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add criteria to automatically include contacts in this segment. This is a preview - full criteria builder coming soon!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
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
                    if (editingSegment != null) {
                      final index = _segments.indexWhere((segment) => segment['id'] == editingSegment['id']);
                      if (index != -1) {
                        _segments[index] = {
                          ..._segments[index],
                          'name': nameController.text,
                          'description': descriptionController.text,
                          'is_active': isActive,
                          'last_refresh': DateTime.now().toString().split(' ')[0],
                        };
                      }
                    } else {
                      _segments.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': nameController.text,
                        'description': descriptionController.text,
                        'is_active': isActive,
                        'contact_count': 0,
                        'created_date': DateTime.now().toString().split(' ')[0],
                        'last_refresh': DateTime.now().toString().split(' ')[0],
                        'criteria': [], // Will be populated when criteria builder is implemented
                      });
                    }
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        editingSegment != null ? 'Segment updated successfully' : 'Segment created successfully',
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
              child: Text(editingSegment != null ? 'Update' : 'Create', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshSegment(String id) {
    setState(() {
      final index = _segments.indexWhere((segment) => segment['id'] == id);
      if (index != -1) {
        _segments[index]['last_refresh'] = DateTime.now().toString().split(' ')[0];
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Segment refreshed successfully', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.greenAccent,
      ),
    );
  }

  void _viewSegmentContacts(Map<String, dynamic> segment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View contacts in "${segment['name']}" - Coming soon!', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _editSegment(Map<String, dynamic> segment) {
    _showCreateSegmentDialog(editingSegment: segment);
  }

  void _deleteSegment(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Smart Segment', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to delete this smart segment? This action cannot be undone.',
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
                _segments.removeWhere((segment) => segment['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Segment deleted successfully', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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