/// Constants and explanations for the AI Demand Prediction System
/// This file contains all text explanations in multiple languages
class DemandPredictionConstants {
  // ==========================================
  // AI SYSTEM EXPLANATIONS
  // ==========================================
  
  /// English explanation of the AI system
  static const String aiExplanationEnglish = '''This system analyzes recent sales trends using AI-based logic to help businesses manage stock efficiently.

How it works:
1. Analyzes sales data from the last 7 days
2. Detects demand trends (Increasing, Decreasing, or Stable)
3. Calculates optimal reorder quantities
4. Identifies slow-moving products
5. Provides profit/loss analysis

The AI considers:
• Average daily sales trends
• Current stock levels
• Product profitability
• Market demand patterns

This helps shop owners make smart decisions about which products to order and how much to stock.''';

  /// Urdu explanation of the AI system
  static const String aiExplanationUrdu = '''یہ نظام حالیہ فروخت کے ڈیٹا کو تجزیہ کر کے اسٹاک مینجمنٹ میں ذہین فیصلے سجھاتا ہے۔

یہ کیسے کام کرتا ہے:
۱۔ پچھلے ۷ دن کی فروخت کا تجزیہ کرتا ہے
۲۔ مانگ کے رجحانات تلاش کرتا ہے (بڑھتی، گھٹتی، یا مستحکم)
۳۔ بہترین دوبارہ آرڈر کی مقدار کا حساب لگاتا ہے
۴۔ آہستہ فروخت والی مصنوعات کی نشاندہی کرتا ہے
۵۔ منافع/نقصان کا تجزیہ فراہم کرتا ہے

AI مندرجہ ذیل پر غور کرتا ہے:
• روزانہ اوسط فروخت کے رجحانات
• موجودہ اسٹاک کی سطح
• مصنوع کی منافع بخشی
• بازار کی مانگ کے نمونے

یہ دکان کے مالکان کو اسمارٹ فیصلے لینے میں مدد دیتا ہے کہ کون سی مصنوعات خریدنی ہیں اور کتنی مقدار میں۔''';

  // ==========================================
  // DEMAND TREND EXPLANATIONS
  // ==========================================
  
  static const String trendIncreasingEnglish =
      'Product demand is going UP! Sales are increasing. This is a good sign - people want this product more.';
  
  static const String trendIncreasingUrdu =
      'مصنوع کی مانگ بڑھ رہی ہے! فروخت میں اضافہ ہو رہا ہے۔ یہ ایک اچھی علامت ہے - لوگوں کو یہ مصنوع زیادہ چاہی ہے۔';

  static const String trendDecreasingEnglish =
      'Product demand is going DOWN. Sales are decreasing. People are buying less of this product.';
  
  static const String trendDecreasingUrdu =
      'مصنوع کی مانگ کم ہو رہی ہے۔ فروخت میں کمی ہو رہی ہے۔ لوگ اس مصنوع کو کم خریدنا پسند کر رہے ہیں۔';

  static const String trendStableEnglish =
      'Product demand is STABLE. Sales are consistent. This product is selling at a steady rate.';
  
  static const String trendStableUrdu =
      'مصنوع کی مانگ مستحکم ہے۔ فروخت میں مطابقت ہے۔ یہ مصنوع برابر شرح سے فروخت ہو رہی ہے۔';

  // ==========================================
  // REORDER LOGIC EXPLANATION
  // ==========================================
  
  static const String reorderExplanationEnglish = '''REORDER QUANTITY CALCULATION:

Formula: (Average Daily Sales × 7 days) - Current Stock

Example:
If average daily sales = 50 units
And you need 7 days of stock
Total needed = 50 × 7 = 350 units

If current stock = 200 units
Reorder quantity = 350 - 200 = 150 units

This ensures you always have enough stock for a week!''';

