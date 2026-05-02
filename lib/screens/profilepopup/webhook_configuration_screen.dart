import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guptik/screens/profilepopup/webhook_server.dart';
import 'package:guptik/screens/profilepopup/desktop_pairing_screen.dart';
import 'package:guptik/widgets/home/animated_nebula_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class WebhookConfigurationScreen extends StatefulWidget {
  const WebhookConfigurationScreen({super.key});

  @override
  State<WebhookConfigurationScreen> createState() => _WebhookConfigurationScreenState();
}

class _WebhookConfigurationScreenState extends State<WebhookConfigurationScreen> {
  final _domainController = TextEditingController();
  final _verifyTokenController = TextEditingController();
  final WebhookServer _webhookServer = WebhookServer();
  
  bool _isLocalServerRunning = false;
  String? _webhookUrl;
  
  @override
  void initState() {
    super.initState();
    _loadWebhookSettings();
    _checkServerStatus();
  }

  @override
  void dispose() {
    _domainController.dispose();
    _verifyTokenController.dispose();
    super.dispose();
  }

  void _loadWebhookSettings() {
    // Load saved webhook settings
    _domainController.text = 'your-domain.com'; // Load from config or database
    _verifyTokenController.text = 'YOUR_VERIFY_TOKEN_HERE';
    _updateWebhookUrl();
  }

  void _checkServerStatus() {
    setState(() {
      _isLocalServerRunning = _webhookServer.isRunning;
    });
  }

  void _updateWebhookUrl() {
    final domain = _domainController.text.trim();
    if (domain.isNotEmpty && domain != 'your-domain.com') {
      _webhookUrl = _webhookServer.getWebhookUrl(domain: domain);
    } else {
      _webhookUrl = _webhookServer.getWebhookUrl(); // localhost
    }
    setState(() {});
  }

