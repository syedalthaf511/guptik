import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MobileUploadService {
  final String gatewayUrl;

  MobileUploadService({required this.gatewayUrl});

  Future<bool> uploadVideoFromMobile({
    required File videoFile,
    required String title,
    required String description,
    required String category,
  }) async {
    try {
      final safeUrl = gatewayUrl.startsWith('http') ? gatewayUrl : 'https://$gatewayUrl';
      
      var request = http.MultipartRequest('POST', Uri.parse('$safeUrl/player/video/upload'));
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['category'] = category;
      
      request.files.add(await http.MultipartFile.fromPath('video', videoFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Mobile Upload Error: $e");
      return false;
    }
  }
}