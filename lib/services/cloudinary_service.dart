import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String _cloudName = 'darjm6tm0';
  static const String _uploadPreset = 'ABDULLAH-MASRY';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Uploads an image file to Cloudinary and returns the secure URL.
  /// Returns null if the upload fails.
  static Future<String?> uploadImage(Uint8List imageBytes, String filename) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final url = data['secure_url'] as String?;
        debugPrint('>>> Cloudinary upload success: $url');
        return url;
      } else {
        debugPrint('>>> Cloudinary upload failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('>>> Cloudinary upload error: $e');
      return null;
    }
  }
}
