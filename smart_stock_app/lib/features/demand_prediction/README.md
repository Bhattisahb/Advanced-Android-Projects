# SmartStock AI - Demand Prediction System

## 📊 Overview

This is a **complete AI-based demand prediction system** for small and medium businesses in Pakistan. It uses simple, easy-to-understand rule-based logic to help shop owners make smart decisions about stock management.

**This is a student competition project that is competition-ready!**

---

## 🎯 Core Features

### 1. **Demand Trend Detection**
Analyzes sales patterns to determine if demand is:
- **Increasing** 📈 - Product is hot! Reorder immediately
- **Decreasing** 📉 - Sales are slowing. Avoid reordering
- **Stable** ➡️ - Consistent sales. Monitor regularly

### 2. **Stock Level Alerts**
- Monitors current stock vs. minimum threshold
- Shows low stock warnings
- Suggests when to reorder

### 3. **Smart Reorder Calculations**
Uses the formula:
```
Reorder Quantity = (Average Daily Sales × 7) - Current Stock
```
Ensures you always have a week's worth of stock!

### 4. **Profit/Loss Analysis**
```
Profit = (Selling Price - Cost Price) × Quantity Sold
```
Identifies unprofitable products that need pricing review.

### 5. **Sales Visualization**
Interactive 7-day sales chart showing:
- Daily sales quantities
- Highest, average, and total sales
- Color-coded trend indicators

---

## 📁 Project Structure

```
lib/features/demand_prediction/
├── models/
│   └── demand_prediction_result.dart          # Data model
├── services/
│   └── demand_prediction_service.dart         # AI logic (✨ Core!)
├── screens/
│   └── demand_prediction_screen.dart          # Main UI screen
├── widgets/
│   └── sales_trend_chart.dart                 # 7-day chart
├── constants/
│   └── ai_explanations.dart                   # English & Urdu text
└── index.dart                                 # Easy imports
```

---

## 🤖 AI Logic Explained (Simple & Easy!)

### Algorithm 1: Demand Trend Detection

```
Step 1: Calculate average of FIRST 3 days sales
Step 2: Calculate average of LAST 3 days sales

IF last_avg > first_avg:
    → Demand is INCREASING ✅
ELSE IF sales decreased for 4 consecutive days:
    → Demand is DECREASING ❌
ELSE:
    → Demand is STABLE 📊
```

### Algorithm 2: Low Stock Alert

```
IF currentStock < minimumThreshold:
    → Show warning to owner ⚠️
    → Add "Reorder urgently" message
```

### Algorithm 3: Reorder Quantity

```
avgDailySales = sum of all 7 days / 7
needFor7Days = avgDailySales × 7
reorderQty = needFor7Days - currentStock

If result is negative → Set to 0 (Don't reorder yet)
```

### Algorithm 4: Profit Analysis

```
profit = (sellingPrice - costPrice) × totalSold

IF profit < 0:
    → Product is losing money ❌
    → Add: "Review pricing!" message
ELSE:
    → Product is profitable ✅
```

---

## 📱 UI Features

### Demand Trend Card
Shows the main trend indicator with emoji and status badge.

### Stock Status Card
Displays:
- Current stock quantity
- Minimum threshold
- Suggested reorder amount
- Low stock warning badge (if needed)

### Sales Trend Chart
- 7-day bar chart
- Color coding (Blue: baseline, Purple: middle, Green: recent)
- Hover tooltips with exact values
- Statistics box (Highest, Average, Total)

### Profit/Loss Indicator
- Shows total profit earned
- Color coded (Green = profit, Red = loss)
- Money 💰 or chart 📉 emoji

### AI Recommendation Card
- Smart suggestion based on trend
- Urgent warnings if needed
- Profit loss alerts

### Detailed Analysis Report
Professional report format with:
- Product name
- Demand trend
- Average daily sales
- Stock status
- Profit information
- Clear recommendations

---

## 🌍 Bilingual Support

All explanations are available in:

### English 🇬🇧
Clear, business-focused explanations

### Urdu 🇵🇰
Complete Urdu translations for local shop owners

---

## 💻 Code Quality

✅ **Clean Code**
- Well-commented
- Easy to understand
- Beginner-friendly

✅ **Professional Structure**
- Clear separation of concerns
- Models, Services, Screens, Widgets
- Reusable components

