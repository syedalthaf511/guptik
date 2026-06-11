import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:guptik/services/mediaplayer/mobile_upload_service.dart';

class MobileUploadScreen extends StatefulWidget {
  final String gatewayUrl;

  const MobileUploadScreen({super.key, required this.gatewayUrl});

  // 🚀 FIXED: Retuned public State widget visibility interface to stop private type leaks
  @override
  State<MobileUploadScreen> createState() => _MobileUploadScreenState();
}

class _MobileUploadScreenState extends State<MobileUploadScreen> {
  late MobileUploadService _uploadService;
  bool _isUploading = false;

  final TextEditingController _channelNameController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  String _selectedCategory = 'Entertainment';
  final List<String> _categories = ['Entertainment', 'Tech', 'Education', 'Gaming', 'Music', 'Vlog', 'News'];

  String _selectedVisibility = 'public';
  bool _isReel = false;
  bool _isMonetized = false;

  File? _selectedVideoFile;
  String _fileLabel = "No file selected";

  @override
  void initState() {
    super.initState();
    _uploadService = MobileUploadService(gatewayUrl: widget.gatewayUrl);
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedVideoFile = File(result.files.single.path!);
        _fileLabel = result.files.single.name;
      });
    }
  }

  Future<void> _publishVideo() async {
    if (_selectedVideoFile == null || _titleController.text.isEmpty || _channelNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill out Title, Channel, and select a Video file.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    List<String> tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    bool success = await _uploadService.uploadVideoFromMobile(
      videoFile: _selectedVideoFile!,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      tags: tags,
      visibility: _selectedVisibility,
      isReel: _isReel,
      isMonetized: _isMonetized,
      channelName: _channelNameController.text.trim(),
    );

    // 🚀 FIXED: Checks context safety bounds across async network thread pools
    if (!mounted) return;

    setState(() => _isUploading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 Video Published to Network Successfully!"), backgroundColor: Colors.green),
      );
      _titleController.clear();
      _descController.clear();
      _tagsController.clear();
      setState(() {
        _selectedVideoFile = null;
        _fileLabel = "No file selected";
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Upload Failed. Check Node connection status."), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Creator Studio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.orange),
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text("Uploading blocks to decentralized hub...", style: TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Publish to Network", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
                    child: Row(
                      children: [
                        const Icon(Icons.video_collection, color: Colors.orange, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_fileLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.black),
                          onPressed: _pickVideo,
                          child: const Text("Browse", style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildFormInput("Channel Name", _channelNameController, hint: "e.g., Meta Fly Studios"),
                  const SizedBox(height: 16),
                  _buildFormInput("Video Title", _titleController, hint: "Enter cinematic title"),
                  const SizedBox(height: 16),
                  _buildFormInput("Description", _descController, hint: "Provide video notes...", maxLines: 3),
                  const SizedBox(height: 16),
                  _buildFormInput("Tags (comma separated)", _tagsController, hint: "privacy, tech, open-source"),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: _buildDropdown("Category", _selectedCategory, _categories, (v) => setState(() => _selectedCategory = v!))),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDropdown("Visibility", _selectedVisibility, ['public', 'unlisted', 'private'], (v) => setState(() => _selectedVisibility = v!))),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    title: const Text("Publish as Reel / Short", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    // 🚀 FIXED: Swapped deprecated activeColor option out for activeThumbColor
                    activeThumbColor: Colors.orange,
                    contentPadding: EdgeInsets.zero,
                    value: _isReel,
                    onChanged: (v) => setState(() => _isReel = v),
                  ),
                  SwitchListTile(
                    title: const Text("Enable Monetization Layout", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    // 🚀 FIXED: Swapped deprecated activeColor option out for activeThumbColor
                    activeThumbColor: Colors.orange,
                    contentPadding: EdgeInsets.zero,
                    value: _isMonetized,
                    onChanged: (v) => setState(() => _isMonetized = v),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: _isUploading ? null : _publishVideo,
                      child: const Text("Publish Video", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFormInput(String label, TextEditingController controller, {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🚀 FIXED: Replaced invalid typo constant selection token 'whiteBxl' with standard 'white70'
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String currentVal, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentVal,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}