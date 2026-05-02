import 'package:flutter/material.dart';
import 'package:guptik/widgets/home/animated_nebula_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  final List<Map<String, dynamic>> _integrations = [
    {
      'id': 'zapier',
      'name': 'Zapier',
      'description': 'Connect with 5000+ apps through Zapier automation',
      'icon': Icons.link,
      'color': Colors.orangeAccent,
      'connected': true,
      'category': 'Automation',
    },
    {
      'id': 'shopify',
      'name': 'Shopify',
      'description': 'Sync products, orders, and customer data',
      'icon': Icons.shopping_cart,
      'color': Colors.greenAccent,
      'connected': false,
      'category': 'E-commerce',
    },
    {
      'id': 'woocommerce',
      'name': 'WooCommerce',
      'description': 'WordPress e-commerce integration',
      'icon': Icons.store,
      'color': Colors.purpleAccent,
      'connected': false,
      'category': 'E-commerce',
    },
    {
      'id': 'hubspot',
      'name': 'HubSpot CRM',
      'description': 'Sync contacts and lead data automatically',
      'icon': Icons.people,
      'color': Colors.blueAccent,
      'connected': true,
      'category': 'CRM',
    },
    {
      'id': 'salesforce',
      'name': 'Salesforce',
      'description': 'Enterprise CRM integration',
      'icon': Icons.cloud,
      'color': Colors.lightBlueAccent,
      'connected': false,
      'category': 'CRM',
    },
    {
      'id': 'google_sheets',
      'name': 'Google Sheets',
      'description': 'Export data and sync contacts with spreadsheets',
      'icon': Icons.table_chart,
      'color': Colors.greenAccent,
      'connected': true,
      'category': 'Productivity',
    },
    {
      'id': 'mailchimp',
      'name': 'Mailchimp',
      'description': 'Sync email marketing lists and campaigns',
      'icon': Icons.email,
      'color': Colors.amberAccent,
      'connected': false,
      'category': 'Marketing',
    },
    {
      'id': 'stripe',
      'name': 'Stripe',
      'description': 'Payment processing and subscription management',
      'icon': Icons.payment,
      'color': Colors.indigoAccent,
      'connected': false,
      'category': 'Payments',
    },
  ];

  String _selectedCategory = 'All';
  List<String> get _categories {
    final categories = _integrations.map((i) => i['category'] as String).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  List<Map<String, dynamic>> get _filteredIntegrations {
    if (_selectedCategory == 'All') return _integrations;
    return _integrations.where((i) => i['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Integrations',
          style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: _ancientGold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // The Shared Cinematic Nebula Background
            const Positioned.fill(child: AnimatedNebulaBackground()),
            
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Connect Your Apps',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _ancientGold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Integrate WhatsApp with your favorite tools and platforms to streamline your workflow.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Connected',
                          _integrations.where((i) => i['connected']).length.toString(),
                          Icons.check_circle,
                          Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Available',
                          _integrations.length.toString(),
                          Icons.apps,
                          _ancientGold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Category Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: _selectedCategory == category,
                          label: Text(category),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                          selectedColor: _ancientGold.withValues(alpha: 0.2),
                          checkmarkColor: _ancientGold,
                          side: BorderSide(
                            color: _selectedCategory == category 
                                ? _ancientGold 
                                : Colors.white24,
                          ),
                          labelStyle: TextStyle(
                            color: _selectedCategory == category 
                                ? _ancientGold 
                                : Colors.white70,
                            fontWeight: _selectedCategory == category 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Integrations Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          // THE FIX: Replaced childAspectRatio with a strict vertical height 
                          // of 260px so the cards never overflow!
                          mainAxisExtent: 260, 
                        ),
                        itemCount: _filteredIntegrations.length,
                        itemBuilder: (context, index) {
                          return _buildIntegrationCard(_filteredIntegrations[index]);
                        },
                      );
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationCard(Map<String, dynamic> integration) {
    final isConnected = integration['connected'] as bool;
    
    return Container(
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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (integration['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (integration['color'] as Color).withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    integration['icon'],
                    color: integration['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        integration['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          border: Border.all(color: _ancientGold.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          integration['category'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[300],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8), // Added spacing to prevent overlap
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isConnected ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.white24,
                    ),
                  ),
                  child: Text(
                    isConnected ? 'Connected' : 'Available',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isConnected ? Colors.greenAccent : Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              integration['description'],
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _toggleIntegration(integration),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected 
                    ? Colors.redAccent.withValues(alpha: 0.15)
                    : _ancientGold,
                  foregroundColor: isConnected 
                    ? Colors.redAccent
                    : Colors.black,
                  side: isConnected 
                    ? const BorderSide(color: Colors.redAccent) 
                    : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: isConnected ? 0 : 4,
                ),
                child: Text(
                  isConnected ? 'Disconnect' : 'Connect',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleIntegration(Map<String, dynamic> integration) {
    final isConnected = integration['connected'] as bool;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '${isConnected ? 'Disconnect' : 'Connect'} ${integration['name']}',
          style: TextStyle(
            color: isConnected ? Colors.redAccent : _ancientGold, 
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isConnected 
            ? 'Are you sure you want to disconnect ${integration['name']}? This will stop all data syncing.'
            : 'Connect ${integration['name']} to sync data and automate workflows.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                integration['connected'] = !isConnected;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${integration['name']} ${!isConnected ? 'connected' : 'disconnected'} successfully',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: !isConnected ? Colors.greenAccent : Colors.orangeAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected ? Colors.redAccent : _ancientGold,
              foregroundColor: Colors.black,
            ),
            child: Text(
              isConnected ? 'Disconnect' : 'Connect',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}