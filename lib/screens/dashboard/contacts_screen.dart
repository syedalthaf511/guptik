import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  
  // Contacts data - starts empty, will be populated from database
  final List<Map<String, dynamic>> _contacts = [];

  List<String> get _filters => ['All', 'Recent', 'Favorites', 'Tagged', 'Untagged'];

  List<Map<String, dynamic>> get _filteredContacts {
    var filtered = _contacts.where((contact) {
      final matchesSearch = _searchController.text.isEmpty ||
          contact['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
          contact['phone'].toString().contains(_searchController.text) ||
          (contact['email']?.toString().toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);
      
      final matchesFilter = _selectedFilter == 'All' || 
          (_selectedFilter == 'Tagged' && (contact['tags'] as List).isNotEmpty) ||
          (_selectedFilter == 'Untagged' && (contact['tags'] as List).isEmpty) ||
          (_selectedFilter == 'Favorites' && contact['is_favorite'] == true) ||
          (_selectedFilter == 'Recent' && contact['last_interaction'] != null);
      
      return matchesSearch && matchesFilter;
    }).toList();
    
    // Sort by name
    filtered.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Contacts',
          style: TextStyle(
            fontSize: 24,
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
            icon: const Icon(Icons.person_add, color: _ancientGold),
            onPressed: () => _showAddContactDialog(),
            tooltip: 'Add New Contact',
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
                  case 'import':
                    _showImportDialog();
                    break;
                  case 'export':
                    _showExportDialog();
                    break;
                  case 'bulk_actions':
                    _showBulkActionsDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'import',
                  child: ListTile(
                    leading: Icon(Icons.file_upload, color: Colors.blueAccent),
                    title: Text('Import Contacts', style: TextStyle(color: _ancientGold)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.file_download, color: Colors.greenAccent),
                    title: Text('Export Contacts', style: TextStyle(color: _ancientGold)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'bulk_actions',
                  child: ListTile(
                    leading: Icon(Icons.edit, color: _ancientGold),
                    title: Text('Bulk Actions', style: TextStyle(color: _ancientGold)),
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
                      Expanded(child: _buildStatCard('Total Contacts', _contacts.length.toString(), Icons.people, Colors.blueAccent)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Tagged', _contacts.where((c) => (c['tags'] as List).isNotEmpty).length.toString(), Icons.local_offer, Colors.purpleAccent)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatCard('Favorites', _contacts.where((c) => c['is_favorite'] == true).length.toString(), Icons.favorite, Colors.redAccent)),
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
                          hintText: 'Search contacts by name, phone, or email...',
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
                
                // Contacts List
                Expanded(
                  child: _filteredContacts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          itemCount: _filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _filteredContacts[index];
                            return _buildContactCard(contact);
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
                Icons.contacts_outlined,
                size: 64,
                color: _ancientGold.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchController.text.isEmpty && _selectedFilter == 'All' 
                  ? 'No contacts yet'
                  : 'No contacts found',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _ancientGold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isEmpty && _selectedFilter == 'All'
                  ? 'Add your first contact to get started'
                  : 'Try adjusting your search or filter criteria',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            if (_searchController.text.isEmpty && _selectedFilter == 'All') ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showAddContactDialog(),
                icon: const Icon(Icons.person_add, color: Colors.black),
                label: const Text('Add First Contact', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildContactCard(Map<String, dynamic> contact) {
    final tags = contact['tags'] as List<String>;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _ancientGold.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: _ancientGold.withValues(alpha: 0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.6),
            child: Text(
              contact['name'].toString().substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: _ancientGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            if (contact['is_favorite'] == true)
              const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              contact['phone'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[300],
                fontFamily: 'monospace',
              ),
            ),
            if (contact['email']?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                contact['email'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _ancientGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _ancientGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: Theme(
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
                case 'edit':
                  _editContact(contact);
                  break;
                case 'delete':
                  _deleteContact(contact['id']);
                  break;
                case 'favorite':
                  _toggleFavorite(contact['id']);
                  break;
                case 'message':
                  _sendMessage(contact);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'message',
                child: ListTile(
                  leading: Icon(Icons.message, color: Colors.blueAccent),
                  title: Text('Send Message', style: TextStyle(color: Colors.white)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'favorite',
                child: ListTile(
                  leading: Icon(contact['is_favorite'] == true ? Icons.favorite : Icons.favorite_border, color: Colors.redAccent),
                  title: Text(contact['is_favorite'] == true ? 'Remove from Favorites' : 'Add to Favorites', style: const TextStyle(color: Colors.white)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit, color: _ancientGold),
                  title: Text('Edit', style: TextStyle(color: Colors.white)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.redAccent),
                  title: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Add New Contact', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name *',
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
                controller: phoneController,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: 'Phone Number *',
                  labelStyle: TextStyle(color: Colors.grey[500], fontFamily: 'sans-serif'),
                  prefixText: '+',
                  prefixStyle: const TextStyle(color: _ancientGold, fontWeight: FontWeight.bold),
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
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
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
                keyboardType: TextInputType.emailAddress,
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
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                setState(() {
                  _contacts.add({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'name': nameController.text,
                    'phone': '+${phoneController.text}',
                    'email': emailController.text,
                    'tags': <String>[],
                    'is_favorite': false,
                    'created_date': DateTime.now().toString().split(' ')[0],
                    'last_interaction': null,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contact added successfully', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.greenAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _ancientGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Add Contact', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _editContact(Map<String, dynamic> contact) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit contact functionality - Coming soon!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _deleteContact(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Contact', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to delete this contact? This action cannot be undone.',
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
                _contacts.removeWhere((contact) => contact['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact deleted successfully', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  void _toggleFavorite(String id) {
    setState(() {
      final index = _contacts.indexWhere((contact) => contact['id'] == id);
      if (index != -1) {
        _contacts[index]['is_favorite'] = !(_contacts[index]['is_favorite'] ?? false);
      }
    });
  }

  void _sendMessage(Map<String, dynamic> contact) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Send message to ${contact['name']} - Coming soon!', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Import Contacts', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        content: const Text('Choose how you want to import contacts:', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Import from CSV - Coming soon!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: _ancientGold,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _ancientGold, foregroundColor: Colors.black),
            child: const Text('From CSV', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Export Contacts', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        content: Text('Export ${_contacts.length} contacts to CSV file?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export to CSV - Coming soon!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: _ancientGold,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _ancientGold, foregroundColor: Colors.black),
            child: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBulkActionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Bulk Actions', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        content: const Text('Select bulk action to perform:', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bulk actions - Coming soon!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: _ancientGold,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _ancientGold, foregroundColor: Colors.black),
            child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}