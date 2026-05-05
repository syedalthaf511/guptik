import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _callbackUrlController = TextEditingController();
  final _verifyTokenController = TextEditingController();

  bool _isLoading = false;
  bool _isValidating = false;
  final bool _showAccessToken = false;
  String? _metaflyApiKey;

  @override
  void initState() {
    super.initState();
    _loadSavedKeys();
  }

  @override
  void dispose() {
    _callbackUrlController.dispose();
    _verifyTokenController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedKeys() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Load saved API keys from user metadata or a separate table
      final response = await Supabase.instance.client
          .from('user_api_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _callbackUrlController.text =
              response['callback_url'] ?? 'https://app.metafly.com/webhooks';
          _verifyTokenController.text = response['verify_token'] ?? 'meta-fly';
          _metaflyApiKey = response['metafly_api_key'];
        });
      } else {
        // Set default values for new users
        setState(() {
          _callbackUrlController.text = 'https://app.metafly.com/webhooks';
          _verifyTokenController.text = 'meta-fly';
        });
      }
    } catch (e) {
      // Table might not exist yet, that's okay
    }
  }

  Future<void> _saveApiKeys() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Generate MetaFly API key if not exists
      if (_metaflyApiKey == null || _metaflyApiKey!.isEmpty) {
        _metaflyApiKey = _generateMetaFlyApiKey();
      }

      // Save API keys to database
      await Supabase.instance.client.from('user_api_settings').upsert({
        'user_id': user.id,
        'callback_url': _callbackUrlController.text.trim(),
        'verify_token': _verifyTokenController.text.trim(),
        'metafly_api_key': _metaflyApiKey,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ API keys saved successfully!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving keys: $e', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateMetaFlyApiKey() {
    // Generate a random API key similar to the format shown in the web interface
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      26,
      (index) => chars[random.hashCode % chars.length],
    ).join();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ API key copied to clipboard!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _validateAndProceed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isValidating = true);

    try {
      // Validate all required fields
      if (_callbackUrlController.text.trim().isEmpty ||
          _verifyTokenController.text.trim().isEmpty) {
        throw Exception('Please fill all required fields');
      }

      // Save the configuration first
      await _saveApiKeys();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Configuration validated and saved successfully!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Validation failed: $e', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isValidating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'API Configuration',
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
            const Positioned.fill(child: DynamicAppBackground()),
            
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
              child: Form(
                key: _formKey,
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
                                Icon(
                                  Icons.api,
                                  color: _ancientGold,
                                  size: 28,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'WhatsApp Business API Setup',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _ancientGold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Configure your WhatsApp Business API credentials to start sending messages through MetaFly.',
                              style: TextStyle(fontSize: 14, color: Colors.grey[400], height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Webhook Configuration Section
                    Divider(color: _ancientGold.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),

                    const Row(
                      children: [
                        Icon(Icons.webhook, color: _ancientGold, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Webhook Configuration',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Callback URL
                    _buildApiKeyField(
                      controller: _callbackUrlController,
                      label: 'Callback URL',
                      hint: 'https://app.metafly.com/webhooks/...',
                      icon: Icons.link,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Callback URL is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Verify Token
                    _buildApiKeyField(
                      controller: _verifyTokenController,
                      label: 'Verify Token',
                      hint: 'meta-fly',
                      icon: Icons.verified,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Verify Token is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    // Action Button (Validate and proceed)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isLoading || _isValidating)
                            ? null
                            : _validateAndProceed,
                        icon: (_isLoading || _isValidating)
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.check_circle, color: Colors.black),
                        label: Text(
                          (_isLoading || _isValidating)
                              ? 'Validating...'
                              : 'Validate and proceed',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ancientGold,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: Colors.grey[800],
                          disabledForegroundColor: Colors.grey[500],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // API Integrations Section
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
                            const Text(
                              'API Integrations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _ancientGold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Use the following API key for 3rd party integrations like WordPress, Shopify, Google Sheet etc.',
                              style: TextStyle(fontSize: 14, color: Colors.grey[400], height: 1.4),
                            ),
                            const SizedBox(height: 20),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'MetaFly.com API Key',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: _ancientGold.withValues(alpha: 0.5),
                                              ),
                                            ),
                                            child: Text(
                                              _metaflyApiKey ??
                                                  'API key will be generated after saving configuration',
                                              style: TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                                color: _metaflyApiKey != null
                                                    ? _ancientGold
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: _ancientGold,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.copy,
                                              color: Colors.black,
                                              size: 20,
                                            ),
                                            onPressed: _metaflyApiKey != null
                                                ? () => _copyToClipboard(
                                                    _metaflyApiKey!,
                                                  )
                                                : null,
                                            padding: const EdgeInsets.all(10),
                                            constraints: const BoxConstraints(
                                              minWidth: 40,
                                              minHeight: 40,
                                            ),
                                            tooltip: 'Copy',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Instructions Card
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
                                  'How to get your API keys',
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
                              '3. Get Access Token from App Dashboard\n'
                              '4. Get Phone Number ID from WhatsApp > Phone Numbers\n'
                              '5. Get Business Account ID from Business Settings',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      style: const TextStyle(color: _ancientGold, fontFamily: 'monospace'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontFamily: 'sans-serif'),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: _ancientGold),
        suffixIcon: suffixIcon,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
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
            Text('API Setup Help', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To get your WhatsApp Business API credentials:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text('🌐 Visit: developers.facebook.com', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 8),
              Text('📱 Create or select your WhatsApp Business app', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 8),
              Text('🔑 Generate Access Token in App Dashboard', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 8),
              Text('📞 Get Phone Number ID from WhatsApp section', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 8),
              Text('🏢 Get Business Account ID from Settings', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _ancientGold.withValues(alpha: 0.1),
                  border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Need help? Contact our support team!',
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