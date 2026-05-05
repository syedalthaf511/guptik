import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class WhatsAppNumbersScreen extends StatefulWidget {
  const WhatsAppNumbersScreen({super.key});

  @override
  State<WhatsAppNumbersScreen> createState() => _WhatsAppNumbersScreenState();
}

class _WhatsAppNumbersScreenState extends State<WhatsAppNumbersScreen> {
  final List<Map<String, dynamic>> _accounts = [];

  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _phoneIdController = TextEditingController();
  final TextEditingController _businessIdController = TextEditingController();
  final TextEditingController _appIdController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedKeys();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _phoneIdController.dispose();
    _businessIdController.dispose();
    _appIdController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedKeys() async {
    try {
      setState(() => _isLoading = true);
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('user_api_settings')
          .select()
          .eq('user_id', user.id);

      if (mounted) {
        setState(() {
          _accounts.clear();
          for (var item in response) {
            _accounts.add({
              'id': item['id'],
              'token': item['whatsapp_access_token'],
              'phone_id': item['meta_wa_phone_number_id'],
              'business_id': item['meta_business_account_id'],
              'app_id': item['meta_app_id'],
              'mobile_number': item['mobile_number'],
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading saved keys: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addAccountToSupabase() async {
    if (_tokenController.text.isEmpty ||
        _phoneIdController.text.isEmpty ||
        _businessIdController.text.isEmpty ||
        _appIdController.text.isEmpty) {
      return;
    }

    try {
      Navigator.pop(context);
      setState(() => _isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final data = {
        'user_id': user.id,
        'whatsapp_access_token': _tokenController.text,
        'meta_wa_phone_number_id': _phoneIdController.text,
        'meta_business_account_id': _businessIdController.text,
        'meta_app_id': _appIdController.text,
        'mobile_number': _mobileNumberController.text,
      };

      final response = await Supabase.instance.client
          .from('user_api_settings')
          .upsert(data, onConflict: 'user_id')
          .select()
          .single();

      setState(() {
        _accounts.clear();
        _accounts.add({
          'id': response['id'],
          'token': _tokenController.text,
          'phone_id': _phoneIdController.text,
          'business_id': _businessIdController.text,
          'app_id': _appIdController.text,
          'mobile_number': _mobileNumberController.text,
        });
      });

      _tokenController.clear();
      _phoneIdController.clear();
      _businessIdController.clear();
      _appIdController.clear();
      _mobileNumberController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account settings saved successfully', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount(int index) async {
    try {
      final accountId = _accounts[index]['id'];
      if (accountId == null) return;

      await Supabase.instance.client
          .from('user_api_settings')
          .delete()
          .eq('id', accountId);

      setState(() {
        _accounts.removeAt(index);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration deleted', style: TextStyle(color: Colors.black)),
            backgroundColor: _ancientGold,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting: $e', style: const TextStyle(color: Colors.black)),
          backgroundColor: Colors.redAccent,
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
          'Meta API Settings',
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
          if (_accounts.isEmpty)
            IconButton(
              icon: const Icon(Icons.add, color: _ancientGold),
              onPressed: _showAddAccountDialog,
            ),
        ],
      ),
      // THE FIX: Wrap the body in an expanding Container so the background covers all scrolling
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // The Shared Cinematic Nebula Background
            const Positioned.fill(child: DynamicAppBackground()),
            
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: _ancientGold))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WhatsApp Business Configuration',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _ancientGold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your Meta API keys and tokens for WhatsApp integration.',
                          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 30),

                        if (_accounts.isEmpty)
                          _buildEmptyState()
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _accounts.length,
                            itemBuilder: (context, index) {
                              return _buildAccountCard(_accounts[index], index);
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 2),
              ),
              child: Icon(
                Icons.api_rounded,
                size: 64,
                color: _ancientGold.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No API keys configured.',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showAddAccountDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ancientGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Configure Now", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Active Configuration",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _ancientGold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: _ancientGold, width: 1.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Delete Config?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        content: const Text('Are you sure you want to remove these API keys?', style: TextStyle(color: Colors.white70)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.black),
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteAccount(index);
                            },
                            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            Divider(color: _ancientGold.withValues(alpha: 0.2), height: 20),
            _buildInfoRow("App ID", account['app_id'] ?? ''),
            _buildInfoRow("Phone ID", account['phone_id'] ?? ''),
            _buildInfoRow("Business ID", account['business_id'] ?? ''),
            _buildInfoRow("Mobile", account['mobile_number'] ?? 'Not provided'),
            _buildInfoRow(
              "Token",
              "••••••••${(account['token'] ?? '').toString().characters.takeLast(4)}",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
          ),
          SizedBox(
            width: 32,
            height: 24,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.copy, size: 16, color: _ancientGold),
              tooltip: 'Copy to clipboard',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    backgroundColor: _ancientGold,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: _ancientGold, fontFamily: 'monospace'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontFamily: 'sans-serif'),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[700]),
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
    );
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Configure Meta API', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _buildDialogTextField(
                controller: _tokenController,
                label: 'WhatsApp Access Token',
                hint: 'EAAG...',
              ),
              _buildDialogTextField(
                controller: _appIdController,
                label: 'Meta App ID',
                keyboardType: TextInputType.number,
              ),
              _buildDialogTextField(
                controller: _phoneIdController,
                label: 'Phone Number ID (Meta)',
                keyboardType: TextInputType.number,
              ),
              _buildDialogTextField(
                controller: _businessIdController,
                label: 'Business Account ID (Meta)',
                keyboardType: TextInputType.number,
              ),
              _buildDialogTextField(
                controller: _mobileNumberController,
                label: 'Mobile Number',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _ancientGold,
              foregroundColor: Colors.black,
            ),
            onPressed: _addAccountToSupabase,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}