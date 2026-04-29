import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:guptik/models/facebook/meta_content_model.dart';
import 'package:guptik/services/facebook/meta_service.dart';
import 'package:guptik/config/app_theme.dart';

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
    final platformColor = _selectedPlatform == SocialPlatform.facebook
        ? AppTheme.facebookBlue
        : AppTheme.instagramPink;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text("Create Post", style: AppTheme.textTheme.headlineSmall),
        backgroundColor: AppTheme.surface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        iconTheme: const IconThemeData(color: AppTheme.dark),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Center(
              child: ElevatedButton(
                onPressed: (_canPost && !_isUploading) ? _handlePost : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_canPost && !_isUploading)
                      ? platformColor
                      : AppTheme.lightGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.md,
                  ),
                  elevation: 0,
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        "Post",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: (_canPost && !_isUploading)
                              ? Colors.white
                              : AppTheme.mediumGrey,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform Selector Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppTheme.lightGrey.withValues(alpha: 0.3),
                ),
                boxShadow: AppShadows.light,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Select Platform", style: AppTheme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPlatformButton(
                          "Facebook",
                          AppTheme.facebookBlue,
                          _selectedPlatform == SocialPlatform.facebook,
                          () => setState(
                            () => _selectedPlatform = SocialPlatform.facebook,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: _buildPlatformButton(
                          "Instagram",
                          AppTheme.instagramPink,
                          _selectedPlatform == SocialPlatform.instagram,
                          () => setState(
                            () => _selectedPlatform = SocialPlatform.instagram,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Caption Input Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppTheme.lightGrey.withValues(alpha: 0.3),
                ),
                boxShadow: AppShadows.light,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Write Caption", style: AppTheme.textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _captionController,
                    maxLines: 4,
                    style: AppTheme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: AppTheme.textTheme.bodySmall,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppTheme.lightGrey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppTheme.lightGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(color: platformColor, width: 2),
                      ),
                      filled: true,
                      fillColor: AppTheme.lightGreyBg,
                      contentPadding: const EdgeInsets.all(AppSpacing.lg),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    "${_captionController.text.length}/2200",
                    style: TextStyle(
                      fontSize: 12,
                      color: _captionController.text.length > 2000
                          ? AppTheme.warning
                          : AppTheme.mediumGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Image Upload Card
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: platformColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: AppShadows.light,
                ),
                child: _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: AppSpacing.lg,
                            right: AppSpacing.lg,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
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
                          Icon(
                            Icons.add_a_photo,
                            size: 48,
                            color: platformColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            _selectedPlatform == SocialPlatform.instagram
                                ? "Photo Required"
                                : "Add Photo",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.dark,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _selectedPlatform == SocialPlatform.instagram
                                ? "Tap to add a photo for Instagram"
                                : "Tap to add a photo (optional)",
                            style: AppTheme.textTheme.bodySmall,
                          ),
                        ],
                      ),
              ),
            ),

            // Warning for Instagram
            if (_selectedPlatform == SocialPlatform.instagram &&
                _selectedImage == null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Text(
                          "Instagram requires at least one photo to post.",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformButton(
    String label,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppTheme.background,
          border: Border.all(
            color: isSelected ? color : AppTheme.lightGrey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? color : AppTheme.mediumGrey,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppTheme.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}