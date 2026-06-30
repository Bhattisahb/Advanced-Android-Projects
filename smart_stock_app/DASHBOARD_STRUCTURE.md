# Dashboard Structure Overview

## Screen Layout:

```
┌─────────────────────────────────────────┐
│  SmartStock AI Dashboard        [+] [≡]  │  ← Top bar with add/manage buttons
├─────────────────────────────────────────┤
│                                         │
│     📱 Introduction Section             │
│  AI-Powered Demand Prediction System    │
│                                         │
├─────────────────────────────────────────┤
│  📊 PRODUCTS OVERVIEW                   │
│  Total: 4 products                      │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🍚 Rice (10kg)        [✏️] [🗑️]  │   │
│  │ Increasing ⚠️ Low Stock          │   │
│  ├─────────────────────────────────┤   │
│  │ Stock: 50  │ Avg: 56.1  │ Profit: 28000 │
│  ├─────────────────────────────────┤   │
│  │ 💡 Suggestion:                  │   │
│  │ "URGENT: Low stock + High       │   │
│  │  demand! Reorder immediately!" │   │
│  │                                  │   │
│  │ [View Detailed Analysis]        │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🌾 Wheat Flour (5kg)  [✏️] [🗑️]  │   │
│  │ Decreasing                      │   │
│  │ ...                             │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🛢️ Cooking Oil (1L)    [✏️] [🗑️]  │   │
│  │ Stable                          │   │
│  │ ...                             │   │
│  └─────────────────────────────────┘   │
│                                         │
├─────────────────────────────────────────┤
│  📈 COLLECTIVE ANALYSIS                 │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────┐  ┌──────────────┐   │
│  │📦 Total      │  │✓ Inventory   │   │
│  │ Inventory    │  │  Health      │   │
│  │              │  │              │   │
│  │ 345 units    │  │ Low          │   │
│  └──────────────┘  └──────────────┘   │
│                                         │
│  ┌──────────────┐  ┌──────────────┐   │
│  │💰 Total      │  │📊 Avg Daily  │   │
│  │ Revenue      │  │ Sales        │   │
│  │              │  │              │   │
│  │PKR 150,000   │  │ 225.3 units  │   │
│  └──────────────┘  └──────────────┘   │
│                                         │
│  ⚠️ LOW STOCK ALERT                     │
│  2 product(s) have low stock           │
│                                         │
│  📊 Market Trends                       │
│  Increasing: 2    Stable: 1   Decreasing: 1 │
│                                         │
└─────────────────────────────────────────┘
```

## Individual Product Card Details:

```
┌──────────────────────────────┐
│ PRODUCT NAME         [Edit] [Delete]
│ Trend Status  ⚠️ Alert Status
├──────────────────────────────┤
│ Stock: 50/100  Avg Daily: 56.1  Profit: 28K
├──────────────────────────────┤
│ 💡 Suggestion:
│ "Smart recommendation based
│  on AI analysis of trends"
├──────────────────────────────┤
│ [View Detailed Analysis...]
└──────────────────────────────┘
```

## Detailed Analysis Modal:

```
┌──────────────────────────┐
│ RICE (10KG)           [X]
├──────────────────────────┤
│ Demand Trend      Increasing
│ Avg Daily Sales   56.1 units
│ Current Stock     50
│ Minimum Threshold 100
│ Suggested Reorder 272
│ Total Profit      PKR 28,000
│ Low Stock Alert   Yes ⚠️
├──────────────────────────┤
│ Sales Chart (7-day visualization)
│
│        📈
│       /
│      /
│     /
├──────────────────────────┤
│ Detailed Analysis:
│ - Sales trend shows strong
│   increase over 7 days
│ - Current stock critically
│   below threshold
│ - High demand continues
│ - Immediate reorder needed
│
│             [Close]
└──────────────────────────┘
```

## Manage Products Screen:

```
┌──────────────────────────┐
│ MANAGE PRODUCTS      [X]
├──────────────────────────┤
│ Total Products: 4
│
│ ┌──────────────────────┐
│ │ Rice (10kg)  [✏️][🗑️]│
│ │ Stock: 50/100 ⚠️     │
│ └──────────────────────┘
│
│ ┌──────────────────────┐
│ │ Wheat Flour   [✏️][🗑️]│
│ │ Stock: 200/150 ✓     │
│ └──────────────────────┘
│
│ ┌──────────────────────┐
│ │ Cooking Oil   [✏️][🗑️]│
│ │ Stock: 80/50 ✓       │
│ └──────────────────────┘
│
│ [+ Add New Product]
└──────────────────────────┘
```

## Add/Edit Product Form:

```
┌────────────────────────────────┐
│ ADD NEW PRODUCT/EDIT      [X]
├────────────────────────────────┤
│
│ Product Name: [_______________]
│
│ Last 7 Days Sales (One per day):
│ [Day1] [Day2] [Day3] [Day4]
│ [Day5] [Day6] [Day7]
│
│ Current Stock: [_______________]
│
│ Minimum Threshold: [___________]
│
│ Cost Price (PKR): [____________]
│
│ Selling Price (PKR): [_________]
│
│  [Cancel]        [Save]
└────────────────────────────────┘
```

---

**Color Scheme:**
- 🟢 Green: Positive (Increasing demand, Profit, Good stock)
- 🔴 Red: Negative (Decreasing demand, Loss, Low stock)
- 🟠 Orange: Caution (Stable trend, Moderate metrics)
- 🔵 Blue: Neutral (Edit actions)

**Icons Used:**
- 📊 Dashboard & Analytics
- 📈 Growth & Trends
- ⚠️ Warnings & Alerts
- 💡 Suggestions
- ✏️ Edit
- 🗑️ Delete
- ✓ Success/Good
- 📱 Products
- 💰 Revenue
- 📦 Inventory
