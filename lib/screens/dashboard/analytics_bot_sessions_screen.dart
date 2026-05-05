import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class AnalyticsBotSessionsScreen extends StatefulWidget {
  const AnalyticsBotSessionsScreen({super.key});

  @override
  State<AnalyticsBotSessionsScreen> createState() => _AnalyticsBotSessionsScreenState();
}

class _AnalyticsBotSessionsScreenState extends State<AnalyticsBotSessionsScreen> {
  String selectedPeriod = 'Last 7 days';
  final List<String> periods = ['Last 24 hours', 'Last 7 days', 'Last 30 days', 'Last 3 months', 'Custom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Bot Session Analytics',
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
                  // Bot Analytics Header
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
                            const Icon(Icons.smart_toy, color: _ancientGold, size: 28),
                            const SizedBox(width: 12),
                            const Text(
                              'Bot Analytics Period:',
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
                            labelText: 'Select Bot',
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
                          initialValue: 'All Bots',
                          items: const [
                            DropdownMenuItem(value: 'All Bots', child: Text('All Bots', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Customer Support Bot', child: Text('Customer Support Bot', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Sales Assistant Bot', child: Text('Sales Assistant Bot', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'FAQ Bot', child: Text('FAQ Bot', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Order Status Bot', child: Text('Order Status Bot', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (value) {
                            // Handle bot selection
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bot Performance Overview
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Total Sessions',
                          '2,847',
                          '+15.3%',
                          Icons.chat,
                          Colors.blueAccent,
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Success Rate',
                          '82.4%',
                          '+4.7%',
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
                          'Avg. Session Time',
                          '3m 42s',
                          '-18s',
                          Icons.schedule,
                          Colors.orangeAccent,
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Handoff Rate',
                          '17.6%',
                          '-2.3%',
                          Icons.person,
                          Colors.purpleAccent,
                          true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Bot Performance by Type
                  _buildSectionContainer(
                    title: 'Bot Performance by Type',
                    child: Column(
                      children: [
                        _buildBotPerformanceRow('Customer Support Bot', 1247, 1034, 82.9, '4m 12s'),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildBotPerformanceRow('Sales Assistant Bot', 834, 712, 85.4, '3m 28s'),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildBotPerformanceRow('FAQ Bot', 478, 423, 88.5, '2m 15s'),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildBotPerformanceRow('Order Status Bot', 288, 267, 92.7, '1m 45s'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Intent Recognition Analysis
                  _buildSectionContainer(
                    title: 'Intent Recognition Performance',
                    child: Column(
                      children: [
                        _buildIntentRow('Product Information', 1034, 97.3, Icons.info),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildIntentRow('Order Support', 678, 94.8, Icons.shopping_cart),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildIntentRow('Technical Help', 445, 89.2, Icons.build),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildIntentRow('Account Issues', 234, 92.7, Icons.account_circle),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildIntentRow('General Inquiry', 456, 85.1, Icons.help),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Session Duration Distribution
                  _buildSectionContainer(
                    title: 'Session Duration Distribution',
                    child: Column(
                      children: [
                        _buildDurationRow('< 1 minute', 456, 16.0),
                        const SizedBox(height: 12),
                        _buildDurationRow('1-3 minutes', 1247, 43.8),
                        const SizedBox(height: 12),
                        _buildDurationRow('3-5 minutes', 834, 29.3),
                        const SizedBox(height: 12),
                        _buildDurationRow('5-10 minutes', 234, 8.2),
                        const SizedBox(height: 12),
                        _buildDurationRow('> 10 minutes', 76, 2.7),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Escalation Analysis
                  _buildSectionContainer(
                    title: 'Escalation Reasons',
                    child: Column(
                      children: [
                        _buildEscalationRow('Complex Issue', 234, 46.8),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildEscalationRow('Bot Confusion', 123, 24.6),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildEscalationRow('User Request', 89, 17.8),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildEscalationRow('Technical Error', 54, 10.8),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // User Satisfaction Metrics
                  _buildSectionContainer(
                    title: 'User Satisfaction Metrics',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildSatisfactionMetric('Average Rating', '4.2/5', Colors.greenAccent),
                        ),
                        Container(width: 1, height: 60, color: _ancientGold.withValues(alpha: 0.2)),
                        Expanded(
                          child: _buildSatisfactionMetric('Positive Feedback', '78.4%', Colors.blueAccent),
                        ),
                        Container(width: 1, height: 60, color: _ancientGold.withValues(alpha: 0.2)),
                        Expanded(
                          child: _buildSatisfactionMetric('Response Rate', '34.7%', Colors.orangeAccent),
                        ),
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
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotPerformanceRow(String botName, int sessions, int successful, double rate, String avgTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              botName,
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
              sessions.toString(),
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
                color: rate > 85 ? Colors.greenAccent : rate > 75 ? Colors.orangeAccent : Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              avgTime,
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

  Widget _buildIntentRow(String intent, int count, double accuracy, IconData icon) {
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
                  intent,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count interactions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (accuracy > 95 ? Colors.greenAccent : accuracy > 85 ? Colors.orangeAccent : Colors.redAccent).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: (accuracy > 95 ? Colors.greenAccent : accuracy > 85 ? Colors.orangeAccent : Colors.redAccent).withValues(alpha: 0.3)),
            ),
            child: Text(
              '${accuracy.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: accuracy > 95 ? Colors.greenAccent : accuracy > 85 ? Colors.orangeAccent : Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationRow(String duration, int count, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                duration,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              Text(
                '$count (${percentage.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _ancientGold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(_ancientGold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationRow(String reason, int count, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              reason,
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
              color: Colors.orangeAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
            ),
            child: Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSatisfactionMetric(String metric, String value, Color color) {
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
}