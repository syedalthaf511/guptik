import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class AnalyticsFlowResponsesScreen extends StatefulWidget {
  const AnalyticsFlowResponsesScreen({super.key});

  @override
  State<AnalyticsFlowResponsesScreen> createState() => _AnalyticsFlowResponsesScreenState();
}

class _AnalyticsFlowResponsesScreenState extends State<AnalyticsFlowResponsesScreen> {
  String selectedPeriod = 'Last 7 days';
  final List<String> periods = ['Last 24 hours', 'Last 7 days', 'Last 30 days', 'Last 3 months', 'Custom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Flow Response Analytics',
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
                  // Period and Flow Selector
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
                            const Icon(Icons.account_tree, color: _ancientGold, size: 24),
                            const SizedBox(width: 12),
                            const Text(
                              'Flow Analytics Period:',
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
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          dropdownColor: Colors.black,
                          icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          isExpanded: true, // Prevents text overflow
                          decoration: InputDecoration(
                            labelText: 'Select Flow',
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
                          initialValue: 'All Flows',
                          items: const [
                            DropdownMenuItem(value: 'All Flows', child: Text('All Flows', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Welcome Flow', child: Text('Welcome Flow', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Support Flow', child: Text('Support Flow', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Product Inquiry', child: Text('Product Inquiry Flow', overflow: TextOverflow.ellipsis)),
                            DropdownMenuItem(value: 'Feedback Flow', child: Text('Feedback Flow', overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (value) {
                            // Handle flow selection
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Flow Overview
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Total Interactions',
                          '3,247',
                          '+18.5%',
                          Icons.touch_app,
                          Colors.blueAccent,
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Completion Rate',
                          '68.4%',
                          '+5.2%',
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
                          'Drop-off Rate',
                          '31.6%',
                          '-3.1%',
                          Icons.exit_to_app,
                          Colors.orangeAccent,
                          true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Avg. Steps/Session',
                          '4.2',
                          '+0.8',
                          Icons.timeline,
                          Colors.purpleAccent,
                          true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Flow Performance Comparison
                  _buildSectionContainer(
                    title: 'Flow Performance Comparison',
                    child: Column(
                      children: [
                        _buildFlowPerformanceRow('Welcome Flow', 1247, 892, 71.5, 4.8),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildFlowPerformanceRow('Support Flow', 834, 523, 62.7, 3.2),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildFlowPerformanceRow('Product Inquiry', 678, 445, 65.6, 4.1),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildFlowPerformanceRow('Feedback Flow', 488, 362, 74.2, 5.1),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Step-by-Step Analysis
                  _buildSectionContainer(
                    title: 'Welcome Flow - Step Analysis',
                    child: Column(
                      children: [
                        _buildStepAnalysisRow('Step 1: Greeting', 1247, 1189, 95.3),
                        const SizedBox(height: 12),
                        _buildStepAnalysisRow('Step 2: Menu Selection', 1189, 1034, 87.0),
                        const SizedBox(height: 12),
                        _buildStepAnalysisRow('Step 3: Information Request', 1034, 923, 89.3),
                        const SizedBox(height: 12),
                        _buildStepAnalysisRow('Step 4: Confirmation', 923, 892, 96.6),
                        const SizedBox(height: 12),
                        _buildStepAnalysisRow('Step 5: Completion', 892, 892, 100.0),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Response Type Distribution
                  _buildSectionContainer(
                    title: 'Response Type Distribution',
                    child: Column(
                      children: [
                        _buildResponseTypeRow('Button Clicks', 1894, 58.4, Icons.touch_app),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildResponseTypeRow('Quick Replies', 967, 29.8, Icons.reply),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildResponseTypeRow('Text Input', 284, 8.7, Icons.keyboard),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildResponseTypeRow('List Selection', 102, 3.1, Icons.list),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Drop-off Points Analysis
                  _buildSectionContainer(
                    title: 'Common Drop-off Points',
                    child: Column(
                      children: [
                        _buildDropoffRow('Step 2: Menu Selection', 155, 13.0),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildDropoffRow('Step 3: Information Request', 111, 10.7),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildDropoffRow('Step 1: Greeting', 58, 4.7),
                        Divider(color: _ancientGold.withValues(alpha: 0.1), height: 16),
                        _buildDropoffRow('Step 4: Confirmation', 31, 3.4),
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

  Widget _buildFlowPerformanceRow(String flowName, int started, int completed, double rate, double avgSteps) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              flowName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              '$completed/$started',
              style: TextStyle(fontSize: 12, color: Colors.grey[400], fontFamily: 'monospace'),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: rate > 70 ? Colors.greenAccent : rate > 60 ? Colors.orangeAccent : Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              avgSteps.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: _ancientGold,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepAnalysisRow(String step, int entered, int completed, double rate) {
    final Color progressColor = rate > 95 ? Colors.greenAccent : rate > 85 ? Colors.orangeAccent : Colors.redAccent;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  step,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$completed/$entered (${rate.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTypeRow(String type, int count, double percentage, IconData icon) {
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
            '$count (${percentage.toStringAsFixed(1)}%)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _ancientGold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropoffRow(String step, int count, double percentage) {
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
              step,
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
}