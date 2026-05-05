import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  
  // Notifications data - starts empty
  final List<Map<String, dynamic>> _notifications = [];

  List<String> get _filters => ['All', 'Sent', 'Scheduled', 'Draft', 'Failed'];

  List<Map<String, dynamic>> get _filteredNotifications {
    var filtered = _notifications.where((notification) {
      final matchesSearch = _searchController.text.isEmpty ||
          notification['title'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
          notification['message'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      
      final matchesFilter = _selectedFilter == 'All' || notification['status'] == _selectedFilter.toLowerCase();
      
      return matchesSearch && matchesFilter;
    }).toList();
    
    // Sort by created date (newest first)
    filtered.sort((a, b) => DateTime.parse(b['created_date']).compareTo(DateTime.parse(a['created_date'])));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Manage Notifications',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _ancientGold,
          ),
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
            icon: const Icon(Icons.add, color: _ancientGold),
            onPressed: () => _createNotification(),
            tooltip: 'Create New Notification',
          ),
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: Colors.black,
              iconTheme: const IconThemeData(color: _ancientGold),
            ),
            child: PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: _ancientGold.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'templates':
                    _manageTemplates();
                    break;
                  case 'schedule':
                    _viewScheduled();
                    break;
                  case 'analytics':
                    _viewAnalytics();
                    break;
                  case 'settings':
                    _openSettings();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'templates',
                  child: ListTile(
                    leading: Icon(Icons.article, color: Colors.blueAccent),
                    title: Text('Templates', style: TextStyle(color: Colors.white)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'schedule',
                  child: ListTile(
                    leading: Icon(Icons.schedule, color: Colors.orangeAccent),
                    title: Text('Scheduled', style: TextStyle(color: Colors.white)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'analytics',
                  child: ListTile(
                    leading: Icon(Icons.analytics, color: Colors.purpleAccent),
                    title: Text('Analytics', style: TextStyle(color: Colors.white)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings, color: _ancientGold),
                    title: Text('Settings', style: TextStyle(color: Colors.white)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
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
            
            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight), // Push below transparent AppBar
                
                // Header Stats
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: _buildStatCard('Total Sent', _notifications.where((n) => n['status'] == 'sent').length.toString(), Icons.send, Colors.greenAccent)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Scheduled', _notifications.where((n) => n['status'] == 'scheduled').length.toString(), Icons.schedule, Colors.orangeAccent)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Failed', _notifications.where((n) => n['status'] == 'failed').length.toString(), Icons.error, Colors.redAccent)),
                    ],
                  ),
                ),
                
                // Search and Filter Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search notifications...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: const Icon(Icons.search, color: _ancientGold),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.5),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.white54),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _ancientGold, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Filter Row
                      Row(
                        children: [
                          const Text(
                            'Filter: ',
                            style: TextStyle(fontWeight: FontWeight.bold, color: _ancientGold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _filters.map((filter) {
                                  final isSelected = _selectedFilter == filter;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(
                                        filter,
                                        style: TextStyle(
                                          color: isSelected ? _ancientGold : Colors.white70,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedFilter = filter;
                                        });
                                      },
                                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                                      selectedColor: _ancientGold.withValues(alpha: 0.15),
                                      checkmarkColor: _ancientGold,
                                      side: BorderSide(color: isSelected ? _ancientGold : Colors.white24),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Notifications List
                Expanded(
                  child: _filteredNotifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = _filteredNotifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // THE FIX: Wrapped in SingleChildScrollView to prevent bottom overflow
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _ancientGold.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Icon(
                Icons.notifications_none,
                size: 64,
                color: _ancientGold.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchController.text.isEmpty && _selectedFilter == 'All' 
                  ? 'No notifications yet'
                  : 'No notifications found',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _ancientGold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isEmpty && _selectedFilter == 'All'
                  ? 'Create your first notification to reach your contacts'
                  : 'Try adjusting your search or filter criteria',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchController.text.isEmpty && _selectedFilter == 'All') ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _createNotification(),
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('Create First Notification', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ancientGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _ancientGold.withValues(alpha: 0.1),
        border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final status = notification['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${notification['recipient_count']} recipients',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                notification['message'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Created: ${notification['created_date']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (notification['scheduled_date'] != null) ...[
                  Icon(Icons.schedule, size: 14, color: Colors.orangeAccent),
                  const SizedBox(width: 6),
                  Text(
                    'Scheduled: ${notification['scheduled_date']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            // THE FIX: Flexible row prevents button overflow on narrow screens
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _duplicateNotification(notification),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Duplicate', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ancientGold,
                      side: BorderSide(color: _ancientGold.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (status == 'sent') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewAnalytics(notification),
                      icon: const Icon(Icons.analytics, size: 16),
                      label: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _editNotification(notification),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ancientGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: IconButton(
                    onPressed: () => _deleteNotification(notification['id']),
                    icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                    tooltip: 'Delete',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'sent':
        return Colors.greenAccent;
      case 'scheduled':
        return Colors.orangeAccent;
      case 'draft':
        return Colors.grey[400]!;
      case 'failed':
        return Colors.redAccent;
      default:
        return _ancientGold;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'sent':
        return Icons.check_circle;
      case 'scheduled':
        return Icons.schedule;
      case 'draft':
        return Icons.drafts;
      case 'failed':
        return Icons.error;
      default:
        return Icons.notifications;
    }
  }

  void _createNotification() {
    _showCreateNotificationDialog();
  }

  void _showCreateNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    bool scheduleDelivery = false;
    DateTime? scheduledDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: _ancientGold, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Create New Notification', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Notification Title *',
                    labelStyle: TextStyle(color: Colors.grey[500]),
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
                TextField(
                  controller: messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Message *',
                    labelStyle: TextStyle(color: Colors.grey[500]),
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
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                Theme(
                  data: ThemeData(
                    unselectedWidgetColor: Colors.white54,
                  ),
                  child: CheckboxListTile(
                    activeColor: _ancientGold,
                    checkColor: Colors.black,
                    title: const Text('Schedule Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    value: scheduleDelivery,
                    onChanged: (value) => setState(() => scheduleDelivery = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                if (scheduleDelivery) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _ancientGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                    ),
                    child: ListTile(
                      title: Text(
                        scheduledDate != null 
                            ? 'Scheduled: ${scheduledDate!.toString().split(' ')[0]}'
                            : 'Select Date & Time',
                        style: const TextStyle(color: _ancientGold, fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.calendar_today, color: _ancientGold),
                      onTap: () async {
                        final selectedDate = await _selectDateTime();
                        if (selectedDate != null) {
                          setState(() {
                            scheduledDate = selectedDate;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && messageController.text.isNotEmpty) {
                  this.setState(() {
                    _notifications.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleController.text,
                      'message': messageController.text,
                      'status': scheduleDelivery ? 'scheduled' : 'draft',
                      'recipient_count': 0, // Will be calculated when sent
                      'created_date': DateTime.now().toString().split(' ')[0],
                      'scheduled_date': scheduledDate?.toString().split(' ')[0],
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        scheduleDelivery ? 'Notification scheduled successfully' : 'Notification draft created successfully',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.greenAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _ancientGold,
                foregroundColor: Colors.black,
              ),
              child: Text(scheduleDelivery ? 'Schedule' : 'Create Draft', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _editNotification(Map<String, dynamic> notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit "${notification['title']}" - Coming soon!', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _duplicateNotification(Map<String, dynamic> notification) {
    setState(() {
      _notifications.add({
        ...notification,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': '${notification['title']} (Copy)',
        'status': 'draft',
        'created_date': DateTime.now().toString().split(' ')[0],
        'scheduled_date': null,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification duplicated successfully', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.greenAccent,
      ),
    );
  }

  void _viewAnalytics([Map<String, dynamic>? notification]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification analytics - Coming soon!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _deleteNotification(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Notification', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to delete this notification? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notifications.removeWhere((notification) => notification['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification deleted successfully', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.greenAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.black),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null && mounted) {
        return DateTime(date.year, date.month, date.day, time.hour, time.minute);
      }
    }
    return null;
  }

  void _manageTemplates() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification templates - Coming soon!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _viewScheduled() {
    setState(() {
      _selectedFilter = 'Scheduled';
    });
  }

  void _openSettings() {
    Navigator.pushNamed(context, '/notification-settings');
  }
}