  Future<void> _startLocalServer() async {
    try {
      await _webhookServer.startWebhookServer();
      setState(() {
        _isLocalServerRunning = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚀 Local webhook server started on port 8080', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to start server: $e', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _stopLocalServer() async {
    try {
      await _webhookServer.stopWebhookServer();
      setState(() {
        _isLocalServerRunning = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛑 Local webhook server stopped', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to stop server: $e', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _copyWebhookUrl() {
    if (_webhookUrl != null) {
      Clipboard.setData(ClipboardData(text: _webhookUrl!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Webhook URL copied to clipboard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: _ancientGold,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Webhook Configuration',
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
            icon: const Icon(Icons.help_outline, color: _ancientGold),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      // THE FIX: Full screen container ensures the background stretches to cover all scrollable area
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
                  // Header Card
                  Container(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.webhook, color: _ancientGold, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'WhatsApp Webhook Setup',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _ancientGold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Desktop Device Pairing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text("Connect your mobile to your local desktop server", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            trailing: Icon(Icons.chevron_right, color: _ancientGold.withValues(alpha: 0.8)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const DesktopPairingScreen()),
                              );
                            },
                          ),
                          Divider(color: _ancientGold.withValues(alpha: 0.2)),
                          const SizedBox(height: 8),
                          Text(
                            'Configure webhooks to receive real-time updates from WhatsApp Business API including message delivery status, incoming messages, and template approvals.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Webhook URL Configuration
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Webhook URL Configuration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _ancientGold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Domain Input
                          TextFormField(
                            controller: _domainController,
                            onChanged: (value) => _updateWebhookUrl(),
                            style: const TextStyle(color: _ancientGold, fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              labelText: 'Your Domain',
                              labelStyle: TextStyle(color: Colors.grey[500], fontFamily: 'sans-serif'),
                              hintText: 'example.com',
                              hintStyle: TextStyle(color: Colors.grey[700]),
                              prefixIcon: const Icon(Icons.language, color: _ancientGold),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.3),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _ancientGold, width: 2),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Verify Token Input
                          TextFormField(
                            controller: _verifyTokenController,
                            style: const TextStyle(color: _ancientGold, fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              labelText: 'Verify Token',
                              labelStyle: TextStyle(color: Colors.grey[500], fontFamily: 'sans-serif'),
                              hintText: 'Enter a secure verify token',
                              hintStyle: TextStyle(color: Colors.grey[700]),
                              prefixIcon: const Icon(Icons.security, color: _ancientGold),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.3),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: _ancientGold, width: 2),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Generated Webhook URL
                          if (_webhookUrl != null) ...[
                            const Text(
                              'Generated Webhook URL:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _ancientGold.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _webhookUrl!,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                        color: _ancientGold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 18, color: _ancientGold),
                                    onPressed: _copyWebhookUrl,
                                    tooltip: 'Copy URL',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Local Development Server
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.computer,
                                color: _isLocalServerRunning ? Colors.greenAccent : Colors.grey[600],
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Local Development',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _isLocalServerRunning 
                                      ? Colors.greenAccent.withValues(alpha: 0.15) 
                                      : Colors.grey.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: _isLocalServerRunning 
                                        ? Colors.greenAccent.withValues(alpha: 0.5) 
                                        : Colors.grey.withValues(alpha: 0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _isLocalServerRunning ? 'RUNNING' : 'STOPPED',
                                  style: TextStyle(
                                    color: _isLocalServerRunning ? Colors.greenAccent : Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'For testing webhooks locally during development. The server will run on http://localhost:8080',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLocalServerRunning ? null : _startLocalServer,
                                  icon: Icon(Icons.play_arrow, color: _isLocalServerRunning ? Colors.grey[600] : Colors.black),
                                  label: Text('Start Server', style: TextStyle(fontWeight: FontWeight.bold, color: _isLocalServerRunning ? Colors.grey[600] : Colors.black)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent,
                                    disabledBackgroundColor: Colors.grey[800],
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLocalServerRunning ? _stopLocalServer : null,
                                  icon: Icon(Icons.stop, color: !_isLocalServerRunning ? Colors.grey[600] : Colors.white),
                                  label: Text('Stop Server', style: TextStyle(fontWeight: FontWeight.bold, color: !_isLocalServerRunning ? Colors.grey[600] : Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    disabledBackgroundColor: Colors.grey[800],
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Setup Instructions
                  Container(
                    decoration: BoxDecoration(
                      color: _ancientGold.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: _ancientGold),
                              SizedBox(width: 12),
                              Text(
                                'WhatsApp Configuration Steps',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _ancientGold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '1. Go to Facebook Developers Console\n'
                            '2. Select your WhatsApp Business app\n'
                            '3. Navigate to WhatsApp > Configuration\n'
                            '4. Add the webhook URL above\n'
                            '5. Enter the verify token\n'
                            '6. Subscribe to webhook events:\n'
                            '   • messages\n'
                            '   • message_deliveries\n'
                            '   • message_reads\n'
                            '   • message_template_status_update',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[300],
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
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

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.build_circle_outlined, color: _ancientGold),
            SizedBox(width: 10),
            Text('Webhook Help', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'What are webhooks?',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Webhooks allow WhatsApp to send real-time notifications to your app when events occur, such as:',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              Text('• New messages from customers', style: TextStyle(color: Colors.grey[400])),
              Text('• Message delivery confirmations', style: TextStyle(color: Colors.grey[400])),
              Text('• Template approval status', style: TextStyle(color: Colors.grey[400])),
              Text('• Account alerts', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 16),
              const Text(
                'Setup Requirements:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text('1. HTTPS endpoint (required for production)', style: TextStyle(color: Colors.grey[400])),
              Text('2. Verify token for security', style: TextStyle(color: Colors.grey[400])),
              Text('3. Facebook webhook configuration', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _ancientGold.withValues(alpha: 0.1),
                  border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'For local testing, use ngrok or similar tunnel service to expose your localhost webhook to the internet.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: _ancientGold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}