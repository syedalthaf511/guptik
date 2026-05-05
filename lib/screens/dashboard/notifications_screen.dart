import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';
// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool pushNotifications = true;
  bool emailNotifications = false;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  bool showPreview = true;
  bool groupMessages = false;
  String notificationTone = 'Default';
  TimeOfDay? quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay? quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);

  final List<String> tones = ['Default', 'Classic', 'Modern', 'Silent'];

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  void _loadNotificationSettings() {
    // Load notification preferences from SharedPreferences or Supabase
    // Current values will be default until loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Notifications',
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
                children: [
                  // General Notifications
                  _buildSettingsGroup(
                    title: 'General',
                    icon: Icons.notifications_active,
                    children: [
                      _buildSwitchTile(
                        title: 'Push Notifications',
                        subtitle: 'Receive push notifications',
                        value: pushNotifications,
                        onChanged: (value) {
                          setState(() => pushNotifications = value);
                          _saveNotificationSettings();
                        },
                      ),
                      Divider(color: _ancientGold.withValues(alpha: 0.2), height: 1),
                      _buildSwitchTile(
                        title: 'Email Notifications',
                        subtitle: 'Receive notifications via email',
                        value: emailNotifications,
                        onChanged: (value) {
                          setState(() => emailNotifications = value);
                          _saveNotificationSettings();
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Sound & Vibration
                  _buildSettingsGroup(
                    title: 'Sound & Vibration',
                    icon: Icons.volume_up,
                    children: [
                      _buildSwitchTile(
                        title: 'Sound',
                        subtitle: 'Play notification sounds',
                        value: soundEnabled,
                        onChanged: (value) {
                          setState(() => soundEnabled = value);
                          _saveNotificationSettings();
                        },
                      ),
                      Divider(color: _ancientGold.withValues(alpha: 0.2), height: 1),
                      ListTile(
                        title: const Text('Notification Tone', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('Currently: $notificationTone', style: TextStyle(color: Colors.grey[400])),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: _ancientGold),
                        onTap: _showToneDialog,
                      ),
                      Divider(color: _ancientGold.withValues(alpha: 0.2), height: 1),
                      _buildSwitchTile(
                        title: 'Vibration',
                        subtitle: 'Vibrate for notifications',
                        value: vibrationEnabled,
                        onChanged: (value) {
                          setState(() => vibrationEnabled = value);
                          _saveNotificationSettings();
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Message Notifications
                  _buildSettingsGroup(
                    title: 'Message Notifications',
                    icon: Icons.message,
                    children: [
                      _buildSwitchTile(
                        title: 'Show Preview',
                        subtitle: 'Show message content in notifications',
                        value: showPreview,
                        onChanged: (value) {
                          setState(() => showPreview = value);
                          _saveNotificationSettings();
                        },
                      ),
                      Divider(color: _ancientGold.withValues(alpha: 0.2), height: 1),
                      _buildSwitchTile(
                        title: 'Group Messages',
                        subtitle: 'Group notifications from same contact',
                        value: groupMessages,
                        onChanged: (value) {
                          setState(() => groupMessages = value);
                          _saveNotificationSettings();
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Quiet Hours
                  _buildSettingsGroup(
                    title: 'Quiet Hours',
                    icon: Icons.do_not_disturb_on,
                    children: [
                      ListTile(
                        title: const Text('Start Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(quietHoursStart?.format(context) ?? 'Not set', style: TextStyle(color: Colors.grey[400])),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _ancientGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.access_time, color: _ancientGold, size: 20),
                        ),
                        onTap: () => _selectTime(true),
                      ),
                      Divider(color: _ancientGold.withValues(alpha: 0.2), height: 1),
                      ListTile(
                        title: const Text('End Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(quietHoursEnd?.format(context) ?? 'Not set', style: TextStyle(color: Colors.grey[400])),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _ancientGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.access_time, color: _ancientGold, size: 20),
                        ),
                        onTap: () => _selectTime(false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: _ancientGold, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _ancientGold,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: _ancientGold.withValues(alpha: 0.5), height: 1, thickness: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      value: value,
      activeColor: Colors.black,
      activeTrackColor: _ancientGold,
      inactiveThumbColor: Colors.grey[400],
      inactiveTrackColor: Colors.black.withValues(alpha: 0.5),
      onChanged: onChanged,
    );
  }

  void _showToneDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Notification Tone', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: tones.map((tone) {
            return Theme(
              data: ThemeData(
                unselectedWidgetColor: Colors.white54,
              ),
              child: RadioListTile<String>(
                title: Text(tone, style: const TextStyle(color: Colors.white)),
                value: tone,
                groupValue: notificationTone,
                activeColor: _ancientGold,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      notificationTone = value;
                    });
                    Navigator.pop(context);
                    _saveNotificationSettings();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime 
          ? (quietHoursStart ?? const TimeOfDay(hour: 22, minute: 0))
          : (quietHoursEnd ?? const TimeOfDay(hour: 7, minute: 0)),
      builder: (BuildContext context, Widget? child) {
        // Theme the time picker for dark mode
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _ancientGold,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[900],
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          quietHoursStart = picked;
        } else {
          quietHoursEnd = picked;
        }
      });
      _saveNotificationSettings();
    }
  }

  void _saveNotificationSettings() {
    // Save notification preferences to SharedPreferences or Supabase
    // This will persist the user's notification settings
  }
}