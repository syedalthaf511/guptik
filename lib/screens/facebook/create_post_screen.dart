import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:guptik/models/facebook/meta_content_model.dart'; // For SocialPlatform enum
import 'package:guptik/services/facebook/meta_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final MetaService _metaService = MetaService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  final TextEditingController _captionController = TextEditingController();
  SocialPlatform _selectedPlatform = SocialPlatform.facebook;
  bool _isUploading = false;

  bool get _canPost => _captionController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _captionController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _handlePost() async {
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a caption.")));
      return;
    }

    // Instagram requires an image
    if (_selectedPlatform == SocialPlatform.instagram &&
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Instagram posts require an image. Please select one."),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    bool success = await _metaService.uploadPost(
      _selectedPlatform,
      _selectedImage,
      _captionController.text,
    );

    if (mounted) {
      setState(() => _isUploading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Posted successfully!")));
      } else {
        String errorMsg =
            _selectedPlatform == SocialPlatform.instagram &&
                _selectedImage == null
            ? "Instagram requires an image to post."
            : "Upload failed. Check console for details.";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Create New Post",
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withValues(alpha: 0.1),
        iconTheme: IconThemeData(color: Colors.grey[800]),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton(
              onPressed: (_canPost && !_isUploading) ? _handlePost : null,
              style: TextButton.styleFrom(
                backgroundColor: (_canPost && !_isUploading)
                    ? const Color(0xFF1877F2)
                    : Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 10,
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      "Post",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: (_canPost && !_isUploading)
                            ? Colors.white
                            : Colors.grey[600],
                        letterSpacing: 0.4,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform Selector
            Row(
              children: [
                const Text(
                  "Post to: ",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Facebook"),
                  selected: _selectedPlatform == SocialPlatform.facebook,
                  onSelected: (val) => setState(
                    () => _selectedPlatform = SocialPlatform.facebook,
                  ),
                  selectedColor: Colors.blue.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _selectedPlatform == SocialPlatform.facebook
                        ? Colors.blue
                        : Colors.black,
                  ),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Instagram"),
                  selected: _selectedPlatform == SocialPlatform.instagram,
                  onSelected: (val) => setState(
                    () => _selectedPlatform = SocialPlatform.instagram,
                  ),
                  selectedColor: Colors.pink.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _selectedPlatform == SocialPlatform.instagram
                        ? Colors.pink
                        : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Caption Input
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 20),

            // Image Picker Area (Optional for Facebook, Required for Instagram)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                          const SizedBox(height: 10),
                          Text(
                            _selectedPlatform == SocialPlatform.instagram
                                ? "Photo Required for Instagram"
                                : "Add Photo (Optional for Facebook)",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
              ),
            ),
            if (_selectedPlatform == SocialPlatform.instagram &&
                _selectedImage == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Instagram requires an image. Please select one to post.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
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
}