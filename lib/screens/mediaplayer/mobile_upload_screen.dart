import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:guptik/services/mediaplayer/mobile_upload_service.dart';

class MobileUploadScreen extends StatefulWidget {
  final String gatewayUrl;

  MobileUploadScreen({required this.gatewayUrl});

  @override
  _MobileUploadScreenState createState() => _MobileUploadScreenState();
}

class _MobileUploadScreenState extends State<MobileUploadScreen> {
  late MobileUploadService _uploadService;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _uploadService = MobileUploadService(gatewayUrl: widget.gatewayUrl);
  }

  Future<void> _pickAndUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() => _isUploading = true);
      
      bool success = await _uploadService.uploadVideoFromMobile(
        videoFile: File(result.files.single.path!),
        title: "Mobile Upload", 
        description: "Uploaded from phone", 
        category: "general"
      );

      setState(() => _isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "Upload Complete!" : "Upload Failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload to Vault")),
      body: Center(
        child: _isUploading 
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _pickAndUpload,
                child: Text("Select Video from Gallery"),
              ),
      ),
    );
  }
}