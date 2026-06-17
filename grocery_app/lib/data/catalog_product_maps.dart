/// Shared Firestore-shaped product maps — used by [main_seed.dart] and offline fallback.
///
/// Field names match what [ProductsProvider] expects. Amounts are **Pakistani Rupees (PKR)**.
/// `price` is stored as a string for readability in the Firebase Console.
List<Map<String, dynamic>> catalogFirestoreMaps() => [
      // --- Vegetables ---
      _p(
        id: 'tomato_1kg',
        title: 'Tomato (premium) 1kg',
        category: 'Vegetables',
        description:
            'Ripe, juicy tomatoes with a bright colour — ideal for salads, curries, and fresh chutneys.',
        price: '150',
        salePrice: 135,
        onSale: true,
        piece: false,
        img: 'https://loremflickr.com/600/400/tomato?lock=101',
      ),
      _p(
        id: 'tomato_2kg',
        title: 'Tomato (standard) 1kg',
        category: 'Vegetables',
        description:
            'Everyday cooking tomatoes with balanced sweetness and tang — great for daily gravy bases.',
        price: '135',
        salePrice: 135,
        onSale: false,
        piece: false,
        img: 'https://loremflickr.com/600/400/tomato?lock=102',
      ),
      _p(
        id: 'lettuce_1',
        title: 'Iceberg Lettuce',
        category: 'Vegetables',
        description:
            'Crisp iceberg leaves — perfect for burgers, wraps, and crunchy side salads.',
        price: '135',
        salePrice: 135,
        onSale: false,
        piece: true,
        img:
            'https://images.unsplash.com/photo-1622206151226-18ca2c9ab4a1?w=600&q=80',
      ),
      _p(
        id: 'potato_25kg',
        title: 'Potato 2.5kg bag',
        category: 'Vegetables',
        description:
            'Versatile potatoes for roasting, mash, fries, and hearty curries — a pantry staple.',
        price: '290',
        salePrice: 275,
        onSale: true,
        piece: false,
        img: 'https://loremflickr.com/600/400/potato?lock=104',
      ),
      _p(
        id: 'veg_onion_1kg',
        title: 'Onion 1kg',
        category: 'Vegetables',
        description:
            'Cooking onions with a mellow bite — the base layer for almost every savoury dish.',
        price: '120',
        salePrice: 120,
        onSale: false,
        piece: false,
        img: 'https://loremflickr.com/600/400/onion?lock=105',
      ),
      _p(
        id: 'veg_carrot_500g',
        title: 'Carrot 500g',
        category: 'Vegetables',
        description:
            'Naturally sweet carrots — slice raw for snacks or simmer into soups and stir-fries.',
        price: '85',
        salePrice: 75,
        onSale: true,
        piece: false,
        img:
            'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=600&q=80',
      ),
      _p(
        id: 'veg_cucumber',
        title: 'Cucumber (each)',
        category: 'Vegetables',
        description:
            'Cool and hydrating — dice into salads, sandwiches, or refreshing raita.',
        price: '45',
        salePrice: 45,
        onSale: false,
        piece: true,
        img:
            'https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?w=600&q=80',
      ),
      _p(
        id: 'veg_ginger_100g',
        title: 'Ginger 100g',
        category: 'Vegetables',
        description:
            'Fragrant ginger root — grate into marinades, tea, or Asian-style stir-fries.',
        price: '65',
        salePrice: 65,
        onSale: false,
        piece: false,
        img:
            'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?w=600&q=80',
      ),
      _p(
        id: 'veg_garlic_250g',
        title: 'Garlic 250g',
        category: 'Vegetables',
        description:
            'Bold garlic cloves — crush or mince for depth in sauces, rubs, and sautés.',
        price: '180',
        salePrice: 180,
        onSale: false,
        piece: false,
        img:
            'https://images.unsplash.com/photo-1540148426945-6cf22a6b2383?w=600&q=80',
      ),
      _p(
        id: 'veg_broccoli',
        title: 'Broccoli (each)',
        category: 'Vegetables',
        description:
            'Fresh broccoli florets — steam, roast, or stir-fry for a quick nutritious side.',
        price: '195',
        salePrice: 165,
        onSale: true,
        piece: true,
        img:
            'https://images.unsplash.com/photo-1584270354949-c26b0d5b4a0c?w=600&q=80',
      ),
      _p(
        id: 'veg_capsicum_mix',
        title: 'Bell Peppers 500g',
        category: 'Vegetables',
        description:
            'Colourful bell peppers — adds crunch and sweetness to pizzas, pasta, and grills.',
        price: '220',
        salePrice: 220,
        onSale: false,
        piece: false,
        img:
            'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=600&q=80',
      ),
      _p(
        id: 'veg_cabbage',
        title: 'Green Cabbage (each)',
        category: 'Vegetables',
        description:
            'Firm cabbage — shred for slaw, stir-fry, or slow-cooked comfort dishes.',
        price: '95',
        salePrice: 95,
        onSale: false,
        piece: true,
        img: 'https://loremflickr.com/600/400/cabbage?lock=112',
      ),

      // --- Fruits ---
      _p(
        id: 'orange_dozen',
        title: 'Orange 12 pcs',
        category: 'Fruits',
        description:
            'Sweet citrus oranges — peel for a vitamin C boost or squeeze fresh juice.',
        price: '140',
        salePrice: 140,
        onSale: false,
        piece: false,
        img:
            'https://images.unsplash.com/photo-1547514701-42782101795e?w=600&q=80',
      ),
      _p(
        id: 'banana_dozen',
        title: 'Banana 12 pcs',
        category: 'Fruits',
        description:
            'Creamy bananas — instant energy for breakfast bowls, shakes, or baking.',
        price: '175',
        salePrice: 175,
        onSale: false,
        piece: false,
        img:
            'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=600&q=80',
      ),
      _p(
        id: 'grapes_green',
        title: 'Green Grapes 500g',
        category: 'Fruits',
        description:
            'Snappy green grapes — chill and enjoy as a refreshing snack or cheese-board pairing.',
        price: '215',
        salePrice: 215,
        onSale: false,
        piece: false,
        img: 'https://loremflickr.com/600/400/grapes?lock=115',
      ),
      _p(
        id: 'apple_1kg',
        title: 'Apple (green) 1kg',
        category: 'Fruits',
        description:
            'Tart-sweet green apples — crisp bite that holds up in lunchboxes and pies.',
        price: '205',
        salePrice: 205,
        onSale: false,
        piece: false,
        img: 'https://loremflickr.com/600/400/apple?lock=116',
      ),
      _p(
        id: 'guava_1kg',
        title: 'Guava 1kg',
        category: 'Fruits',
        description:
            'Aromatic guavas — slice with chaat masala or blend into smoothies.',
        price: '175',
        salePrice: 175,
        onSale: false,
        piece: false,
        img: 'https://loremflickr.com/600/400/guava?lock=117',
      ),
      _p(
        id: 'fruit_mango_1kg',
        title: 'Mango (seasonal) 1kg',
        category: 'Fruits',
        description:
            'Seasonal mangoes — silky flesh when ripe; perfect for shakes and desserts.',
        price: '320',
        salePrice: 289,
        onSale: true,
        piece: false,
        img: 'https://loremflickr.com/600/400/mango?lock=118',
      ),
      _p(
        id: 'fruit_strawberry_250g',
        title: 'Strawberry 250g',
        category: 'Fruits',
        description:
            'Sweet berries — top yogurt, cakes, or blend into strawberry shakes.',
        price: '450',
        salePrice: 450,
        onSale: false,
        piece: false,
        img: 'https://loremflickr.com/600/400/strawberry?lock=119',
      ),
      _p(
        id: 'fruit_lemon_250g',
        title: 'Lemon 250g',
        category: 'Fruits',
        description:
            'Zesty lemons — brighten drinks, marinades, dressings, and seafood.',
        price: '90',
        salePrice: 90,
        onSale: false,
        piece: false,
        img: 'https://loremflickr.com/600/400/lemon?lock=120',
      ),
      _p(
        id: 'fruit_watermelon',
        title: 'Watermelon (whole)',
        category: 'Fruits',
        description:
            'Juicy summer melon — chill and serve wedges for picnics and hydration.',
        price: '280',
        salePrice: 260,
        onSale: true,
        piece: true,
        img:
            'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=600&q=80',
      ),

      // --- Herbs ---
      _p(
        id: 'mint_bundle',
        title: 'Mint Bundle',
        category: 'Herbs',
        description:
            'Cooling mint — chop into chutney, garnish drinks, or steep for herbal tea.',
        price: '45',
        salePrice: 45,
        onSale: false,
        piece: true,
        img: 'https://loremflickr.com/600/400/mint?lock=121',
      ),
      _p(
        id: 'herb_coriander',
        title: 'Fresh Coriander Bundle',
        category: 'Herbs',
        description:
            'Bright coriander — finish curries, salads, and marinades with fresh flavour.',
        price: '35',
        salePrice: 35,
        onSale: false,
        piece: true,
        img: 'https://loremflickr.com/600/400/coriander?lock=122',
      ),
      _p(
        id: 'herb_parley',
        title: 'Parsley Bundle',
        category: 'Herbs',
        description:
            'Mild curly parsley — chop into soups, stocks, and Mediterranean dishes.',
        price: '55',
        salePrice: 55,
        onSale: false,
        piece: true,
        img: 'https://loremflickr.com/600/400/parsley?lock=123',
      ),
      _p(
        id: 'herb_basil',
        title: 'Fresh Basil 50g',
        category: 'Herbs',
        description:
            'Sweet basil aroma — tear over tomatoes, pesto, pizzas, and pasta.',
        price: '120',
        salePrice: 120,
        onSale: false,
        piece: false,
        img: 'https://loremflickr.com/600/400/basil?lock=124',
      ),

      // --- Spices ---
      _p(
        id: 'saunf',
        title: 'Fennel Seeds (Saunf) 200g',
        category: 'Spices',
        description:
            'Mildly sweet fennel seeds — chew after meals or bloom in pickles and fish.',
        price: '310',
        salePrice: 310,
        onSale: false,
        piece: false,
        img:
            'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600&q=80',
      ),
      _p(
        id: 'spice_turmeric',
        title: 'Turmeric Powder 200g',
        category: 'Spices',
        description:
            'Warm golden turmeric — essential for curries, lentils, and golden milk.',
        price: '145',
        salePrice: 145,
        onSale: false,
        piece: false,
        img:
            'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600&q=80',
      ),
      _p(
        id: 'spice_red_chili',
        title: 'Red Chili Powder 200g',
        category: 'Spices',
        description:
            'Vibrant chili powder — layer heat into marinades, rubs, and everyday masalas.',
        price: '165',
        salePrice: 165,
        onSale: false,
        piece: false,
        img: 'https://loremflickr.com/600/400/red-chili?lock=128',
      ),
      _p(
        id: 'spice_cumin',
        title: 'Whole Cumin (Zeera) 200g',
        category: 'Spices',
        description:
            'Earthy whole cumin — toast lightly in oil to release nutty aroma before cooking.',
        price: '275',
        salePrice: 275,
        onSale: false,
        piece: false,
        img:
            'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600&q=80',
      ),

      // --- Grains & staples ---
      _p(
        id: 'daal_masoor',
        title: 'Masoor Daal 1kg',
        category: 'Grains',
        description:
            'Quick-cooking red lentils — comforting everyday daal rich in plant protein.',
        price: '195',
        salePrice: 195,
        onSale: false,
        piece: false,
        img: 'https://loremflickr.com/600/400/lentils?lock=130',
      ),
      _p(
        id: 'chana_white',
        title: 'White Chickpeas (Chana) 1kg',
        category: 'Grains',
        description:
            'Plump chickpeas — soak overnight for curries, salads, or creamy hummus.',
        price: '220',
        salePrice: 198,
        onSale: true,
        piece: false,
        img: 'https://loremflickr.com/600/400/chickpeas?lock=131',
      ),
      _p(
        id: 'bread_large',
        title: 'Large White Bread',
        category: 'Grains',
        description:
            'Soft sandwich loaf — toast for breakfast or stack your favourite fillings.',
        price: '230',
        salePrice: 230,
        onSale: false,
        piece: true,
        img:
            'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&q=80',
      ),
      _p(
        id: 'grain_rice_basmati',
        title: 'Basmati Rice 5kg',
        category: 'Grains',
        description:
            'Long fragrant grains — rinse and steam for fluffy rice, biryani, and pulao.',
        price: '1850',
        salePrice: 1750,
        onSale: true,
        piece: false,
        img:
            'https://images.unsplash.com/photo-1596560548464-f010549b84d7?w=600&q=80',
      ),
      _p(
        id: 'grain_oats',
        title: 'Rolled Oats 500g',
        category: 'Grains',
        description:
            'Hearty rolled oats — simmer into porridge or fold into cookies and granola.',
        price: '295',
        salePrice: 295,
        onSale: false,
        piece: false,
        img: 'https://loremflickr.com/600/400/oats?lock=134',
      ),

      // --- Nuts & dried fruit ---
      _p(
        id: 'almonds_250',
        title: 'Almonds 250g',
        category: 'Nuts',
        description:
            'Crunchy almonds — snack raw, toast for salads, or blend into smoothies.',
        price: '845',
        salePrice: 845,
        onSale: false,
        piece: false,
        img:
            'https://images.unsplash.com/photo-1508747703725-719777637510?w=600&q=80',
      ),
      _p(
        id: 'dates_mixed',
        title: 'Mixed Dates 250g',
        category: 'Nuts',
        description:
            'Naturally sweet dates — energy-rich bites for desserts and tea-time.',
        price: '398',
        salePrice: 398,
        onSale: false,
        piece: false,
        img: 'https://loremflickr.com/600/400/dates?lock=136',
      ),
      _p(
        id: 'nut_walnuts',
        title: 'Walnuts 200g',
        category: 'Nuts',
        description:
            'Buttery walnuts — chop into baking, salads, or oatmeal for rich texture.',
        price: '720',
        salePrice: 720,
        onSale: false,
        piece: false,
        img: 'https://loremflickr.com/600/400/walnuts?lock=137',
      ),
      _p(
        id: 'nut_cashews',
        title: 'Cashews 200g',
        category: 'Nuts',
        description:
            'Creamy cashews — perfect for korma-style curries, trail mix, or snacking.',
        price: '890',
        salePrice: 799,
        onSale: true,
        piece: false,
        img:
            'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=600&q=80',
      ),

      // --- Meat ---
      _p(
        id: 'chicken_boneless',
        title: 'Chicken Boneless 1kg',
        category: 'Meat',
        description:
            'Tender boneless chicken — grills quickly and stays juicy in curries and stir-fries.',
        price: '880',
        salePrice: 792,
        onSale: true,
        piece: false,
        img:
            'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=600&q=80',
      ),
      _p(
        id: 'mutton_mince',
        title: 'Mutton Mince 1kg',
        category: 'Meat',
        description:
            'Fresh ground mutton — shape into kebabs, kofta, or a savoury kheema.',
        price: '2050',
        salePrice: 1947,
        onSale: true,
        piece: false,
        img: 'https://loremflickr.com/600/400/mutton?lock=139',
      ),
      _p(
        id: 'meat_fish_fillet',
        title: 'Fish Fillet 500g',
        category: 'Meat',
        description:
            'Mild white fish fillets — pan-sear with lemon or steam with herbs for a light meal.',
        price: '650',
        salePrice: 650,
        onSale: false,
        piece: false,
        img:
            'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=600&q=80',
      ),
    ];

Map<String, dynamic> _p({
  required String id,
  required String title,
  required String category,
  required String description,
  required String price,
  required double salePrice,
  required bool onSale,
  required bool piece,
  required String img,
}) =>
    {
      'id': id,
      'title': title,
      'productCategoryName': category,
      'description': description,
      'price': price,
      'salePrice': salePrice,
      'isOnSale': onSale,
      'isPiece': piece,
      'imageUrl': img,
    };
