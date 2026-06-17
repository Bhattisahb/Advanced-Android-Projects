import 'package:flutter/material.dart';
import 'package:grocery_app/models/home_screen_tile_model.dart';

/// Bundled defaults when Firestore `home_screen_tiles` is empty.
abstract final class HomeScreenTilePresets {
  HomeScreenTilePresets._();

  static List<HomeScreenTileModel> models() => [
        HomeScreenTileModel(
          id: '',
          sortOrder: 0,
          title: 'Most rated',
          linkType: HomeTileLinkType.mostRated,
          colorArgb: 0xFFFFB74D,
          iconCodePoint: Icons.star_rate_rounded.codePoint,
        ),
        HomeScreenTileModel(
          id: '',
          sortOrder: 1,
          title: 'Fresh Vegetables',
          linkType: HomeTileLinkType.categoryFilter,
          categoryFilter: 'Vegetables',
          colorArgb: 0xFF53B175,
          assetPath: 'assets/images/cat/veg.png',
        ),
        HomeScreenTileModel(
          id: '',
          sortOrder: 2,
          title: 'Fresh Fruits',
          linkType: HomeTileLinkType.categoryFilter,
          categoryFilter: 'Fruits',
          colorArgb: 0xFFF8A44C,
          assetPath: 'assets/images/cat/fruits.png',
        ),
        HomeScreenTileModel(
          id: '',
          sortOrder: 3,
          title: 'Frozen Meat',
          linkType: HomeTileLinkType.categoryFilter,
          categoryFilter: 'Meat',
          colorArgb: 0xFFF7A593,
          iconCodePoint: Icons.restaurant_rounded.codePoint,
        ),
        HomeScreenTileModel(
          id: '',
          sortOrder: 4,
          title: 'Breakfast & Pantry',
          linkType: HomeTileLinkType.categoryFilter,
          categoryFilter: 'Grains',
          colorArgb: 0xFFFDE598,
          assetPath: 'assets/images/cat/grains.png',
        ),
        HomeScreenTileModel(
          id: '',
          sortOrder: 5,
          title: 'Pulses',
          linkType: HomeTileLinkType.categoryFilter,
          categoryFilter: 'Grains',
          colorArgb: 0xFFE8C9A0,
          assetPath: 'assets/images/cat/grains.png',
        ),
        HomeScreenTileModel(
          id: '',
          sortOrder: 6,
          title: 'Dates & Dry Fruit',
          linkType: HomeTileLinkType.categoryFilter,
          categoryFilter: 'Nuts',
          colorArgb: 0xFFC4A484,
          assetPath: 'assets/images/cat/nuts.png',
        ),
        HomeScreenTileModel(
          id: '',
          sortOrder: 7,
          title: 'Spices & Herbs',
          linkType: HomeTileLinkType.categoryFilter,
          categoryFilter: 'Herbs',
          colorArgb: 0xFFFFE080,
          assetPath: 'assets/images/cat/spices.png',
        ),
        HomeScreenTileModel(
          id: '',
          sortOrder: 8,
          title: 'Combo Deals',
          linkType: HomeTileLinkType.onSale,
          colorArgb: 0xFFF8A44C,
          iconCodePoint: Icons.percent_rounded.codePoint,
        ),
      ];
}
