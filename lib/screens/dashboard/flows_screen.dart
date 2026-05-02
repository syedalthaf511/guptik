import 'package:flutter/material.dart';
import 'package:guptik/widgets/home/animated_nebula_background.dart';


// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class FlowsScreen extends StatefulWidget {
  const FlowsScreen({super.key});

  @override
  State<FlowsScreen> createState() => _FlowsScreenState();
}

class _FlowsScreenState extends State<FlowsScreen> {
  final List<Map<String, dynamic>> _flows = [
    {
      'id': '1',
      'name': 'Customer Support Flow',
      'description': 'Handle common customer support inquiries',
      'status': 'Active',
      'triggers': ['support', 'help', 'issue'],
      'steps': 5,
      'created_at': DateTime.now().subtract(const Duration(days: 7)),
      'responses': 234,
    },
    {
      'id': '2',
      'name': 'Product Inquiry Flow',
      'description': 'Guide customers through product selection',
      'status': 'Draft',
      'triggers': ['product', 'buy', 'purchase'],
      'steps': 8,
      'created_at': DateTime.now().subtract(const Duration(days: 3)),
      'responses': 0,
    },
    {
      'id': '3',
      'name': 'Appointment Booking Flow',
      'description': 'Schedule appointments with customers',
      'status': 'Active',
      'triggers': ['appointment', 'booking', 'schedule'],
      'steps': 6,
      'created_at': DateTime.now().subtract(const Duration(days: 14)),
      'responses': 156,
    },
  ];

  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Flows', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
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
            onPressed: _createNewFlow,
          ),
        ],
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // The Shared Cinematic Nebula Background
            const Positioned.fill(child: AnimatedNebulaBackground()),
            
            Column(
              children: [
                // Header Section
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 100, 16, 0),
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_tree, color: _ancientGold, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Conversation Flows',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _ancientGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Design automated conversation flows to engage with your customers effectively. Create interactive experiences that guide customers through support, sales, and booking processes.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[400], height: 1.4),
                      ),
                    ],
                  ),
                ),

                // Search and Filter Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search flows...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon: const Icon(Icons.search, color: _ancientGold),
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
                              borderSide: const BorderSide(color: _ancientGold, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          dropdownColor: Colors.black,
                          icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          value: _selectedFilter,
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: ['All', 'Active', 'Draft', 'Paused'].map((filter) {
                            return DropdownMenuItem(
                              value: filter,
                              child: Text(filter, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedFilter = value!),
                        ),
                      ),
                    ],
                  ),
                ),

                // Flows List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Padding to avoid FAB overlap
                    itemCount: _getFilteredFlows().length,
                    itemBuilder: (context, index) {
                      final flow = _getFilteredFlows()[index];
                      return _buildFlowCard(flow);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewFlow,
        backgroundColor: _ancientGold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredFlows() {
    List<Map<String, dynamic>> filtered = _flows;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((flow) {
        return flow['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
               flow['description'].toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((flow) => flow['status'] == _selectedFilter).toList();
    }

    return filtered;
  }

  Widget _buildFlowCard(Map<String, dynamic> flow) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flow['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        flow['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(flow['status']).withValues(alpha: 0.15),
                    border: Border.all(color: _getStatusColor(flow['status']).withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    flow['status'],
                    style: TextStyle(
                      color: _getStatusColor(flow['status']),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Flow Stats
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.linear_scale, size: 16, color: Colors.grey[300]),
                ),
                const SizedBox(width: 8),
                Text(
                  '${flow['steps']} steps',
                  style: TextStyle(fontSize: 13, color: Colors.grey[300], fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[300]),
                ),
                const SizedBox(width: 8),
                Text(
                  '${flow['responses']} responses',
                  style: TextStyle(fontSize: 13, color: Colors.grey[300], fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Triggers
            if (flow['triggers'] != null && flow['triggers'].isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text(
                    'Triggers:',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold),
                  ),
                  ...flow['triggers'].map<Widget>((trigger) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _ancientGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      trigger,
                      style: const TextStyle(color: _ancientGold, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  )).toList(),
                ],
              ),
              const SizedBox(height: 20),
            ],
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editFlow(flow),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ancientGold,
                      side: BorderSide(color: _ancientGold.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _testFlow(flow),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Test', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ancientGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _duplicateFlow(flow),
                  icon: const Icon(Icons.copy, color: Colors.white70),
                  tooltip: 'Duplicate',
                ),
                IconButton(
                  onPressed: () => _deleteFlow(flow),
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.greenAccent;
      case 'Draft':
        return Colors.orangeAccent;
      case 'Paused':
        return Colors.grey[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  void _createNewFlow() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Create New Flow', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        content: const Text(
          'Flow builder is coming soon! This will open a visual flow designer where you can create automated conversation flows with drag-and-drop components.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _editFlow(Map<String, dynamic> flow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Edit ${flow['name']}', style: const TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        content: const Text(
          'Flow editor is coming soon! This will open the visual flow designer where you can modify your conversation flow structure.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _testFlow(Map<String, dynamic> flow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Test ${flow['name']}', style: const TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        content: const Text(
          'Flow testing simulator is coming soon! This will allow you to test your flow responses and see how customers will experience the conversation.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _duplicateFlow(Map<String, dynamic> flow) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${flow['name']} duplicated successfully', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.greenAccent,
      ),
    );
  }

  void _deleteFlow(Map<String, dynamic> flow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Flow', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${flow['name']}"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Flow deleted successfully', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.redAccent,
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
}