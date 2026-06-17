class CloudinaryConfig {
  const CloudinaryConfig._();

  // Step 1 in Cloudinary: copy your Cloud name here.
  static const cloudName = 'dv8pdj9pc';

  // Step 2 in Cloudinary: create an unsigned upload preset and copy its name.
  static const uploadPreset = 'n6nvlvif';

  static const productImagesFolder = 'grocery_products';

  /// Category tiles / catalog artwork (admin-managed).
  static const categoryImagesFolder = 'grocery_categories';

  /// Home screen shortcut bubbles (admin-managed).
  static const homeTileImagesFolder = 'grocery_home_tiles';
}
