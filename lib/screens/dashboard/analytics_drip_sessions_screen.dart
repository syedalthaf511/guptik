import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class AnalyticsDripSessionsScreen extends StatefulWidget {
  const AnalyticsDripSessionsScreen({super.key});

  @override
  State<AnalyticsDripSessionsScreen> createState() => _AnalyticsDripSessionsScreenState();
}

class _AnalyticsDripSessionsScreenState extends State<AnalyticsDripSessionsScreen> {
  String selectedPeriod = 'Last 30 days';
  final List<String> periods = ['Last 24 hours', 'Last 7 days', 'Last 30 days', 'Last 3 months', 'Custom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Drip Campaign Analytics',
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
                  // Campaign Selector
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
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.water_drop, color: _ancientGold, size: 28),
                            const SizedBox(width: 12),
                            const Text(
                              'Drip Campaign Analytics:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
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
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          dropdownColor: Colors.black,
                          icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          isExpanded: true, // Prevents text overflow
                          decoration: InputDecoration(
                            labelText: 'Select Campaign',
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
                          initialValue: 'All Campaigns',
                          items: const [
                            DropdownMenuItem(value: 'All Campaigns', child: Text('All Campaigns', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Welcome Series', child: Text('Welcome Series', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Product Education', child: Text('Product Education', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Re-engagement', child: Text('Re-engagement Campaign', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Customer Onboarding', child: Text('Customer Onboarding', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (value) {
                            // Handle campaign selection
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Campaign Performance Overview
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Active Campaigns',
                          '8',
                          '+2',
                          Icons.play_circle_filled,
                          Colors.greenAccent,
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Total Subscribers',
                          '4,521',
                          '+187',
                          Icons.group,
                          Colors.blueAccent,
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
                          'Messages Sent',
                          '12,847',
                          '+32.4%',
                          Icons.send,
                          Colors.purpleAccent,
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Completion Rate',
                          '64.7%',
                          '+8.2%',
                          Icons.check_circle,
                          Colors.orangeAccent,
                          true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Campaign Performance Comparison
                  _buildSectionContainer(
                    title: 'Campaign Performance Comparison',
                    child: Column(
                      children: [
                        _buildCampaignPerformanceRow('Welcome Series', 1247, 847, 67.9, 8.2),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildCampaignPerformanceRow('Product Education', 894, 623, 69.7, 6.8),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildCampaignPerformanceRow('Re-engagement', 567, 334, 58.9, 4.5),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildCampaignPerformanceRow('Customer Onboarding', 423, 298, 70.4, 7.1),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Message Sequence Performance
                  _buildSectionContainer(
                    title: 'Welcome Series - Message Performance',
                    child: Column(
                      children: [
                        _buildMessageSequenceRow('Day 1: Welcome Message', 1247, 1189, 95.3, 23.4),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildMessageSequenceRow('Day 3: Product Tour', 1189, 967, 81.3, 18.7),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildMessageSequenceRow('Day 7: Tips & Tricks', 967, 823, 85.1, 15.2),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildMessageSequenceRow('Day 14: Feature Highlight', 823, 698, 84.8, 12.8),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildMessageSequenceRow('Day 30: Feedback Request', 698, 534, 76.5, 8.3),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Engagement Metrics
                  _buildSectionContainer(
                    title: 'Engagement Metrics',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildEngagementMetric('Open Rate', '84.2%', Colors.blueAccent),
                        ),
                        Container(width: 1, height: 60, color: _ancientGold.withValues(alpha: 0.2)),
                        Expanded(
                          child: _buildEngagementMetric('Click Rate', '18.7%', Colors.greenAccent),
                        ),
                        Container(width: 1, height: 60, color: _ancientGold.withValues(alpha: 0.2)),
                        Expanded(
                          child: _buildEngagementMetric('Unsubscribe', '2.1%', Colors.redAccent),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Drop-off Analysis
                  _buildSectionContainer(
                    title: 'Drop-off Analysis',
                    child: Column(
                      children: [
                        _buildDropoffRow('After Message 1', 58, 4.7),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildDropoffRow('After Message 2', 222, 18.7),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildDropoffRow('After Message 3', 144, 17.5),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildDropoffRow('After Message 4', 125, 17.9),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildDropoffRow('After Message 5', 164, 30.7),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Best Performing Messages
                  _buildSectionContainer(
                    title: 'Best Performing Messages',
                    child: Column(
                      children: [
                        _buildTopMessageRow(1, 'Welcome & Getting Started', 95.3, 23.4),
                        const SizedBox(height: 8),
                        _buildTopMessageRow(2, 'Feature Tips & Tricks', 85.1, 15.2),
                        const SizedBox(height: 8),
                        _buildTopMessageRow(3, 'Product Highlight', 84.8, 12.8),
                        const SizedBox(height: 8),
                        _buildTopMessageRow(4, 'Tutorial Video', 81.3, 18.7),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Timing Analysis
                  _buildSectionContainer(
                    title: 'Optimal Timing Analysis',
                    child: Column(
                      children: [
                        _buildTimingRow('Best Day', 'Tuesday', '89.4% open rate'),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 12),
                        _buildTimingRow('Best Time', '10:00 AM', '91.2% open rate'),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 12),
                        _buildTimingRow('Worst Day', 'Saturday', '67.8% open rate'),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 12),
                        _buildTimingRow('Worst Time', '11:00 PM', '52.3% open rate'),
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

  Widget _buildCampaignPerformanceRow(String campaign, int subscribers, int completed, double rate, double avgMessages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              campaign,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              subscribers.toString(),
              style: TextStyle(fontSize: 13, color: Colors.grey[400], fontFamily: 'monospace'),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: rate > 65 ? Colors.greenAccent : rate > 55 ? Colors.orangeAccent : Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              avgMessages.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _ancientGold,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSequenceRow(String message, int sent, int opened, double openRate, double clickRate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '$opened/$sent',
                style: TextStyle(fontSize: 12, color: Colors.grey[400], fontFamily: 'monospace'),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (openRate > 85 ? Colors.greenAccent : openRate > 75 ? Colors.orangeAccent : Colors.redAccent).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${openRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: openRate > 85 ? Colors.greenAccent : openRate > 75 ? Colors.orangeAccent : Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(flex: 2, child: SizedBox()),
              Text(
                'Click rate: ${clickRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: _ancientGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementMetric(String metric, String value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          metric,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDropoffRow(String point, int count, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.redAccent.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              point,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMessageRow(int rank, String message, double openRate, double clickRate) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Open: ${openRate.toStringAsFixed(1)}%, Click: ${clickRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingRow(String label, String value, String metric) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _ancientGold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              metric,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}