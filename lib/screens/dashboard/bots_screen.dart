import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class BotsScreen extends StatefulWidget {
  const BotsScreen({super.key});

  @override
  State<BotsScreen> createState() => _BotsScreenState();
}

class _BotsScreenState extends State<BotsScreen> {
  final List<Map<String, dynamic>> _bots = [
    {
      'id': '1',
      'name': 'Customer Support Bot',
      'description': 'Handles common support inquiries and escalates complex issues',
      'status': 'Active',
      'conversations': 156,
      'resolution_rate': 78.5,
      'created_date': DateTime.now().subtract(const Duration(days: 15)),
      'last_interaction': DateTime.now().subtract(const Duration(minutes: 45)),
      'triggers': ['help', 'support', 'problem', 'issue'],
    },
    {
      'id': '2',
      'name': 'Product Catalog Bot',
      'description': 'Shows product information, prices, and availability',
      'status': 'Active',
      'conversations': 89,
      'resolution_rate': 92.1,
      'created_date': DateTime.now().subtract(const Duration(days: 8)),
      'last_interaction': DateTime.now().subtract(const Duration(hours: 2)),
      'triggers': ['catalog', 'products', 'price', 'buy'],
    },
    {
      'id': '3',
      'name': 'Order Tracking Bot',
      'description': 'Provides order status and tracking information',
      'status': 'Paused',
      'conversations': 234,
      'resolution_rate': 85.3,
      'created_date': DateTime.now().subtract(const Duration(days: 30)),
      'last_interaction': DateTime.now().subtract(const Duration(days: 3)),
      'triggers': ['order', 'tracking', 'delivery', 'status'],
    },
  ];

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Paused', 'Training'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Chatbots',
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
            onPressed: _createBot,
            tooltip: 'Create New Bot',
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
                        const Row(
                          children: [
                            Icon(Icons.smart_toy, color: _ancientGold, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'AI-Powered Chatbots',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Create intelligent chatbots to handle customer inquiries automatically and provide instant support.',
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
                                  'Active Bots',
                                  _bots.where((b) => b['status'] == 'Active').length.toString(),
                                  Icons.bolt,
                                  Colors.greenAccent,
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatCard(
                                  'Conversations',
                                  _bots.fold(0, (sum, b) => sum + (b['conversations'] as int)).toString(),
                                  Icons.chat,
                                  Colors.blueAccent,
                                )),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildStatCard(
                                  'Avg Resolution',
                                  '${(_bots.fold(0.0, (sum, b) => sum + b['resolution_rate']) / _bots.length).toStringAsFixed(1)}%',
                                  Icons.check_circle,
                                  Colors.orangeAccent,
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _buildStatCard(
                                  'Total Bots',
                                  _bots.length.toString(),
                                  Icons.psychology,
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
                              'Active Bots',
                              _bots.where((b) => b['status'] == 'Active').length.toString(),
                              Icons.bolt,
                              Colors.greenAccent,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard(
                              'Conversations',
                              _bots.fold(0, (sum, b) => sum + (b['conversations'] as int)).toString(),
                              Icons.chat,
                              Colors.blueAccent,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard(
                              'Avg Resolution',
                              '${(_bots.fold(0.0, (sum, b) => sum + b['resolution_rate']) / _bots.length).toStringAsFixed(1)}%',
                              Icons.check_circle,
                              Colors.orangeAccent,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatCard(
                              'Total Bots',
                              _bots.length.toString(),
                              Icons.psychology,
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
                          isExpanded: true, // Prevents text overflow
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
                        onPressed: _createBot,
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: const Text('Create Bot', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  
                  // Bot Templates (Quick Start)
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
                          Row(
                            children: [
                              const Icon(Icons.bolt, color: _ancientGold),
                              const SizedBox(width: 8),
                              const Text(
                                'Quick Start Templates',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(foregroundColor: _ancientGold),
                                child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildBotTemplates(),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Existing Bots
                  const Text(
                    'Your Chatbots',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _ancientGold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _filteredBots.length,
                    itemBuilder: (context, index) {
                      return _buildBotCard(_filteredBots[index]);
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

  List<Map<String, dynamic>> get _filteredBots {
    if (_selectedFilter == 'All') return _bots;
    return _bots.where((bot) => bot['status'] == _selectedFilter).toList();
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

  Widget _buildBotTemplates() {
    final templates = [
      {'name': 'Customer Support', 'icon': Icons.support_agent, 'color': Colors.blueAccent},
      {'name': 'E-commerce', 'icon': Icons.shopping_cart, 'color': Colors.greenAccent},
      {'name': 'Lead Generation', 'icon': Icons.trending_up, 'color': Colors.orangeAccent},
      {'name': 'FAQ Assistant', 'icon': Icons.help, 'color': Colors.purpleAccent},
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (template['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      template['icon'] as IconData,
                      color: template['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      template['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBotCard(Map<String, dynamic> bot) {
    final isActive = bot['status'] == 'Active';
    final statusColor = _getStatusColor(bot['status']);
    
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
                  Icons.smart_toy,
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
                      bot['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bot['description'],
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
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  bot['status'],
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
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    'Conversations',
                    bot['conversations'].toString(),
                    Icons.chat,
                    Colors.blueAccent,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white10),
                Expanded(
                  child: _buildMetric(
                    'Resolution Rate',
                    '${bot['resolution_rate']}%',
                    Icons.check_circle,
                    Colors.greenAccent,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white10),
                Expanded(
                  child: _buildMetric(
                    'Last Active',
                    _formatTime(bot['last_interaction']),
                    Icons.access_time,
                    Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Trigger Keywords
          if (bot['triggers'].isNotEmpty) ...[
            Text(
              'Trigger Keywords:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (bot['triggers'] as List<String>).map((trigger) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _ancientGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                ),
                child: Text(
                  trigger,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _ancientGold,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // Actions - THE FIX: Scrollable row prevents action buttons from overflowing on small screens
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editBot(bot),
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
                  onPressed: () => _testBot(bot),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('Test', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                    side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _toggleBot(bot),
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
                  onPressed: () => _viewAnalytics(bot),
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
        const SizedBox(height: 8),
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
      case 'training':
        return Colors.blueAccent;
      default:
        return Colors.grey[400]!;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _createBot() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening bot builder...', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _useTemplate(String templateName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Creating bot from $templateName template', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _editBot(Map<String, dynamic> bot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing ${bot['name']}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _testBot(Map<String, dynamic> bot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting test conversation with ${bot['name']}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _toggleBot(Map<String, dynamic> bot) {
    setState(() {
      bot['status'] = bot['status'] == 'Active' ? 'Paused' : 'Active';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${bot['name']} ${bot['status'].toLowerCase()}',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bot['status'] == 'Active' ? Colors.greenAccent : Colors.orangeAccent,
      ),
    );
  }

  void _viewAnalytics(Map<String, dynamic> bot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing analytics for ${bot['name']}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }
}