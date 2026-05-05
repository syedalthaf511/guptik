import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class AnalyticsNotificationsScreen extends StatefulWidget {
  const AnalyticsNotificationsScreen({super.key});

  @override
  State<AnalyticsNotificationsScreen> createState() => _AnalyticsNotificationsScreenState();
}

class _AnalyticsNotificationsScreenState extends State<AnalyticsNotificationsScreen> {
  String _selectedPeriod = 'Last 7 days';
  final List<String> _periods = ['Last 24 hours', 'Last 7 days', 'Last 30 days', 'Last 90 days', 'Custom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Notifications Analytics',
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
                        const Icon(Icons.access_time, color: _ancientGold),
                        const SizedBox(width: 12),
                        const Text(
                          'Time Period:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            dropdownColor: Colors.black,
                            icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            initialValue: _selectedPeriod,
                            isExpanded: true, // Prevents text overflow
                            decoration: InputDecoration(
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
                            items: _periods.map((period) => DropdownMenuItem(
                              value: period,
                              child: Text(period, overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedPeriod = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Metrics Cards
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard(
                        'Total Campaigns',
                        '45',
                        Icons.campaign,
                        Colors.blueAccent,
                        '+12.5%'
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildMetricCard(
                        'Sent Notifications',
                        '12,847',
                        Icons.send,
                        Colors.greenAccent,
                        '+8.3%'
                      )),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard(
                        'Delivery Rate',
                        '94.2%',
                        Icons.check_circle,
                        Colors.cyanAccent,
                        '+2.1%'
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _buildMetricCard(
                        'Click Rate',
                        '23.7%',
                        Icons.touch_app,
                        Colors.orangeAccent,
                        '+5.8%'
                      )),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Campaign Performance Table
                  Container(
                    width: double.infinity,
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
                        const Text(
                          'Campaign Performance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _ancientGold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildPerformanceTable(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Notification Types Breakdown
                  Container(
                    width: double.infinity,
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
                        const Text(
                          'Notification Types',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _ancientGold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildNotificationTypesChart(),
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String change) {
    final isPositive = change.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 1.5),
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

  Widget _buildPerformanceTable() {
    final campaigns = [
      {'name': 'Welcome Series', 'sent': 2847, 'delivered': 2695, 'clicked': 678, 'status': 'Active'},
      {'name': 'Product Updates', 'sent': 1923, 'delivered': 1834, 'clicked': 423, 'status': 'Active'},
      {'name': 'Support Follow-up', 'sent': 1456, 'delivered': 1398, 'clicked': 287, 'status': 'Paused'},
      {'name': 'Promotional Offers', 'sent': 3214, 'delivered': 3048, 'clicked': 892, 'status': 'Active'},
      {'name': 'Order Confirmations', 'sent': 2876, 'delivered': 2743, 'clicked': 534, 'status': 'Active'},
    ];

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: _ancientGold.withValues(alpha: 0.2),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _ancientGold,
            fontSize: 14,
          ),
          dataTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          columns: const [
            DataColumn(label: Text('Campaign')),
            DataColumn(label: Text('Sent')),
            DataColumn(label: Text('Delivered')),
            DataColumn(label: Text('Clicked')),
            DataColumn(label: Text('Click Rate')),
            DataColumn(label: Text('Status')),
          ],
          rows: campaigns.map((campaign) {
            final clickRate = ((campaign['clicked'] as int) / (campaign['sent'] as int) * 100);
            final isActive = campaign['status'] == 'Active';
            return DataRow(
              cells: [
                DataCell(Text(campaign['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text((campaign['sent'] as int).toString(), style: const TextStyle(fontFamily: 'monospace'))),
                DataCell(Text((campaign['delivered'] as int).toString(), style: const TextStyle(fontFamily: 'monospace'))),
                DataCell(Text((campaign['clicked'] as int).toString(), style: const TextStyle(fontFamily: 'monospace', color: Colors.blueAccent))),
                DataCell(Text('${clickRate.toStringAsFixed(1)}%', style: const TextStyle(fontFamily: 'monospace', color: Colors.orangeAccent))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.orangeAccent.withValues(alpha: 0.15),
                      border: Border.all(color: isActive ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.orangeAccent.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      campaign['status'] as String,
                      style: TextStyle(
                        color: isActive ? Colors.greenAccent : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationTypesChart() {
    final types = [
      {'type': 'Marketing', 'count': 8456, 'percentage': 42.3, 'color': Colors.blueAccent},
      {'type': 'Transactional', 'count': 5234, 'percentage': 26.2, 'color': Colors.greenAccent},
      {'type': 'Support', 'count': 3421, 'percentage': 17.1, 'color': Colors.orangeAccent},
      {'type': 'Reminders', 'count': 2890, 'percentage': 14.4, 'color': Colors.purpleAccent},
    ];

    return Column(
      children: types.map((type) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: type['color'] as Color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(color: (type['color'] as Color).withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  type['type'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                ),
              ),
              Text(
                '${type['count']}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace', fontSize: 15),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 60,
                child: Text(
                  '${(type['percentage'] as double).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: _ancientGold,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}