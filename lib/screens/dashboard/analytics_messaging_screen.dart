import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class AnalyticsMessagingScreen extends StatefulWidget {
  const AnalyticsMessagingScreen({super.key});

  @override
  State<AnalyticsMessagingScreen> createState() => _AnalyticsMessagingScreenState();
}

class _AnalyticsMessagingScreenState extends State<AnalyticsMessagingScreen> {
  String selectedPeriod = 'Last 7 days';
  final List<String> periods = ['Last 24 hours', 'Last 7 days', 'Last 30 days', 'Last 3 months', 'Custom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Messaging Analytics',
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
                        const Icon(Icons.calendar_today, color: _ancientGold, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'Analytics Period:',
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
                  ),

                  const SizedBox(height: 24),

                  // Overview Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Messages Sent',
                          '1,247',
                          '+12.5%',
                          Icons.send,
                          Colors.blueAccent,
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Messages Delivered',
                          '1,189',
                          '+10.2%',
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
                          'Messages Read',
                          '892',
                          '+8.7%',
                          Icons.visibility,
                          Colors.orangeAccent,
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Failed Messages',
                          '58',
                          '-3.1%',
                          Icons.error,
                          Colors.redAccent,
                          false,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Message Status Breakdown
                  _buildSectionContainer(
                    title: 'Message Status Breakdown',
                    child: Column(
                      children: [
                        _buildStatusRow('Delivered', 1189, 1247, Colors.greenAccent),
                        _buildStatusRow('Read', 892, 1247, Colors.blueAccent),
                        _buildStatusRow('Failed', 58, 1247, Colors.redAccent),
                        _buildStatusRow('Pending', 0, 1247, Colors.orangeAccent),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Message Types Analytics
                  _buildSectionContainer(
                    title: 'Message Types',
                    child: Column(
                      children: [
                        _buildMessageTypeRow('Text Messages', 847, Icons.message),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildMessageTypeRow('Media Messages', 234, Icons.image),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildMessageTypeRow('Template Messages', 166, Icons.description),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildMessageTypeRow('Interactive Messages', 0, Icons.touch_app),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Response Times
                  _buildSectionContainer(
                    title: 'Response Times',
                    child: Column(
                      children: [
                        _buildResponseTimeRow('Average Response Time', '2m 34s'),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildResponseTimeRow('Fastest Response', '12s'),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildResponseTimeRow('Slowest Response', '45m 12s'),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildResponseTimeRow('Response Rate', '74.2%'),
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

  Widget _buildStatusRow(String status, int count, int total, Color color) {
    final percentage = (count / total * 100).toStringAsFixed(1);
    final progress = count / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                status,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '$count ($percentage%)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTypeRow(String type, int count, IconData icon) {
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
            child: Text(
              type,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _ancientGold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTimeRow(String metric, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            metric,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _ancientGold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}