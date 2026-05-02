import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guptik/screens/dashboard/create_template_screen.dart';
import 'package:guptik/services/dashboard/template_service.dart';
import 'package:guptik/widgets/home/animated_nebula_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class MessageTemplatesScreen extends StatefulWidget {
  const MessageTemplatesScreen({super.key});

  @override
  State<MessageTemplatesScreen> createState() => _MessageTemplatesScreenState();
}

class _MessageTemplatesScreenState extends State<MessageTemplatesScreen> {
  final TemplateService _templateService = TemplateService();
  
  List<Map<String, dynamic>> templates = [];
  List<Map<String, dynamic>> favoriteTemplates = [];
  List<Map<String, dynamic>> recentTemplates = [];
  
  bool _isLoading = true;
  String? _error;
  
  // Feature 1: Search & Filter System
  String _searchQuery = '';
  String _selectedFilter = 'All';
  String _selectedSort = 'Name';
  
  final List<String> _filterOptions = ['All', 'Marketing', 'Utility', 'Authentication', 'General', 'Greeting', 'Business', 'Support', 'Promotion', 'Reminder'];
  final List<String> _sortOptions = ['Name', 'Date Created', 'Usage Count', 'Category'];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _templateService.getTemplates(),
        _templateService.getFavoriteTemplates(),
        _templateService.getRecentTemplates(),
      ]);

      if (mounted) {
        setState(() {
          templates = results[0];
          favoriteTemplates = results[1];
          recentTemplates = results[2];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load templates: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeDuplicates() async {
    setState(() => _isLoading = true);
    
    try {
      await _templateService.removeDuplicateTemplates();
      await _loadTemplates(); // Reload after cleanup
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Duplicate templates removed successfully!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing duplicates: $e', style: const TextStyle(color: Colors.black)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _darkBg,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Message Templates', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black.withValues(alpha: 0.7),
          elevation: 0,
          iconTheme: const IconThemeData(color: _ancientGold),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: _ancientGold),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _darkBg,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Message Templates', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black.withValues(alpha: 0.7),
          elevation: 0,
          iconTheme: const IconThemeData(color: _ancientGold),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.redAccent.withValues(alpha: 0.8)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ancientGold,
                  foregroundColor: Colors.black,
                ),
                onPressed: _loadTemplates,
                child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Message Templates', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
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
            onPressed: _showTemplateVariablesHelp,
            tooltip: 'Template Variables Help',
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: _ancientGold),
            onPressed: _removeDuplicates,
            tooltip: 'Remove Duplicates',
          ),
          IconButton(
            icon: const Icon(Icons.import_export, color: _ancientGold),
            onPressed: _showImportExportDialog,
            tooltip: 'Import/Export',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: _ancientGold),
            onPressed: () => _showTemplateDialog(),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // The Shared Cinematic Nebula Background
            const Positioned.fill(child: AnimatedNebulaBackground()),
            
            RefreshIndicator(
              color: Colors.black,
              backgroundColor: _ancientGold,
              onRefresh: _loadTemplates,
              child: templates.isEmpty ? _buildEmptyState() : _buildTemplatesList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTemplateDialog(),
        backgroundColor: _ancientGold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                Icons.text_snippet_outlined,
                size: 80,
                color: _ancientGold.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Templates Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _ancientGold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create your first message template\nto get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _showTemplateDialog(),
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Create Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _ancientGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesList() {
    List<Map<String, dynamic>> filteredTemplates = _getFilteredAndSortedTemplates();
    
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature 1: Search and Filter Bar
          _buildSearchAndFilterBar(),
          const SizedBox(height: 24),
          
          // Feature 6: Quick Access Sections
          if (favoriteTemplates.isNotEmpty) ...[
            _buildSectionHeader('⭐ Favorites', favoriteTemplates.length),
            const SizedBox(height: 12),
            _buildTemplateList(favoriteTemplates.take(2).toList()),
            const SizedBox(height: 24),
          ],
          
          if (recentTemplates.isNotEmpty) ...[
            _buildSectionHeader('🕒 Recent', recentTemplates.length),
            const SizedBox(height: 12),
            _buildTemplateList(recentTemplates.take(3).toList()),
            const SizedBox(height: 24),
          ],
          
          // All Templates
          _buildSectionHeader('📝 All Templates', filteredTemplates.length),
          const SizedBox(height: 12),
          
          if (filteredTemplates.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No templates match your search',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ),
            )
          else
            _buildTemplateList(filteredTemplates),
        ],
      ),
    );
  }

  // Feature 1: Search & Filter System
  Widget _buildSearchAndFilterBar() {
    return Column(
      children: [
        // Search Bar
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search templates...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: const Icon(Icons.search, color: _ancientGold),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.5),
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
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        const SizedBox(height: 16),
        
        // Filter and Sort Row
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                dropdownColor: Colors.black,
                icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
                style: const TextStyle(color: Colors.white),
                initialValue: _selectedFilter,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.5),
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
                    borderSide: const BorderSide(color: _ancientGold),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _filterOptions.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                dropdownColor: Colors.black,
                icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
                style: const TextStyle(color: Colors.white),
                initialValue: _selectedSort,
                decoration: InputDecoration(
                  labelText: 'Sort by',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.5),
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
                    borderSide: const BorderSide(color: _ancientGold),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _sortOptions.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSort = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Feature 6: Advanced Organization
  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _ancientGold.withValues(alpha: 0.15),
            border: Border.all(color: _ancientGold.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 12,
              color: _ancientGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateList(List<Map<String, dynamic>> templateList) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: templateList.length,
      itemBuilder: (context, index) {
        return _buildTemplateCard(templateList[index], index);
      },
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template, int index) {
    bool isFavorite = template['is_favorite'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () => _useTemplate(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(template['category'] ?? 'General').withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: _getCategoryColor(template['category'] ?? 'General').withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      _getTemplateIcon(template['category'] ?? 'General'),
                      color: _getCategoryColor(template['category'] ?? 'General'),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      template['name'] ?? 'Untitled Template',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.redAccent : Colors.white54,
                    ),
                    onPressed: () => _toggleFavorite(template),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      cardColor: Colors.black,
                      iconTheme: const IconThemeData(color: _ancientGold),
                    ),
                    child: PopupMenuButton(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: _ancientGold.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.white70, size: 20),
                              SizedBox(width: 12),
                              Text('Edit', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, color: Colors.white70, size: 20),
                              SizedBox(width: 12),
                              Text('Duplicate', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.redAccent, size: 20),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _showTemplateDialog(template: template, index: index);
                            break;
                          case 'duplicate':
                            _duplicateTemplate(template);
                            break;
                          case 'delete':
                            _deleteTemplate(index);
                            break;
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                template['message'] ?? 'No content',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[400], height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(template['category'] ?? 'General').withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getCategoryColor(template['category'] ?? 'General').withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      template['category'] ?? 'General',
                      style: TextStyle(
                        fontSize: 11,
                        color: _getCategoryColor(template['category'] ?? 'General'),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Used ${template['usage_count'] ?? 0} times',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Filtering and Sorting Logic
  List<Map<String, dynamic>> _getFilteredAndSortedTemplates() {
    List<Map<String, dynamic>> filtered = templates;
    
    if (_selectedFilter != 'All') {
      filtered = filtered.where((template) => template['category'] == _selectedFilter).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((template) {
        return template['name'].toLowerCase().contains(_searchQuery) ||
               template['message'].toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'Name':
          return a['name'].compareTo(b['name']);
        case 'Usage Count':
          return (b['usageCount'] ?? 0).compareTo(a['usageCount'] ?? 0);
        case 'Category':
          return a['category'].compareTo(b['category']);
        default:
          return 0;
      }
    });
    
    return filtered;
  }

  void _toggleFavorite(Map<String, dynamic> template) async {
    final templateId = template['id'].toString();
    final isFavorite = template['is_favorite'] ?? false;
    
    await _templateService.toggleFavorite(templateId, isFavorite);
    _loadTemplates(); // Refresh the data
  }

  void _duplicateTemplate(Map<String, dynamic> template) async {
    Map<String, dynamic> duplicated = Map.from(template);
    duplicated.remove('id');
    duplicated.remove('created_at');
    duplicated.remove('updated_at');
    duplicated['name'] = '${template['name']} (Copy)';
    duplicated['usage_count'] = 0;
    duplicated['is_favorite'] = false;
    
    final result = await _templateService.createTemplate(duplicated);
    
    if (result != null) {
      _loadTemplates(); // Refresh the data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template "${template['name']}" duplicated', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to duplicate template', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _useTemplate(Map<String, dynamic> template) async {
    final templateId = template['id'].toString();
    
    // Increment usage count and update last used
    await Future.wait([
      _templateService.incrementUsageCount(templateId),
      _templateService.updateLastUsed(templateId),
    ]);
    
    String processedMessage = _processTemplateVariables(template['message'] ?? '');
    Clipboard.setData(ClipboardData(text: processedMessage));
    
    // Refresh data to update usage count
    _loadTemplates();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template "${template['name']}" copied to clipboard', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: _ancientGold,
        ),
      );
    }
  }

  String _processTemplateVariables(String message) {
    final user = Supabase.instance.client.auth.currentUser;
    
    // Extract user information
    final userName = user?.userMetadata?['full_name'] ?? 
                    user?.userMetadata?['name'] ?? 
                    user?.email?.split('@')[0] ?? 
                    'User';
    
    final userEmail = user?.email ?? 'user@example.com';
    final userPhone = user?.userMetadata?['phone'] ?? user?.phone ?? '+1234567890';
    
    // Current date and time
    final now = DateTime.now();
    final currentDate = '${now.day}/${now.month}/${now.year}';
    final currentTime = TimeOfDay.now().format(context);
    
    return message
        .replaceAll('{{name}}', userName)
        .replaceAll('{{company}}', 'Meta Fly')
        .replaceAll('{{date}}', currentDate)
        .replaceAll('{{time}}', currentTime)
        .replaceAll('{{phone}}', userPhone)
        .replaceAll('{{email}}', userEmail)
        // Support numbered variables for WhatsApp Business API
        .replaceAll('{{1}}', userName)
        .replaceAll('{{2}}', 'Meta Fly')
        .replaceAll('{{3}}', currentDate);
  }

  void _showTemplateVariablesHelp() {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 
                    user?.userMetadata?['name'] ?? 
                    user?.email?.split('@')[0] ?? 
                    'User';
    final userEmail = user?.email ?? 'user@example.com';
    
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
            Icon(Icons.edit_note, color: _ancientGold),
            SizedBox(width: 10),
            Text('Template Variables', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Use these variables in your templates:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            _buildVariableRow('{{name}}', 'Your name', userName),
            _buildVariableRow('{{company}}', 'Company name', 'Meta Fly'),
            _buildVariableRow('{{date}}', 'Current date', '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
            _buildVariableRow('{{time}}', 'Current time', TimeOfDay.now().format(context)),
            _buildVariableRow('{{phone}}', 'Your phone', user?.phone ?? '+1234567890'),
            _buildVariableRow('{{email}}', 'Your email', userEmail),
            const SizedBox(height: 12),
            Divider(color: _ancientGold.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('WhatsApp Business API Variables:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
            const SizedBox(height: 12),
            _buildVariableRow('{{1}}', 'First parameter', userName),
            _buildVariableRow('{{2}}', 'Second parameter', 'Meta Fly'),
            _buildVariableRow('{{3}}', 'Third parameter', 'Current date'),
            const SizedBox(height: 16),
            const Text('Example:', style: TextStyle(fontWeight: FontWeight.bold, color: _ancientGold)),
            const SizedBox(height: 8),
            Text(
              '"Hello {{name}}, welcome to {{company}}! Today is {{date}}."',
              style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
            ),
          ],
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

  Widget _buildVariableRow(String variable, String description, String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _ancientGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                variable,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _ancientGold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$description → $example',
              style: TextStyle(fontSize: 12, color: Colors.grey[300]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showImportExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('📁 Import/Export Templates', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload, color: Colors.blueAccent),
              title: const Text('Import Templates', style: TextStyle(color: Colors.white)),
              subtitle: Text('Import from JSON file', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📥 Import feature coming soon!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    backgroundColor: _ancientGold,
                  ),
                );
              },
            ),
            Divider(color: _ancientGold.withValues(alpha: 0.2)),
            ListTile(
              leading: const Icon(Icons.file_download, color: Colors.greenAccent),
              title: const Text('Export Templates', style: TextStyle(color: Colors.white)),
              subtitle: Text('Export to JSON file', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📤 Export feature coming soon!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    backgroundColor: _ancientGold,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  void _showTemplateDialog({Map<String, dynamic>? template, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTemplateScreen(template: template),
      ),
    );
    
    if (result != null) {
      if (template != null) {
        // Update existing template
        final templateId = template['id'].toString();
        await _templateService.updateTemplate(templateId, result);
      } else {
        // Create new template
        await _templateService.createTemplate(result);
      }
      
      // Refresh the templates
      _loadTemplates();
    }
  }

  void _deleteTemplate(int index) async {
    Map<String, dynamic> template = templates[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: _ancientGold, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Template', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${template['name']}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final templateId = template['id'].toString();
      final success = await _templateService.deleteTemplate(templateId);
      
      if (success) {
        _loadTemplates(); // Refresh the data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Template "${template['name']}" deleted', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: _ancientGold,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete template', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  IconData _getTemplateIcon(String category) {
    switch (category) {
      case 'Marketing': return Icons.campaign;
      case 'Utility': return Icons.build;
      case 'Authentication': return Icons.security;
      case 'General': return Icons.text_snippet;
      case 'Greeting': return Icons.waving_hand;
      case 'Business': return Icons.business;
      case 'Support': return Icons.support_agent;
      case 'Promotion': return Icons.local_offer;
      case 'Reminder': return Icons.alarm;
      default: return Icons.text_snippet;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Marketing': return Colors.redAccent;
      case 'Utility': return Colors.blueAccent;
      case 'Authentication': return Colors.greenAccent;
      case 'General': return Colors.grey[400]!;
      case 'Greeting': return Colors.amberAccent;
      case 'Business': return Colors.purpleAccent;
      case 'Support': return Colors.orangeAccent;
      case 'Promotion': return Colors.pinkAccent;
      case 'Reminder': return Colors.tealAccent;
      default: return Colors.grey[400]!;
    }
  }
}