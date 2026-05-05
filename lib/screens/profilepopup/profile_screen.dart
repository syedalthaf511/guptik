import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Loading state to disable the save button while saving
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- 1. LOAD DATA FROM SUPABASE ---
  void _loadUserProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        // Load Name from 'user_metadata' (JSON)
        _nameController.text = user.userMetadata?['full_name'] ?? '';
        
        // Load Phone from the core Auth table
        _phoneController.text = user.phone ?? '';
      });
    }
  }

  // --- 2. SAVE DATA TO SUPABASE ---
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      // Updates strictly authentication details (Phone) and metadata (Name)
      final updates = UserAttributes(
        // Update the core phone column
        phone: phone.isNotEmpty ? phone : null,
        // Update the custom metadata JSON
        data: {
          'full_name': name, 
        },
      );

      await Supabase.instance.client.auth.updateUser(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: _ancientGold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
        ),
        actions: [
          // Show spinner if loading, otherwise show Save button
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: _ancientGold,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // The Shared Cinematic Nebula Background
          const Positioned.fill(child: DynamicAppBackground()),
          
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 120, 16, 32), // Added top padding for the extended app bar
            child: Column(
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _ancientGold.withValues(alpha: 0.5), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _ancientGold.withValues(alpha: 0.1),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: _ancientGold.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(color: _ancientGold, width: 2),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: _ancientGold, size: 20),
                            onPressed: _changeProfilePicture,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Profile Form
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _ancientGold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: Icons.person_outline,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Account Settings
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.security, color: _ancientGold),
                        title: const Text('Security Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text('Password, two-factor authentication', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: _ancientGold.withValues(alpha: 0.7)),
                        onTap: () {
                          // Navigate to security settings
                        },
                      ),
                      Divider(height: 1, color: _ancientGold.withValues(alpha: 0.2)),
                      ListTile(
                        leading: const Icon(Icons.notifications_outlined, color: _ancientGold),
                        title: const Text('Notification Preferences', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text('Manage how you receive notifications', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: _ancientGold.withValues(alpha: 0.7)),
                        onTap: () {
                          // Navigate to notification settings
                        },
                      ),
                      Divider(height: 1, color: _ancientGold.withValues(alpha: 0.2)),
                      ListTile(
                        leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        title: const Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Permanently delete your account', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
                        onTap: _showDeleteAccountDialog,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: _ancientGold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(icon, color: _ancientGold),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _ancientGold, width: 2),
        ),
      ),
    );
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _ancientGold.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: _ancientGold),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // Implement camera functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📸 Camera functionality will be implemented', style: TextStyle(color: Colors.black)),
                      backgroundColor: _ancientGold,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: _ancientGold),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // Implement gallery functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🖼️ Gallery functionality will be implemented', style: TextStyle(color: Colors.black)),
                      backgroundColor: _ancientGold,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  // Implement remove functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🗑️ Photo removed', style: TextStyle(color: Colors.black)),
                      backgroundColor: _ancientGold,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion will be implemented', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}