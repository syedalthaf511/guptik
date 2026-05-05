import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
  
// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class AnalyticsMessageTemplatesScreen extends StatefulWidget {
  const AnalyticsMessageTemplatesScreen({super.key});

  @override
  State<AnalyticsMessageTemplatesScreen> createState() => _AnalyticsMessageTemplatesScreenState();
}

class _AnalyticsMessageTemplatesScreenState extends State<AnalyticsMessageTemplatesScreen> {
  String selectedPeriod = 'Last 30 days';
  final List<String> periods = ['Last 24 hours', 'Last 7 days', 'Last 30 days', 'Last 3 months', 'Custom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Template Analytics',
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
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: Colors.black,
              iconTheme: const IconThemeData(color: _ancientGold),
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.date_range, color: _ancientGold),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: _ancientGold.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                setState(() {
                  selectedPeriod = value;
                });
              },
              itemBuilder: (context) => periods.map((period) {
                return PopupMenuItem<String>(
                  value: period,
                  child: Text(
                    period,
                    style: TextStyle(
                      color: selectedPeriod == period ? _ancientGold : Colors.white,
                      fontWeight: selectedPeriod == period ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: _ancientGold),
            onPressed: () {
              // Refresh analytics
            },
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
                  // Period Selector
                  Container(
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
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: _ancientGold, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Template Analytics Period:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _ancientGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _ancientGold.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            selectedPeriod,
                            style: const TextStyle(
                              color: _ancientGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Template Overview
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Total Templates',
                          '12',
                          '+3',
                          Icons.description,
                          Colors.blueAccent,
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Approved Templates',
                          '9',
                          '+2',
                          Icons.check_circle,
                          Colors.greenAccent,
                          true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Template Usage',
                          '2,847',
                          '+24.3%',
                          Icons.send,
                          Colors.purpleAccent,
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Success Rate',
                          '96.8%',
                          '+1.2%',
                          Icons.trending_up,
                          Colors.greenAccent,
                          true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Template Performance Ranking
                  _buildSectionContainer(
                    title: 'Template Performance Ranking',
                    child: Column(
                      children: [
                        _buildTemplateRankingRow(1, 'welcome_message', 1247, 1198, 96.1, 'APPROVED'),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildTemplateRankingRow(2, 'order_confirmation', 892, 879, 98.5, 'APPROVED'),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildTemplateRankingRow(3, 'shipping_update', 543, 521, 95.9, 'APPROVED'),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildTemplateRankingRow(4, 'support_ticket', 234, 231, 98.7, 'APPROVED'),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildTemplateRankingRow(5, 'promotional_offer', 156, 142, 91.0, 'APPROVED'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Template Categories
                  _buildSectionContainer(
                    title: 'Templates by Category',
                    child: Column(
                      children: [
                        _buildCategoryRow('Transactional', 6, 1894, 97.2, Icons.receipt),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildCategoryRow('Marketing', 3, 687, 89.4, Icons.campaign),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildCategoryRow('Utility', 3, 266, 94.7, Icons.build),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Template Status Overview
                  _buildSectionContainer(
                    title: 'Template Status Overview',
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatusCard('Approved', 9, Colors.greenAccent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatusCard('Pending', 2, Colors.orangeAccent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatusCard('Rejected', 1, Colors.redAccent),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Template Activity
                  _buildSectionContainer(
                    title: 'Recent Template Activity',
                    child: Column(
                      children: [
                        _buildActivityRow('welcome_message', 'Used 47 times', '2 hours ago', Icons.send),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildActivityRow('order_confirmation', 'Used 23 times', '4 hours ago', Icons.send),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildActivityRow('promo_code_2024', 'Template approved', '1 day ago', Icons.check_circle),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildActivityRow('shipping_delay', 'Template submitted', '2 days ago', Icons.schedule),
                      ],
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

  Widget _buildSectionContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 1.5),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _ancientGold,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String change, IconData icon, Color color, bool isPositive) {
    return Container(
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (isPositive ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.4)),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPositive ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateRankingRow(int rank, String templateName, int sent, int delivered, double rate, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3 ? _ancientGold : Colors.white10,
              borderRadius: BorderRadius.circular(14),
              boxShadow: rank <= 3 ? [BoxShadow(color: _ancientGold.withValues(alpha: 0.4), blurRadius: 4)] : null,
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.black : Colors.white70,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  templateName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$delivered/$sent sent',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'APPROVED' ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.orangeAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: status == 'APPROVED' ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.orangeAccent.withValues(alpha: 0.4)),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: status == 'APPROVED' ? Colors.greenAccent : Colors.orangeAccent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${rate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: rate > 95 ? Colors.greenAccent : rate > 90 ? Colors.orangeAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String category, int count, int usage, double rate, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _ancientGold, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count templates, $usage uses',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${rate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: rate > 95 ? Colors.greenAccent : rate > 90 ? Colors.orangeAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(String templateName, String activity, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  templateName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  activity,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}