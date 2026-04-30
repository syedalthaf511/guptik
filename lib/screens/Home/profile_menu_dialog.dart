import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _ancientGold = Color(0xFFD4AF37);

void showProfileMenu({
  required BuildContext context,
  required String displayName,
  required String email,
  required String initials,
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: MediaQuery.of(dialogContext).size.width < 400
              ? MediaQuery.of(dialogContext).size.width * 0.9
              : 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _ancientGold,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _ancientGold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Colors.white24),

              // Menu Items
              _buildProfileMenuItem(dialogContext, Icons.person_outline, 'My Account'),
              _buildProfileMenuItem(dialogContext, Icons.phone_android, 'WhatsApp Numbers'),
              _buildProfileMenuItem(dialogContext, Icons.facebook, 'Facebook & Instagram'),

              const Divider(height: 1, color: Colors.white24),

              _buildProfileMenuItem(dialogContext, Icons.api, 'API Configuration'),
              _buildProfileMenuItem(dialogContext, Icons.webhook, 'Webhook Configuration'),
              _buildProfileMenuItem(dialogContext, Icons.extension, 'Integrations'),
              _buildProfileMenuItem(dialogContext, Icons.card_giftcard, 'Refer and Earn'),
              _buildProfileMenuItem(dialogContext, Icons.bug_report_outlined, 'Report Bug'),

              const Divider(height: 1, color: Colors.white24),

              _buildProfileMenuItem(dialogContext, Icons.logout, 'Log Out', isDestructive: true),

              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildProfileMenuItem(BuildContext context, IconData icon, String title, {bool isDestructive = false}) {
  return InkWell(
    onTap: () {
      Navigator.of(context).pop();
      _handleProfileAction(context, title);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive ? Colors.redAccent : _ancientGold,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isDestructive ? Colors.redAccent : Colors.white70,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

void _handleProfileAction(BuildContext context, String action) {
  switch (action) {
    case 'My Account':
      Navigator.pushNamed(context, '/profile');
      break;
    case 'WhatsApp Numbers':
      Navigator.pushNamed(context, '/whatsapp-numbers');
      break;
    case 'Facebook & Instagram':
      Navigator.pushNamed(context, '/facebook-instagram');
      break;
    case 'API Configuration':
      Navigator.pushNamed(context, '/api-settings');
      break;
    case 'Webhook Configuration':
      Navigator.pushNamed(context, '/webhook-config');
      break;
    case 'Integrations':
      Navigator.pushNamed(context, '/integrations');
      break;
    case 'Refer and Earn':
      Navigator.pushNamed(context, '/referral');
      break;
    case 'Report Bug':
      Navigator.pushNamed(context, '/support');
      break;
    case 'Log Out':
      _showSignOutConfirmation(context);
      break;
  }
}

void _showSignOutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.black,
      title: const Text('Sign Out', style: TextStyle(color: _ancientGold)),
      content: const Text(
        'Are you sure you want to sign out of your account?',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: () async {
            final navigator = Navigator.of(dialogContext);
            final messenger = ScaffoldMessenger.of(dialogContext);

            navigator.pop();
            try {
              await Supabase.instance.client.auth.signOut();
              navigator.pushReplacementNamed('/login');
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Error signing out: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          child: const Text('Sign Out'),
        ),
      ],
    ),
  );
}