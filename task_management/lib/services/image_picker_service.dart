import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  static final ImagePickerService _instance = ImagePickerService._internal();
  
  static ImagePickerService get instance => _instance;
  
  factory ImagePickerService() => _instance;

  final ImagePicker _imagePicker = ImagePicker();

  ImagePickerService._internal();

  /// Pick an image from camera. Returns the file path or null if cancelled/denied.
  Future<String?> pickFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
      return pickedFile?.path;
    } catch (e) {
      // ignore errors (permission denied, camera unavailable, etc.)
      return null;
    }
  }

  /// Pick an image from gallery. Returns the file path or null if cancelled/denied.
  Future<String?> pickFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      return pickedFile?.path;
    } catch (e) {
      // ignore errors (permission denied, gallery unavailable, etc.)
      return null;
    }
  }

  /// Pick multiple images from gallery. Returns list of file paths.
  Future<List<String>> pickMultipleFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();
      return pickedFiles.map((file) => file.path).toList();
    } catch (e) {
      // ignore errors
      return [];
    }
  }
}
