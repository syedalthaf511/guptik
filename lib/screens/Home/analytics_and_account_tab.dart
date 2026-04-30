import 'dart:ui';
import 'package:flutter/material.dart';

const Color _ancientGold = Color(0xFFD4AF37);

class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final bool wrapWhenSmall;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.wrapWhenSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (wrapWhenSmall && constraints.maxWidth < 600) {
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          );
        }
        return Row(crossAxisAlignment: crossAxisAlignment, children: children);
      },
    );
  }
}

class AnalyticsAndAccountTab extends StatelessWidget {
  final dynamic dashboardData;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;

  const AnalyticsAndAccountTab({
    super.key,
    required this.dashboardData,
    required this.isLoading,
    this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(color: _ancientGold.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: _ancientGold))
                : error != null
                    ? _buildErrorDisplay()
                    : _buildStatusGrid(),
          ),
          const SizedBox(height: 40),
          _buildUsageHeader(),
          const SizedBox(height: 20),
          _buildUsageCards(),
          const SizedBox(height: 24),
          _buildBottomSection(context),
        ],
      ),
    );
  }

  Widget _buildStatusGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              ResponsiveRow(children: [
                Expanded(child: _buildStatusItem('Phone Number', dashboardData?.phoneNumberStatus?.displayPhoneNumber ?? 'Loading...')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatusItem('Display Name', dashboardData?.businessProfile?.displayName ?? 'Loading...')),
              ]),
              const SizedBox(height: 16),
              ResponsiveRow(children: [
                Expanded(child: _buildStatusItem('Messaging Limit', '1k/24hr')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatusItem('Quality Rating', dashboardData?.qualityRating?.rating ?? 'Loading...', isGreen: true)),
              ]),
              const SizedBox(height: 16),
              ResponsiveRow(children: [
                Expanded(child: _buildStatusItem('MM Lite API', '')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatusItem('Phone Status', _getConnectionStatus(), isGreen: _getConnectionStatus() == 'CONNECTED')),
              ]),
            ],
          );
        } else {
          return ResponsiveRow(children: [
            Expanded(child: _buildStatusItem('Phone Number', dashboardData?.phoneNumberStatus?.displayPhoneNumber ?? 'Loading...')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatusItem('Display Name', dashboardData?.businessProfile?.displayName ?? 'Loading...')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatusItem('Messaging Limit', '1k/24hr')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatusItem('MM Lite API', '')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatusItem('Quality Rating', dashboardData?.qualityRating?.rating ?? 'Loading...', isGreen: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatusItem('Phone Status', _getConnectionStatus(), isGreen: _getConnectionStatus() == 'CONNECTED')),
          ]);
        }
      },
    );
  }

  Widget _buildStatusItem(String label, String value, {bool isGreen = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (isGreen && value.isNotEmpty) Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
            if (isGreen && value.isNotEmpty) const SizedBox(width: 6),
            Expanded(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isGreen ? Colors.green : _ancientGold))),
          ],
        ),
      ],
    );
  }

  Widget _buildUsageHeader() {
    return Row(
      children: [
        const Icon(Icons.code, color: _ancientGold, size: 20),
        const SizedBox(width: 8),
        const Expanded(child: Text('WhatsApp API Usage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _ancientGold), overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        const Icon(Icons.info_outline, color: _ancientGold, size: 16),
        const SizedBox(width: 8),
        if (isLoading)
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _ancientGold))
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Text('Live', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.refresh, color: _ancientGold, size: 18), onPressed: onRefresh, padding: const EdgeInsets.all(4), constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
            ],
          ),
      ],
    );
  }

  Widget _buildUsageCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(children: [_buildMessageDeliveryCard(), const SizedBox(height: 16), _buildMessagesSummaryCard()]);
        } else {
          return ResponsiveRow(children: [Expanded(flex: 2, child: _buildMessageDeliveryCard()), const SizedBox(width: 16), Expanded(child: _buildMessagesSummaryCard())]);
        }
      },
    );
  }

  Widget _buildMessageDeliveryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), border: Border.all(color: _ancientGold.withValues(alpha: 0.25)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Expanded(child: Text('Message Delivery Stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ancientGold), overflow: TextOverflow.ellipsis)), SizedBox(width: 8), Icon(Icons.info_outline, color: _ancientGold, size: 16)]),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(children: [
                  _buildStatColumn(dashboardData?.messageAnalytics?.marketing.toString() ?? '0', 'Marketing'), const SizedBox(height: 16),
                  _buildStatColumn(dashboardData?.messageAnalytics?.authentication.toString() ?? '0', 'Auth'), const SizedBox(height: 16),
                  _buildStatColumn(dashboardData?.messageAnalytics?.service.toString() ?? '0', 'Service'), const SizedBox(height: 16),
                  _buildStatColumn(dashboardData?.messageAnalytics?.utility.toString() ?? '0', 'Utility'), const SizedBox(height: 16),
                  _buildStatColumn(dashboardData?.messageAnalytics?.total.toString() ?? '0', 'Total'),
                ]);
              } else {
                return ResponsiveRow(children: [
                  Expanded(child: _buildStatColumn(dashboardData?.messageAnalytics?.marketing.toString() ?? '0', 'Marketing')),
                  Expanded(child: _buildStatColumn(dashboardData?.messageAnalytics?.authentication.toString() ?? '0', 'Auth')),
                  Expanded(child: _buildStatColumn(dashboardData?.messageAnalytics?.service.toString() ?? '0', 'Service')),
                  Expanded(child: _buildStatColumn(dashboardData?.messageAnalytics?.utility.toString() ?? '0', 'Utility')),
                  Expanded(child: _buildStatColumn(dashboardData?.messageAnalytics?.total.toString() ?? '0', 'Total')),
                ]);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), border: Border.all(color: _ancientGold.withValues(alpha: 0.25)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Expanded(child: Text('Messages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ancientGold), overflow: TextOverflow.ellipsis)), SizedBox(width: 8), Icon(Icons.info_outline, color: _ancientGold, size: 16)]),
          const SizedBox(height: 20),
          ResponsiveRow(children: [
            Expanded(child: _buildStatColumn(dashboardData?.messageAnalytics?.sent.toString() ?? '0', 'Sent')), const SizedBox(width: 16),
            Expanded(child: _buildStatColumn(dashboardData?.messageAnalytics?.delivered.toString() ?? '0', 'Delivered')),
          ]),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(children: [_buildPlanCard(), const SizedBox(height: 16), _buildContactsCard(context), const SizedBox(height: 16), _buildQuickLinksCard()]);
        } else {
          return ResponsiveRow(children: [Expanded(child: _buildPlanCard()), const SizedBox(width: 16), Expanded(child: _buildContactsCard(context)), const SizedBox(width: 16), Expanded(child: _buildQuickLinksCard())]);
        }
      },
    );
  }

  Widget _buildPlanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), border: Border.all(color: _ancientGold.withValues(alpha: 0.25)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.credit_card, color: _ancientGold, size: 20), SizedBox(width: 8), Expanded(child: Text('Meta Fly Plan: Free', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ancientGold), overflow: TextOverflow.ellipsis))]),
          const SizedBox(height: 16),
          _buildPlanItem('Message templates', '0 / 250'), _buildPlanItem('Contacts', '1 / 500'), _buildPlanItem('Messages', '2 / 1,000'),
          _buildPlanItem('Bulk broadcast notifications', '0 / 8'), _buildPlanItem('Transactional notifications', '0 / 1'), _buildPlanItem('API Requests', '0 / 100'),
        ],
      ),
    );
  }

  Widget _buildContactsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), border: Border.all(color: _ancientGold.withValues(alpha: 0.25)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.contacts, color: _ancientGold, size: 20), SizedBox(width: 8), Expanded(child: Text('Contacts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ancientGold), overflow: TextOverflow.ellipsis))]),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/contacts'),
            child: Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _ancientGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)), child: const Text('1', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.w600))),
              const SizedBox(width: 8),
              Text('Contacts', style: TextStyle(color: Colors.grey[400])),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinksCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), border: Border.all(color: _ancientGold.withValues(alpha: 0.25)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.link, color: _ancientGold, size: 20), SizedBox(width: 8), Expanded(child: Text('Quick Links', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ancientGold), overflow: TextOverflow.ellipsis))]),
          const SizedBox(height: 16),
          _buildQuickLink(Icons.chat, 'Follow us on WhatsApp', _ancientGold),
          _buildQuickLink(Icons.facebook, 'Join our Facebook group', _ancientGold),
          _buildQuickLink(Icons.star, 'Review us on TrustPilot', _ancientGold),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(error ?? 'An error occurred', style: TextStyle(color: Colors.red[600], fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: onRefresh, icon: const Icon(Icons.refresh, color: Colors.black), label: const Text('Retry', style: TextStyle(color: Colors.black)), style: ElevatedButton.styleFrom(backgroundColor: _ancientGold, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12))),
          ],
        ),
      ),
    );
  }

  String _getConnectionStatus() {
    if (dashboardData?.phoneNumberStatus?.status == 'VERIFIED') return 'CONNECTED';
    return 'DISCONNECTED';
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _ancientGold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPlanItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[400]), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ancientGold), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildQuickLink(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {},
        child: Row(
          children: [
            Icon(icon, color: color, size: 16), const SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: color, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis)),
            Icon(Icons.open_in_new, color: Colors.grey[500], size: 14),
          ],
        ),
      ),
    );
  }
}