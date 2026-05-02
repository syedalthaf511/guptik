import 'package:flutter/material.dart';
import 'package:guptik/widgets/home/animated_nebula_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class CreateTemplateScreen extends StatefulWidget {
  final Map<String, dynamic>? template;

  const CreateTemplateScreen({super.key, this.template});

  @override
  State<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _headerController;
  late TextEditingController _bodyController;
  late TextEditingController _footerController;
  
  // Form values
  String _selectedCategory = 'Marketing';
  String _selectedLanguage = 'English';
  String _selectedTemplateType = 'Custom';
  String _selectedHeaderType = 'None';
  final String _status = 'DRAFT';
  
  // Button-related state
  bool _showButtonOptions = false;
  String _selectedButtonType = 'Quick Reply';
  List<Map<String, String>> _quickReplyButtons = [];
  List<Map<String, String>> _callToActionButtons = [];
  
  // Categories with descriptions
  final Map<String, Map<String, String>> _categories = {
    'Marketing': {
      'title': 'Marketing',
      'description': 'One-to-many bulk broadcast marketing messages',
      'icon': '📢'
    },
    'Utility': {
      'title': 'Utility',
      'description': 'Transactional messages that are sent on some user action',
      'icon': '⚙️'
    },
    'Authentication': {
      'title': 'Authentication',
      'description': 'One time password messages for authentication',
      'icon': '🔐'
    },
  };
  
  final List<String> _languages = [
    'English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese', 'Arabic', 'Hindi'
  ];
  
  final List<String> _templateTypes = [
    'Custom', 'Standard', 'Quick Reply', 'Call to Action'
  ];
  
  final List<String> _headerTypes = [
    'None', 'Text', 'Image', 'Video', 'Document'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _headerController = TextEditingController();
    _bodyController = TextEditingController();
    _footerController = TextEditingController(text: 'Sent via MetaFly.com');
    
    if (widget.template != null) {
      _nameController.text = widget.template!['name'] ?? '';
      _bodyController.text = widget.template!['message'] ?? '';
      _selectedCategory = widget.template!['category'] ?? 'Marketing';
      
      // Load existing buttons if they exist
      if (widget.template!['buttons'] != null) {
        final buttonData = widget.template!['buttons'] as Map<String, dynamic>;
        _showButtonOptions = true;
        _selectedButtonType = buttonData['type'] == 'quick_reply' ? 'Quick Reply' : 'Call To Action';
        
        if (buttonData['type'] == 'quick_reply') {
          _quickReplyButtons = List<Map<String, String>>.from(
            (buttonData['buttons'] as List).map((button) => Map<String, String>.from(button))
          );
        } else if (buttonData['type'] == 'call_to_action') {
          _callToActionButtons = List<Map<String, String>>.from(
            (buttonData['buttons'] as List).map((button) => Map<String, String>.from(button))
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headerController.dispose();
    _bodyController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.template == null ? 'Add Message Template' : 'Edit Message Template',
          style: const TextStyle(color: _ancientGold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: _ancientGold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _ancientGold.withValues(alpha: 0.2), height: 1.0),
        ),
      ),
      // THE FIX: Full screen container ensures the background stretches to cover all scrollable area
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // The Shared Cinematic Nebula Background
            const Positioned.fill(child: AnimatedNebulaBackground()),
            
            LayoutBuilder(
              builder: (context, constraints) {
                // Use single column layout for mobile devices (width < 800)
                if (constraints.maxWidth < 800) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 100, 16, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormContainer(_buildTemplateNameSection()),
                          const SizedBox(height: 24),
                          _buildFormContainer(_buildCategorySection()),
                          const SizedBox(height: 24),
                          _buildFormContainer(_buildLanguageAndTypeSection()),
                          const SizedBox(height: 24),
                          _buildFormContainer(_buildHeaderSection()),
                          const SizedBox(height: 24),
                          _buildFormContainer(_buildBodySection()),
                          const SizedBox(height: 24),
                          _buildFormContainer(_buildFooterSection()),
                          const SizedBox(height: 24),
                          _buildFormContainer(_buildButtonSection()),
                          const SizedBox(height: 24),
                          _buildFormContainer(_buildActionsSection()),
                          const SizedBox(height: 24),
                          _buildFormContainer(_buildPreviewSection()),
                          const SizedBox(height: 100), // Extra space for bottom
                        ],
                      ),
                    ),
                  );
                }
                
                // Use side-by-side layout for larger screens
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Form
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 100, 24, 40),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormContainer(_buildTemplateNameSection()),
                              const SizedBox(height: 24),
                              _buildFormContainer(_buildCategorySection()),
                              const SizedBox(height: 24),
                              _buildFormContainer(_buildLanguageAndTypeSection()),
                              const SizedBox(height: 24),
                              _buildFormContainer(_buildHeaderSection()),
                              const SizedBox(height: 24),
                              _buildFormContainer(_buildBodySection()),
                              const SizedBox(height: 24),
                              _buildFormContainer(_buildFooterSection()),
                              const SizedBox(height: 24),
                              _buildFormContainer(_buildButtonSection()),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Sidebar - Actions and Preview
                    Container(
                      width: 400,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        border: Border(left: BorderSide(color: _ancientGold.withValues(alpha: 0.3))),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80.0), // Account for app bar
                        child: Column(
                          children: [
                            _buildActionsSection(),
                            Divider(height: 1, color: _ancientGold.withValues(alpha: 0.3)),
                            Expanded(child: _buildPreviewSection()),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Wrapper for all form sections to give them the glassmorphism look
  Widget _buildFormContainer(Widget child) {
    return Container(
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
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    String? labelText,
    int maxLines = 1,
    int? maxLength,
    Widget? suffixIcon,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
    Widget? Function(BuildContext, {required int currentLength, required bool isFocused, int? maxLength})? buildCounter,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        hintStyle: TextStyle(color: Colors.grey[600]),
        labelStyle: TextStyle(color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
        suffixIcon: suffixIcon,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onChanged: onChanged,
      validator: validator,
      buildCounter: buildCounter,
    );
  }

  Widget _buildDropdown<T>({
    required T initialValue,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      dropdownColor: Colors.black,
      icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
      style: const TextStyle(color: Colors.white),
      initialValue: initialValue,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.4),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildTemplateNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'TEMPLATE NAME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _ancientGold,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              '${_nameController.text.length} / 512',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _nameController,
          hintText: 'Enter template name',
          onChanged: (value) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Template name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Spaces and special characters are not allowed.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CATEGORY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _ancientGold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Determine if we should stack or row based on space
            if (constraints.maxWidth < 600) {
              return Column(
                children: _categories.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCategoryCard(entry),
                  );
                }).toList(),
              );
            }
            return Row(
              children: _categories.entries.map((entry) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildCategoryCard(entry),
                  ),
                );
              }).toList(),
            );
          }
        ),
        const SizedBox(height: 8),
        Text(
          'Select template category',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(MapEntry<String, Map<String, String>> entry) {
    final isSelected = _selectedCategory == entry.key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = entry.key),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? _ancientGold : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? _ancientGold.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isSelected) 
                  const Icon(Icons.radio_button_checked, color: _ancientGold, size: 18)
                else 
                  Icon(Icons.radio_button_unchecked, color: Colors.grey[500], size: 18),
                const SizedBox(width: 8),
                Text(entry.value['icon']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.value['title']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? _ancientGold : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.value['description']!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[400],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageAndTypeSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildLanguageSelector(),
              const SizedBox(height: 24),
              _buildTypeSelector(),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _buildLanguageSelector()),
            const SizedBox(width: 24),
            Expanded(child: _buildTypeSelector()),
          ],
        );
      }
    );
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LANGUAGE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _ancientGold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _buildDropdown<String>(
          initialValue: _selectedLanguage,
          items: _languages.map((language) {
            return DropdownMenuItem(value: language, child: Text(language));
          }).toList(),
          onChanged: (value) => setState(() => _selectedLanguage = value!),
        ),
        const SizedBox(height: 8),
        Text(
          'Select template language',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TEMPLATE TYPE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _ancientGold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _buildDropdown<String>(
          initialValue: _selectedTemplateType,
          items: _templateTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) => setState(() => _selectedTemplateType = value!),
        ),
        const SizedBox(height: 8),
        Text(
          'Select template type',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Header (Optional)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Add a title that you want to show in message header.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        const Text(
          'HEADER TYPE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _ancientGold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        _buildDropdown<String>(
          initialValue: _selectedHeaderType,
          items: _headerTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) => setState(() => _selectedHeaderType = value!),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the header type.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        if (_selectedHeaderType == 'Text') ...[
          const SizedBox(height: 20),
          _buildTextField(
            controller: _headerController,
            labelText: 'Header Text',
          ),
        ],
      ],
    );
  }

  Widget _buildBodySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Body',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the text for your message in the language you\'ve selected.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text(
              'BODY CONTENT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _ancientGold,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              '${_bodyController.text.length} / 1024',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _bodyController,
          maxLines: 6,
          suffixIcon: Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: _ancientGold),
              onPressed: _showVariableOptions,
              tooltip: 'Add Variables',
            ),
          ),
          onChanged: (value) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Body content is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Enter body content. HTML not allowed. You can format the text using following shorthands:',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 16),
        _buildFormattingHelp(),
      ],
    );
  }

  Widget _buildFormattingHelp() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ancientGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormatExample('Bold:', '*text* will become ', 'text', FontWeight.bold),
          const SizedBox(height: 8),
          _buildFormatExample('Italics:', '_text_ will become ', 'text', FontWeight.normal, isItalic: true),
          const SizedBox(height: 8),
          _buildFormatExample('Strikethrough:', '~text~ will become ', 'text', FontWeight.normal, isStrikethrough: true),
          const SizedBox(height: 8),
          _buildFormatExample('Monospace:', '```text``` will become ', 'text', FontWeight.normal, isMonospace: true),
        ],
      ),
    );
  }

  Widget _buildFormatExample(String label, String prefix, String text, FontWeight weight, {bool isItalic = false, bool isStrikethrough = false, bool isMonospace = false}) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[400], fontWeight: FontWeight.bold)),
        ),
        Text(prefix, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: _ancientGold,
            fontWeight: weight,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isStrikethrough ? TextDecoration.lineThrough : TextDecoration.none,
            decorationColor: _ancientGold,
            fontFamily: isMonospace ? 'monospace' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Footer (Optional)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Add a short line of text to the bottom of your message template.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text(
              'FOOTER TEXT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _ancientGold,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              '${_footerController.text.length} / 60',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _footerController,
          maxLength: 60,
          onChanged: (value) => setState(() {}),
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter footer text.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildButtonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Button (Optional)',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Create buttons that let customers respond to your message or take action.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            setState(() {
              _showButtonOptions = !_showButtonOptions;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: _showButtonOptions ? _ancientGold : Colors.white24),
              borderRadius: BorderRadius.circular(12),
              color: _showButtonOptions ? _ancientGold.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.4),
            ),
            child: Row(
              children: [
                Icon(
                  _showButtonOptions ? Icons.remove_circle_outline : Icons.add_circle_outline,
                  color: _ancientGold,
                ),
                const SizedBox(width: 12),
                Text(
                  'Add a button',
                  style: TextStyle(color: _showButtonOptions ? _ancientGold : Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Icon(
                  _showButtonOptions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
        if (_showButtonOptions) ...[
          const SizedBox(height: 24),
          _buildButtonTypeSelector(),
          const SizedBox(height: 24),
          _buildButtonConfiguration(),
        ],
      ],
    );
  }

  Widget _buildButtonTypeSelector() {
    final buttonTypes = [
      {
        'type': 'Quick Reply',
        'description': 'Custom (Max 10)',
        'icon': Icons.reply,
        'color': Colors.blueAccent,
      },
      {
        'type': 'Call To Action',
        'description': 'Website, Phone & Offer buttons',
        'icon': Icons.touch_app,
        'color': Colors.greenAccent,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Button Type',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        ...buttonTypes.map((buttonType) => GestureDetector(
          onTap: () {
            setState(() {
              _selectedButtonType = buttonType['type'] as String;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedButtonType == buttonType['type']
                    ? buttonType['color'] as Color
                    : Colors.white24,
                width: _selectedButtonType == buttonType['type'] ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _selectedButtonType == buttonType['type']
                  ? (buttonType['color'] as Color).withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.4),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (buttonType['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: (buttonType['color'] as Color).withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    buttonType['icon'] as IconData,
                    color: buttonType['color'] as Color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buttonType['type'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        buttonType['description'] as String,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                if (_selectedButtonType == buttonType['type'])
                  Icon(
                    Icons.check_circle,
                    color: buttonType['color'] as Color,
                    size: 28,
                  ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildButtonConfiguration() {
    if (_selectedButtonType == 'Quick Reply') {
      return _buildQuickReplyButtons();
    } else {
      return _buildCallToActionButtons();
    }
  }

  Widget _buildQuickReplyButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Reply Buttons',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${_quickReplyButtons.length}/10',
              style: TextStyle(
                color: _quickReplyButtons.length >= 10 ? Colors.redAccent : Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._quickReplyButtons.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, String> button = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(color: _ancientGold.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: button['text'],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Button text (max 20 characters)',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    maxLength: 20,
                    onChanged: (value) {
                      setState(() {
                        _quickReplyButtons[index]['text'] = value;
                      });
                    },
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _quickReplyButtons.removeAt(index);
                    });
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ],
            ),
          );
        }),
        if (_quickReplyButtons.length < 10)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _quickReplyButtons.add({'text': '', 'id': 'quick_reply_${_quickReplyButtons.length + 1}'});
                });
              },
              icon: const Icon(Icons.add, color: _ancientGold),
              label: const Text('Add Quick Reply Button', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: _ancientGold.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _ancientGold.withValues(alpha: 0.3))),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCallToActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Call to Action Buttons',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        
        // Visit Website buttons
        _buildCallToActionSection(
          'Visit Website',
          'website',
          Icons.language,
          Colors.blueAccent,
          2,
          'Website URL',
          'https://example.com',
        ),
        
        const SizedBox(height: 24),
        
        // Call Phone buttons
        _buildCallToActionSection(
          'Call Phone Number',
          'phone',
          Icons.phone,
          Colors.greenAccent,
          1,
          'Phone Number',
          '+1234567890',
        ),
        
        const SizedBox(height: 24),
        
        // Copy Offer Code buttons
        _buildCallToActionSection(
          'Copy Offer Code',
          'copy',
          Icons.content_copy,
          Colors.orangeAccent,
          1,
          'Offer Code',
          'SAVE20',
        ),
      ],
    );
  }

  Widget _buildCallToActionSection(
    String title,
    String type,
    IconData icon,
    Color color,
    int maxCount,
    String hintText,
    String placeholderValue,
  ) {
    List<Map<String, String>> buttons = _callToActionButtons
        .where((button) => button['type'] == type)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '(Max $maxCount)',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: buttons.length >= maxCount ? Colors.redAccent.withValues(alpha: 0.2) : Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${buttons.length}/$maxCount',
                style: TextStyle(
                  color: buttons.length >= maxCount ? Colors.redAccent : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...buttons.asMap().entries.map((entry) {
          Map<String, String> button = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: button['text'],
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Button text (max 20 chars)',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        maxLength: 20,
                        onChanged: (value) {
                          setState(() {
                            int originalIndex = _callToActionButtons.indexWhere(
                              (b) => b['id'] == button['id'],
                            );
                            if (originalIndex != -1) {
                              _callToActionButtons[originalIndex]['text'] = value;
                            }
                          });
                        },
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _callToActionButtons.removeWhere((b) => b['id'] == button['id']);
                        });
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Divider(color: color.withValues(alpha: 0.2), height: 16),
                TextFormField(
                  initialValue: button['value'],
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(color: Colors.grey[600], fontFamily: 'sans-serif'),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      int originalIndex = _callToActionButtons.indexWhere(
                        (b) => b['id'] == button['id'],
                      );
                      if (originalIndex != -1) {
                        _callToActionButtons[originalIndex]['value'] = value;
                      }
                    });
                  },
                ),
              ],
            ),
          );
        }),
        if (buttons.length < maxCount)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _callToActionButtons.add({
                    'text': '',
                    'value': '',
                    'type': type,
                    'id': '${type}_${DateTime.now().millisecondsSinceEpoch}',
                  });
                });
              },
              icon: Icon(Icons.add, color: color),
              label: Text('Add $title', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: color.withValues(alpha: 0.3))),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Status:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                debugPrint('Submit button tapped!');
                debugPrint('Template name: "${_nameController.text}"');
                debugPrint('Body text: "${_bodyController.text}"');
                debugPrint('Form valid: ${_formKey.currentState?.validate()}');
                _submitTemplate();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _ancientGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
              child: const Text(
                'Submit for Approval',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Template Preview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              // WhatsApp Web Dark Mode Chat Background Color
              color: const Color(0xFF0B141A), 
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
              image: DecorationImage(
                // Simulating WhatsApp Chat Background Pattern
                image: const NetworkImage('https://i.ibb.co/3s1f9b0/wa-bg.png'), 
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.8), BlendMode.dstATop),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview message bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF202C33), // WhatsApp Dark Mode Bubble Color
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                      bottomLeft: Radius.circular(0), // Chat tail
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedHeaderType != 'None' && _headerController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _headerController.text,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                          ),
                        ),
                      Text(
                        _bodyController.text.isEmpty ? 'Body text here' : _bodyController.text,
                        style: TextStyle(
                          color: _bodyController.text.isEmpty ? Colors.grey[500] : Colors.white,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                      if (_footerController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _footerController.text,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      // Show button previews
                      if (_showButtonOptions && (_quickReplyButtons.isNotEmpty || _callToActionButtons.isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildButtonPreviews(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF182229),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Sent via MetaFly.com',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonPreviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.grey[800], height: 16),
        if (_selectedButtonType == 'Quick Reply' && _quickReplyButtons.isNotEmpty) ...[
          const SizedBox(height: 4),
          ..._quickReplyButtons.where((button) => button['text']!.isNotEmpty).map((button) => 
            Container(
              width: double.infinity, // WhatsApp buttons span full width
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[800]!),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF2A3942), // WhatsApp button color
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.reply, size: 16, color: Color(0xFF00A884)), // WhatsApp blue/green
                  const SizedBox(width: 8),
                  Text(
                    button['text']!,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF00A884), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_selectedButtonType == 'Call To Action' && _callToActionButtons.isNotEmpty) ...[
          const SizedBox(height: 4),
          ..._callToActionButtons.where((button) => button['text']!.isNotEmpty).map((button) {
            IconData icon;
            switch (button['type']) {
              case 'website':
                icon = Icons.open_in_new;
                break;
              case 'phone':
                icon = Icons.phone;
                break;
              case 'copy':
                icon = Icons.content_copy;
                break;
              default:
                icon = Icons.touch_app;
            }
            
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[800]!),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF2A3942),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: const Color(0xFF00A884)),
                  const SizedBox(width: 8),
                  Text(
                    button['text']!,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF00A884), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  void _showVariableOptions() {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['full_name'] ?? 
                    user?.userMetadata?['name'] ?? 
                    user?.email?.split('@')[0] ?? 
                    'User';
    
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
            Icon(Icons.add_circle_outline, color: _ancientGold),
            SizedBox(width: 10),
            Text('Add Variables', style: TextStyle(color: _ancientGold, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('WhatsApp Business API Variables:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            const SizedBox(height: 12),
            _buildVariableOption('{{1}}', 'First parameter ($userName)'),
            _buildVariableOption('{{2}}', 'Second parameter (Meta Fly)'),
            _buildVariableOption('{{3}}', 'Third parameter (Current date)'),
            const SizedBox(height: 12),
            Divider(color: _ancientGold.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('Named Variables:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
            const SizedBox(height: 12),
            _buildVariableOption('{{name}}', 'User name ($userName)'),
            _buildVariableOption('{{company}}', 'Company name (Meta Fly)'),
            _buildVariableOption('{{date}}', 'Current date'),
            _buildVariableOption('{{time}}', 'Current time'),
            _buildVariableOption('{{phone}}', 'User phone'),
            _buildVariableOption('{{email}}', 'User email'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _buildVariableOption(String variable, String description) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      visualDensity: VisualDensity.compact,
      title: Text(variable, style: const TextStyle(color: _ancientGold, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
      subtitle: Text(description, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      onTap: () {
        final currentText = _bodyController.text;
        final currentPosition = _bodyController.selection.start;
        final newText = currentText.substring(0, currentPosition) + 
                       variable + 
                       currentText.substring(currentPosition);
        _bodyController.text = newText;
        _bodyController.selection = TextSelection.fromPosition(
          TextPosition(offset: currentPosition + variable.length),
        );
        Navigator.pop(context);
        setState(() {});
      },
    );
  }

  void _submitTemplate() {
    debugPrint('_submitTemplate called');
    
    if (_formKey.currentState!.validate()) {
      debugPrint('Form validation passed');
      
      // Prepare button data
      Map<String, dynamic> buttonData = {};
      
      if (_showButtonOptions) {
        if (_selectedButtonType == 'Quick Reply' && _quickReplyButtons.isNotEmpty) {
          buttonData['type'] = 'quick_reply';
          buttonData['buttons'] = _quickReplyButtons
              .where((button) => button['text']!.isNotEmpty)
              .toList();
        } else if (_selectedButtonType == 'Call To Action' && _callToActionButtons.isNotEmpty) {
          buttonData['type'] = 'call_to_action';
          buttonData['buttons'] = _callToActionButtons
              .where((button) => button['text']!.isNotEmpty && button['value']!.isNotEmpty)
              .toList();
        }
      }
      
      // Create template data
      Map<String, dynamic> templateData = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'language': _selectedLanguage,
        'type': _selectedTemplateType,
        'headerType': _selectedHeaderType,
        'header': _headerController.text.trim(),
        'message': _bodyController.text.trim(),
        'footer': _footerController.text.trim(),
        'status': _status,
        'createdAt': DateTime.now().toIso8601String(),
        'usageCount': 0,
        'buttons': buttonData.isNotEmpty ? buttonData : null,
      };

      debugPrint('Template data prepared: $templateData');

      // Return the template data
      Navigator.pop(context, templateData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template submitted for approval successfully!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.greenAccent,
        ),
      );
    } else {
      debugPrint('Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields (Template Name and Body Content)', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}