  static const String reorderExplanationUrdu = '''دوبارہ آرڈر کی مقدار کا حساب:

فارمولا: (روزانہ اوسط فروخت × ۷ دن) - موجودہ اسٹاک

مثال:
اگر روزانہ اوسط فروخت = ۵۰ یونٹ
اور آپ کو ۷ دن کے لیے اسٹاک چاہیے
کل ضرورت = ۵۰ × ۷ = ۳۵۰ یونٹ

اگر موجودہ اسٹاک = ۲۰۰ یونٹ
دوبارہ آرڈر = ۳۵۰ - ۲۰۰ = ۱۵۰ یونٹ

یہ یقینی بناتا ہے کہ آپ کے پاس ہمیشہ ایک ہفتے کے لیے اسٹاک ہو!''';

  // ==========================================
  // PROFIT LOSS EXPLANATION
  // ==========================================
  
  static const String profitExplanationEnglish = '''PROFIT CALCULATION:

Formula: (Selling Price - Cost Price) × Quantity Sold

Example:
Cost Price = PKR 100
Selling Price = PKR 150
Profit per unit = 150 - 100 = PKR 50

If 100 units sold
Total Profit = 50 × 100 = PKR 5,000

If profit is NEGATIVE, you're losing money on this product!''';

  static const String profitExplanationUrdu = '''منافع کا حساب:

فارمولا: (فروخت کی قیمت - لاگت کی قیمت) × فروخت کی گئی مقدار

مثال:
لاگت کی قیمت = ۱۰۰ روپے
فروخت کی قیمت = ۱۵۰ روپے
ہر یونٹ کا منافع = ۱۵۰ - ۱۰۰ = ۵۰ روپے

اگر ۱۰۰ یونٹ فروخت ہوے
کل منافع = ۵۰ × ۱۰۰ = ۵۰۰۰ روپے

اگر منافع منفی ہے، تو آپ اس مصنوع پر نقصان کھا رہے ہیں!''';

  // ==========================================
  // STOCK LEVEL EXPLANATIONS
  // ==========================================
  
  static const String lowStockWarningEnglish =
      '⚠️ WARNING: Your stock is below the minimum threshold! Reorder immediately to avoid running out.';
  
  static const String lowStockWarningUrdu =
      '⚠️ انتباہ: آپ کا اسٹاک کم سے کم حد سے کم ہے! ختم ہونے سے بچنے کے لیے فوری طور پر آرڈر دیں۔';

  static const String healthyStockEnglish =
      '✓ Your stock level is healthy. No urgent reorder needed.';
  
  static const String healthyStockUrdu =
      '✓ آپ کی اسٹاک کی سطح صحت مند ہے۔ فوری آرڈر کی ضرورت نہیں۔';

  // ==========================================
  // BUSINESS TIPS
  // ==========================================
  
  static const String businessTipsEnglish = '''💡 SMART BUSINESS TIPS:

1. INCREASING DEMAND:
   - Reorder stock immediately
   - Stock might run out
   - This product makes profit!

2. DECREASING DEMAND:
   - Don't waste money on stock
   - Wait for demand to improve
   - Review product quality/price

3. STABLE DEMAND:
   - Maintain consistent orders
   - This product is reliable
   - Easy to manage inventory

4. PROFIT LOSS:
   - Review your pricing
   - Check product quality
   - Consider removing if persistent loss''';

  static const String businessTipsUrdu = '''💡 ذہین کاروباری تجاویز:

۱۔ بڑھتی ہوئی مانگ:
   - فوری طور پر اسٹاک آرڈر کریں
   - اسٹاک ختم ہو سکتا ہے
   - یہ مصنوع منافع دیتی ہے!

۲۔ گھٹتی ہوئی مانگ:
   - اسٹاک پر رقم ضائع نہ کریں
   - مانگ بہتر ہونے کا انتظار کریں
   - مصنوع کی کوالٹی/قیمت دوبارہ دیکھیں

۳۔ مستحکم مانگ:
   - مستقل آرڈر برقرار رکھیں
   - یہ مصنوع قابل اعتماد ہے
   - انوینٹری کا انتظام آسان ہے

۴۔ منافع کا نقصان:
   - اپنی قیمت کا جائزہ لیں
   - مصنوع کی کوالٹی چیک کریں
   - اگر مسلسل نقصان ہو تو ہٹانے پر غور کریں''';
}