✅ **Competition-Ready**
- Impressive UI/UX
- Simple algorithm explanations
- Perfect for judges to understand

---

## 🚀 Quick Start

### 1. Import the feature
```dart
import 'package:smart_stock_app/features/demand_prediction/index.dart';
```

### 2. Navigate to the screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DemandPredictionScreen(),
  ),
);
```

### 3. Or use the service directly
```dart
final result = DemandPredictionService.analyzeDemand(
  productName: 'Rice',
  last7DaysSales: [45, 42, 40, 55, 60, 65, 68],
  currentStock: 50,
  minimumStockThreshold: 100,
  costPrice: 1200.0,
  sellingPrice: 1500.0,
);

print('Demand: ${result.demandTrend}');
print('Suggestion: ${result.suggestion}');
print('Reorder: ${result.suggestedReorderQty} units');
```

---

## 📊 Dummy Data Included

The demo includes 4 sample products:
1. **Rice (10kg)** - Increasing demand ⬆️
2. **Wheat Flour (5kg)** - Decreasing demand ⬇️
3. **Cooking Oil (1L)** - Stable demand ➡️
4. **Sugar (5kg)** - Low stock alert ⚠️

Users can select any product to see the AI analysis in action!

---

## 🎓 Perfect for Explaining to Judges

### Why This AI is Smart:
1. **Simple Logic** - No complex math, easy to explain
2. **Real Business Problem** - Solves actual SMB needs
3. **Clear Visualizations** - Charts show trends instantly
4. **Bilingual** - Serves local market
5. **Well-Commented** - Every line has explanations

### Explaining the Algorithm:
"This system looks at the last 7 days of sales. If the last 3 days sold more than the first 3 days, demand is increasing. We then calculate how much stock is needed for the next week. Simple, effective, and that's what makes it great for small businesses!"

---

## 🔧 Customization

### Add More Products
Edit the `dummyProducts` map in `demand_prediction_screen.dart`

### Change Time Period
Modify the algorithms to use 14 days, 30 days, etc.

### Adjust Thresholds
Configure the percentage difference for "Increasing" vs "Stable"

### Add More Languages
Add constants to `ai_explanations.dart`

---

## ✨ Features Highlights

| Feature | Status | Details |
|---------|--------|---------|
| Demand Trend Detection | ✅ | Increasing, Decreasing, Stable |
| Low Stock Alerts | ✅ | Real-time warnings |
| Reorder Calculation | ✅ | Smart quantity suggestions |
| Profit Analysis | ✅ | Revenue/Loss tracking |
| 7-Day Chart | ✅ | Beautiful visualization |
| Bilingual UI | ✅ | English & Urdu support |
| Professional Design | ✅ | Competition-ready UI |
| Well-Documented | ✅ | Clean, commented code |

---

## 🏆 Competition Advantages

1. **Complete Solution** - Solves real SMB problems
2. **Impressive UI** - Professional looking interface
3. **Simple Algorithm** - Easy to explain in 2 minutes
4. **Bilingual** - Relevant to Pakistan market
5. **Practical** - Can be implemented immediately
6. **Well-Coded** - Shows programming skills
7. **Business-Focused** - Judges will appreciate the value

---

## 📚 AI Explanation in App

**English:**
> "This system analyzes recent sales trends using AI-based logic to help businesses manage stock efficiently."

**اردو:**
> "یہ نظام حالیہ فروخت کے ڈیٹا کو تجزیہ کر کے اسٹاک مینجمنٹ میں ذہین فیصلے سجھاتا ہے۔"

---

## 🎯 Perfect For

- ✅ SmartStock AI competition project
- ✅ Portfolio showcase
- ✅ Job interviews (demonstrates full-stack thinking)
- ✅ Real business implementation
- ✅ Learning Flutter UI/UX
- ✅ Understanding business logic programming

---

## 📝 Notes

- Uses dummy data (can integrate with Firebase later)
- All logic is deterministic (no machine learning needed)
- Easy to test and debug
- Can be extended with real database

---

## 🚀 Next Steps

1. ✅ Copy all files to your project
2. ✅ Run the app and test the feature
3. ✅ Show to judges and explain the logic
4. ✅ Get 100/100 in competition! 🎉

---

**Good luck with your competition! This system is ready to impress! 🚀**
