import 'dart:convert';

import 'package:grocery_app/config/cloudinary_config.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ProductImageStorageService {
  const ProductImageStorageService();

  Future<String> uploadProductImage({
    required String productId,
    required XFile image,
  }) async {
    return _upload(
      folder: CloudinaryConfig.productImagesFolder,
      publicId: productId,
      image: image,
    );
  }

  Future<String> uploadCategoryImage({
    required String categoryDocId,
    required XFile image,
  }) async {
    return _upload(
      folder: CloudinaryConfig.categoryImagesFolder,
      publicId: categoryDocId,
      image: image,
    );
  }

  Future<String> uploadHomeTileImage({
    required String tileDocId,
    required XFile image,
  }) async {
    return _upload(
      folder: CloudinaryConfig.homeTileImagesFolder,
      publicId: tileDocId,
      image: image,
    );
  }

  Future<String> _upload({
    required String folder,
    required String publicId,
    required XFile image,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );
    final bytes = await image.readAsBytes();
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = folder
      ..fields['public_id'] = publicId
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: image.name,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cloudinary upload failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = decoded['secure_url']?.toString();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary upload did not return an image URL.');
    }
    return secureUrl;
  }
}
