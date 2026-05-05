import 'package:flutter/material.dart';
import 'package:guptik/utils/theme/dynamic_app_background.dart';

// Ancient Gold Theme Constants
const Color _ancientGold = Color(0xFFD4AF37);
const Color _darkBg = Color(0xFF0A0A0A);

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedCategory = 'General';
  String _selectedPriority = 'Medium';

  final List<String> _categories = [
    'General',
    'Technical Issue',
    'Billing',
    'Feature Request',
    'Integration',
    'API',
    'Account',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'How do I connect my WhatsApp Business account?',
      'answer': 'Go to Settings > API Settings, enter your WhatsApp Business API credentials, and click Connect. Make sure your account is verified.',
    },
    {
      'question': 'Why are my messages not being delivered?',
      'answer': 'Check your account status, ensure templates are approved, verify recipient numbers are valid, and confirm you haven\'t exceeded daily limits.',
    },
    {
      'question': 'How do I create message templates?',
      'answer': 'Navigate to Content Library > Message Templates > Add New. Create your template and submit for WhatsApp approval.',
    },
    {
      'question': 'What are the messaging limits?',
      'answer': 'Limits depend on your tier (Tier 1: 1K, Tier 2: 10K, Tier 3: 100K messages/day). Quality rating affects your tier.',
    },
    {
      'question': 'How do I upgrade my subscription?',
      'answer': 'Go to Settings > Subscriptions, select your desired plan, and follow the payment process.',
    },
    {
      'question': 'Can I integrate with my CRM?',
      'answer': 'Yes! Visit Integrations to connect with popular CRMs like HubSpot, Salesforce, and others.',
    },
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Support Center',
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
      // THE FIX: Wrap the body in an expanding Container so the background covers all scrolling
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // The Shared Cinematic Nebula Background
            const Positioned.fill(child: DynamicAppBackground()),
            
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'How can we help you?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _ancientGold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get help with your WhatsApp Business automation. Check our FAQ or contact our support team.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          'Live Chat',
                          'Chat with our support team',
                          Icons.chat,
                          Colors.greenAccent,
                          () => _startLiveChat(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickActionCard(
                          'Call Support',
                          'Speak with an expert',
                          Icons.phone,
                          Colors.blueAccent,
                          () => _callSupport(),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          'Documentation',
                          'Browse our guides',
                          Icons.book,
                          Colors.purpleAccent,
                          () => _openDocumentation(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickActionCard(
                          'Video Tutorials',
                          'Watch how-to videos',
                          Icons.play_circle,
                          Colors.redAccent,
                          () => _openTutorials(),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Contact Form
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Send us a Message',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _ancientGold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Category and Priority
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  dropdownColor: Colors.black,
                                  style: const TextStyle(color: Colors.white),
                                  icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
                                  initialValue: _selectedCategory,
                                  decoration: InputDecoration(
                                    labelText: 'Category',
                                    labelStyle: TextStyle(color: Colors.grey[500]),
                                    filled: true,
                                    fillColor: Colors.black.withValues(alpha: 0.3),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: _ancientGold),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: _categories.map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  )).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedCategory = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  dropdownColor: Colors.black,
                                  style: const TextStyle(color: Colors.white),
                                  icon: const Icon(Icons.arrow_drop_down, color: _ancientGold),
                                  initialValue: _selectedPriority,
                                  decoration: InputDecoration(
                                    labelText: 'Priority',
                                    labelStyle: TextStyle(color: Colors.grey[500]),
                                    filled: true,
                                    fillColor: Colors.black.withValues(alpha: 0.3),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: _ancientGold),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: _priorities.map((priority) => DropdownMenuItem(
                                    value: priority,
                                    child: Text(priority),
                                  )).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedPriority = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Subject
                          TextFormField(
                            controller: _subjectController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Subject',
                              labelStyle: TextStyle(color: Colors.grey[500]),
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.3),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: _ancientGold),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Message
                          TextFormField(
                            controller: _messageController,
                            maxLines: 5,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Message',
                              labelStyle: TextStyle(color: Colors.grey[500]),
                              alignLabelWithHint: true,
                              filled: true,
                              fillColor: Colors.black.withValues(alpha: 0.3),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: _ancientGold.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: _ancientGold),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitMessage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _ancientGold,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Send Message',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // FAQ Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Frequently Asked Questions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _ancientGold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _faqItems.length,
                            itemBuilder: (context, index) {
                              return _buildFAQItem(_faqItems[index]);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Contact Info
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _ancientGold.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contact Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _ancientGold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildContactInfo(Icons.email, 'Email', 'support@metafly.com'),
                          Divider(color: _ancientGold.withValues(alpha: 0.2), height: 24),
                          _buildContactInfo(Icons.phone, 'Phone', '+1 (555) 123-4567'),
                          Divider(color: _ancientGold.withValues(alpha: 0.2), height: 24),
                          _buildContactInfo(Icons.access_time, 'Hours', 'Mon-Fri: 9AM-6PM EST'),
                          Divider(color: _ancientGold.withValues(alpha: 0.2), height: 24),
                          _buildContactInfo(Icons.location_on, 'Address', '123 Business St, Suite 100, New York, NY 10001'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent, // Removes lines around expansion tile
        iconTheme: const IconThemeData(color: _ancientGold),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        iconColor: _ancientGold,
        collapsedIconColor: Colors.white54,
        title: Text(
          faq['question'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16, right: 16),
            child: Text(
              faq['answer'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _ancientGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _ancientGold, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _startLiveChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting live chat...', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _callSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening phone dialer...', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _openDocumentation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening documentation...', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _openTutorials() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening video tutorials...', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: _ancientGold,
      ),
    );
  }

  void _submitMessage() {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Clear form
    _subjectController.clear();
    _messageController.clear();
    setState(() {
      _selectedCategory = 'General';
      _selectedPriority = 'Medium';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support ticket created successfully', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.greenAccent,
      ),
    );
  }
}