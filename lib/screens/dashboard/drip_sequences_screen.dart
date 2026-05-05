import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class DripSequencesScreen extends StatefulWidget {
  const DripSequencesScreen({super.key});

  @override
  State<DripSequencesScreen> createState() => _DripSequencesScreenState();
}

class _DripSequencesScreenState extends State<DripSequencesScreen> {
  final List<Map<String, dynamic>> _sequences = [
    {
      'id': '1',
      'name': 'Welcome Series',
      'description': '5-message welcome sequence for new customers',
      'status': 'Active',
      'subscribers': 1234,
      'messages': [
        {'delay': 0, 'title': 'Welcome Message'},
        {'delay': 1, 'title': 'Getting Started Guide'},
        {'delay': 3, 'title': 'Feature Highlights'},
        {'delay': 7, 'title': 'Success Stories'},
        {'delay': 14, 'title': 'Feedback Request'},
      ],
      'open_rate': 78.5,
      'click_rate': 23.4,
      'created_date': DateTime.now().subtract(const Duration(days: 30)),
      'trigger': 'New subscriber',
    },
    {
      'id': '2',
      'name': 'Product Education',
      'description': '7-day educational series about product features',
      'status': 'Active',
      'subscribers': 867,
      'messages': [
        {'delay': 0, 'title': 'Introduction'},
        {'delay': 1, 'title': 'Basic Features'},
        {'delay': 2, 'title': 'Advanced Tips'},
        {'delay': 4, 'title': 'Best Practices'},
        {'delay': 6, 'title': 'Pro Tips'},
        {'delay': 8, 'title': 'Case Studies'},
        {'delay': 10, 'title': 'Next Steps'},
      ],
      'open_rate': 82.1,
      'click_rate': 31.7,
      'created_date': DateTime.now().subtract(const Duration(days: 15)),
      'trigger': 'Product signup',
    },
    {
      'id': '3',
      'name': 'Re-engagement Campaign',
      'description': 'Win back inactive customers with special offers',
      'status': 'Paused',
      'subscribers': 543,
      'messages': [
        {'delay': 0, 'title': 'We Miss You'},
        {'delay': 3, 'title': 'Special Offer'},
        {'delay': 7, 'title': 'Last Chance'},
      ],
      'open_rate': 45.3,
      'click_rate': 12.8,
      'created_date': DateTime.now().subtract(const Duration(days: 60)),
      'trigger': 'Inactive for 30 days',
    },
  ];

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Paused', 'Draft'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Drip Sequences',
          style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold),
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
            onPressed: _createSequence,
            tooltip: 'Create Sequence',
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
            
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 40), // Padded top to account for transparent AppBar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
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
                        const Text(
                          'Automated Message Sequences',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _ancientGold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Create timed message sequences to nurture leads, onboard customers, and drive engagement over time.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Stats Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildStatCard(
                                  'Active Sequences',
                                  _sequences.where((s) => s['status'] == 'Active').length.toString(),
                                  Icons.water_drop,
                                  Colors.blueAccent,
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatCard(
                                  'Total Subscribers',
                                  _sequences.fold(0, (sum, s) => sum + (s['subscribers'] as int)).toString(),
                                  Icons.people,
                                  Colors.greenAccent,
                                )),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildStatCard(
                                  'Avg Open Rate',
                                  '${(_sequences.fold(0.0, (sum, s) => sum + s['open_rate']) / _sequences.length).toStringAsFixed(1)}%',
                                  Icons.mark_email_read,
                                  Colors.orangeAccent,
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatCard(
                                  'Avg Click Rate',
                                  '${(_sequences.fold(0.0, (sum, s) => sum + s['click_rate']) / _sequences.length).toStringAsFixed(1)}%',
                                  Icons.touch_app,
                                  Colors.purpleAccent,
                                )),
                              ],
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(child: _buildStatCard(
                              'Active Sequences',
                              _sequences.where((s) => s['status'] == 'Active').length.toString(),
                              Icons.water_drop,
                              Colors.blueAccent,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard(
                              'Total Subscribers',
                              _sequences.fold(0, (sum, s) => sum + (s['subscribers'] as int)).toString(),
                              Icons.people,
                              Colors.greenAccent,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard(
                              'Avg Open Rate',
                              '${(_sequences.fold(0.0, (sum, s) => sum + s['open_rate']) / _sequences.length).toStringAsFixed(1)}%',
                              Icons.mark_email_read,
                              Colors.orangeAccent,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard(
                              'Avg Click Rate',
                              '${(_sequences.fold(0.0, (sum, s) => sum + s['click_rate']) / _sequences.length).toStringAsFixed(1)}%',
                              Icons.touch_app,
                              Colors.purpleAccent,
                            )),
                          ],
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Filter and Create Button
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          dropdownColor: Colors.black,
                          icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          initialValue: _selectedFilter,
                          isExpanded: true, // THE FIX: Prevents text overflow in dropdown
                          decoration: InputDecoration(
                            labelText: 'Filter by Status',
                            labelStyle: TextStyle(color: Colors.grey[500]),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.5),
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
                          items: _filters.map((filter) => DropdownMenuItem(
                            value: filter,
                            child: Text(filter, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedFilter = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _createSequence,
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: const Text('New', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ancientGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sequence Templates
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: _ancientGold),
                              SizedBox(width: 8),
                              Text(
                                'Sequence Templates',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSequenceTemplates(),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Your Sequences',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _ancientGold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Existing Sequences
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _filteredSequences.length,
                    itemBuilder: (context, index) {
                      return _buildSequenceCard(_filteredSequences[index]);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredSequences {
    if (_selectedFilter == 'All') return _sequences;
    return _sequences.where((seq) => seq['status'] == _selectedFilter).toList();
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ancientGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSequenceTemplates() {
    final templates = [
      {'name': 'Welcome Series', 'icon': Icons.waving_hand, 'color': Colors.blueAccent, 'messages': 5},
      {'name': 'Product Onboarding', 'icon': Icons.school, 'color': Colors.greenAccent, 'messages': 7},
      {'name': 'Sales Nurture', 'icon': Icons.trending_up, 'color': Colors.orangeAccent, 'messages': 6},
      {'name': 'Re-engagement', 'icon': Icons.refresh, 'color': Colors.purpleAccent, 'messages': 3},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // THE FIX: Replaced childAspectRatio with mainAxisExtent to prevent text overflow on narrow screens
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 80, 
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _useTemplate(template['name'] as String),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(
                        template['icon'] as IconData,
                        color: template['color'] as Color,
                        size: 20,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (template['color'] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: (template['color'] as Color).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${template['messages']} msgs',
                          style: TextStyle(
                            fontSize: 10,
                            color: template['color'] as Color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    template['name'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSequenceCard(Map<String, dynamic> sequence) {
    final isActive = sequence['status'] == 'Active';
    final messages = sequence['messages'] as List<Map<String, dynamic>>;
    final statusColor = _getStatusColor(sequence['status']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _ancientGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _ancientGold.withValues(alpha: 0.4)),
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: _ancientGold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sequence['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sequence['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  sequence['status'],
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Metrics Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(child: _buildMetric('Subscribers', sequence['subscribers'].toString(), Icons.people, Colors.blueAccent)),
                Container(width: 1, height: 40, color: Colors.white10),
                Expanded(child: _buildMetric('Messages', messages.length.toString(), Icons.message, Colors.purpleAccent)),
                Container(width: 1, height: 40, color: Colors.white10),
                Expanded(child: _buildMetric('Open Rate', '${sequence['open_rate']}%', Icons.mark_email_read, Colors.orangeAccent)),
                Container(width: 1, height: 40, color: Colors.white10),
                Expanded(child: _buildMetric('Click Rate', '${sequence['click_rate']}%', Icons.touch_app, Colors.greenAccent)),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Message Timeline Preview
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(
                      'Message Timeline:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ...messages.take(3).map((msg) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        decoration: BoxDecoration(
                          color: _ancientGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Day ${msg['delay']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _ancientGold,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )),
                    if (messages.length > 3)
                      Expanded(
                        child: Text(
                          '+${messages.length - 3} more',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Trigger Info
          Row(
            children: [
              const Icon(Icons.flash_on, size: 16, color: _ancientGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Trigger: ${sequence['trigger']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[300],
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // THE FIX: Scrollable row prevents action buttons from overflowing on small screens
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editSequence(sequence),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _duplicateSequence(sequence),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Duplicate', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                    side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _toggleSequence(sequence),
                  icon: Icon(isActive ? Icons.pause : Icons.play_arrow, size: 16),
                  label: Text(isActive ? 'Pause' : 'Activate', style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isActive ? Colors.orangeAccent : Colors.greenAccent,
                    side: BorderSide(color: isActive ? Colors.orangeAccent.withValues(alpha: 0.5) : Colors.greenAccent.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _viewAnalytics(sequence),
                  icon: const Icon(Icons.analytics, size: 16, color: Colors.black),
                  label: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ancientGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.greenAccent;
      case 'paused':
        return Colors.orangeAccent;
      case 'draft':
        return Colors.blueAccent;
      default:
        return Colors.grey[400]!;
    }
  }

  void _createSequence() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening sequence builder...', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _useTemplate(String templateName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating sequence from $templateName template', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _editSequence(Map<String, dynamic> sequence) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing ${sequence['name']}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _duplicateSequence(Map<String, dynamic> sequence) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Duplicating ${sequence['name']}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _toggleSequence(Map<String, dynamic> sequence) {
    setState(() {
      sequence['status'] = sequence['status'] == 'Active' ? 'Paused' : 'Active';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${sequence['name']} ${sequence['status'].toLowerCase()}',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: sequence['status'] == 'Active' ? Colors.greenAccent : Colors.orangeAccent,
      ),
    );
  }

  void _viewAnalytics(Map<String, dynamic> sequence) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing analytics for ${sequence['name']}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }
}