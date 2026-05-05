import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

// THE FIX: Added SingleTickerProviderStateMixin to safely manage the TabController
class _ImportExportScreenState extends State<ImportExportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Import / Export',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _ancientGold,
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: _ancientGold),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _ancientGold,
          labelColor: _ancientGold,
          unselectedLabelColor: Colors.white54,
          dividerColor: _ancientGold.withValues(alpha: 0.2),
          tabs: const [
            Tab(text: 'Import', icon: Icon(Icons.file_upload)),
            Tab(text: 'Export', icon: Icon(Icons.file_download)),
          ],
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
            
            TabBarView(
              controller: _tabController,
              children: [
                _buildImportTab(),
                _buildExportTab(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 140, 16, 40), // Padded top to account for transparent AppBar+TabBar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Import Statistics
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _ancientGold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.cloud_upload,
                    size: 48,
                    color: _ancientGold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Import Contacts',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Import contacts from various sources to quickly build your contact database.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Import Options
          const Text(
            'Import Options',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _ancientGold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildImportOption(
            icon: Icons.description,
            title: 'CSV File',
            description: 'Import contacts from a CSV file with name, phone, email columns',
            onTap: () => _showImportDialog('CSV'),
          ),
          
          _buildImportOption(
            icon: Icons.table_chart,
            title: 'Excel File',
            description: 'Import contacts from an Excel spreadsheet (.xlsx, .xls)',
            onTap: () => _showImportDialog('Excel'),
          ),
          
          _buildImportOption(
            icon: Icons.contact_phone,
            title: 'vCard File',
            description: 'Import contacts from vCard (.vcf) files',
            onTap: () => _showImportDialog('vCard'),
          ),
          
          _buildImportOption(
            icon: Icons.code,
            title: 'JSON File',
            description: 'Import contacts from JSON format files',
            onTap: () => _showImportDialog('JSON'),
          ),
          
          const SizedBox(height: 32),
          
          // Import History
          const Text(
            'Recent Imports',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _ancientGold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(32),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No import history yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your import history will appear here once you start importing contacts.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 140, 16, 40), // Padded top to account for transparent AppBar+TabBar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Export Statistics
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _ancientGold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.cloud_download,
                    size: 48,
                    color: _ancientGold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Export Contacts',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Export your contacts to various formats for backup or use in other applications.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Export Options
          const Text(
            'Export Options',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _ancientGold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildExportOption(
            icon: Icons.description,
            title: 'Export to CSV',
            description: 'Export all contacts to a CSV file',
            contactCount: '0 contacts',
            onTap: () => _showExportDialog('CSV'),
          ),
          
          _buildExportOption(
            icon: Icons.table_chart,
            title: 'Export to Excel',
            description: 'Export contacts to an Excel spreadsheet',
            contactCount: '0 contacts',
            onTap: () => _showExportDialog('Excel'),
          ),
          
          _buildExportOption(
            icon: Icons.contact_phone,
            title: 'Export to vCard',
            description: 'Export contacts to vCard format',
            contactCount: '0 contacts',
            onTap: () => _showExportDialog('vCard'),
          ),
          
          _buildExportOption(
            icon: Icons.code,
            title: 'Export to JSON',
            description: 'Export contacts in JSON format',
            contactCount: '0 contacts',
            onTap: () => _showExportDialog('JSON'),
          ),
          
          const SizedBox(height: 32),
          
          // Export Filters
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.filter_alt,
                      color: _ancientGold,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Export Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Customize your export by selecting specific contact groups:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                _buildFilterOption('All Contacts', true),
                _buildFilterOption('Tagged Contacts Only', false),
                _buildFilterOption('Favorites Only', false),
                _buildFilterOption('Specific Lists', false),
                _buildFilterOption('Smart Segments', false),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Export History
          const Text(
            'Recent Exports',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _ancientGold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(32),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.white24,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No export history yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your export history will appear here once you start exporting contacts.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _ancientGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _ancientGold.withValues(alpha: 0.4)),
          ),
          child: Icon(
            icon,
            color: _ancientGold,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: _ancientGold,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String description,
    required String contactCount,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ancientGold.withValues(alpha: 0.3), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _ancientGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _ancientGold.withValues(alpha: 0.4)),
          ),
          child: Icon(
            icon,
            color: _ancientGold,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _ancientGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                ),
                child: Text(
                  contactCount,
                  style: const TextStyle(
                    color: _ancientGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: const Icon(
          Icons.download,
          color: _ancientGold,
          size: 24,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFilterOption(String title, bool isSelected) {
    return Theme(
      data: ThemeData(
        unselectedWidgetColor: Colors.white54,
      ),
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        value: isSelected,
        onChanged: (value) {
          // Handle filter selection
        },
        contentPadding: EdgeInsets.zero,
        activeColor: _ancientGold,
        checkColor: Colors.black,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  void _showImportDialog(String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Import from $format', style: const TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.file_upload,
                size: 64,
                color: _ancientGold,
              ),
              const SizedBox(height: 20),
              Text(
                'Select a $format file to import contacts.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Required columns: Name, Phone Number\nOptional: Email, Tags, Notes',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$format import - Coming soon!', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: _ancientGold,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _ancientGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Choose File', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(String format) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Export to $format', style: const TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.file_download,
                size: 64,
                color: _ancientGold,
              ),
              const SizedBox(height: 20),
              Text(
                'Export your contacts to $format format.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'This will include all contact information including names, phone numbers, emails, and tags.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$format export - Coming soon!', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: _ancientGold,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _ancientGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}