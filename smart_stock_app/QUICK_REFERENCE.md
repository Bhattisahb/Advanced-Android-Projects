# SmartStock AI - Quick Reference Card

## 🎯 Dashboard Sections

### 1️⃣ Products Overview
**What:** Individual analysis for each product
**Shows:**
- 📊 Product name & demand trend
- 📦 Stock status with alert
- 💹 Avg daily sales
- 💰 Profit/loss
- 💡 AI suggestion
- [✏️ Edit] [🗑️ Delete] [Details]

**Use:** Monitor individual products

---

### 2️⃣ Collective Analysis
**What:** Business-level overview
**Shows:**
- 📊 Total inventory
- 🏥 Inventory health
- 💰 Total revenue
- 📈 Avg daily sales
- ⚠️ Low stock count
- 📊 Trend distribution

**Use:** Business health check

---

### 3️⃣ Detailed Analysis Modal
**What:** Deep dive into one product
**Shows:**
- All metrics
- Sales chart (7-day)
- Comprehensive analysis
- AI insights

**Use:** Decision-making

---

## 🎮 Main Actions

| Action | Button | Location |
|--------|--------|----------|
| Add Product | [➕] | Top right |
| Manage Products | [≡] | Top right |
| View Details | [Blue Button] | Product card |
| Edit Product | [✏️] | Product card |
| Delete Product | [🗑️] | Product card |
| Close Modal | [✕] | Dialog top |

---

## 📱 Product Card Layout

```
[Product Name]                    [✏️][🗑️]
Demand: Increasing ⚠️ Low Stock

Stock: 50  │  Avg: 56.1  │  Profit: 28K

💡 Suggestion: "..."

[View Detailed Analysis]
```

---

## 📊 Collective Metrics Explained

### Total Inventory
**Value:** Sum of current stock across all products
**Good if:** Greater than total minimum thresholds

### Inventory Health
**Good:** Total stock ≥ total threshold
**Low:** Total stock < total threshold

### Total Revenue
**Value:** Sum of (Selling - Cost) × Quantity for all products
**Green:** Profit (positive number)
**Red:** Loss (negative number)

### Avg Daily Sales
**Value:** Average daily sales across all products
**Use:** Understand aggregate demand

### Low Stock Alerts
**Value:** Count of products below minimum threshold
**Action:** If > 0, need to reorder

### Market Trends
**Increasing:** Products with rising demand
**Stable:** Products with steady demand
**Decreasing:** Products with falling demand

---

## 🌈 Color Meanings

| Color | Meaning | When |
|-------|---------|------|
| 🟢 Green | Good | Profit, increasing demand, enough stock |
| 🔴 Red | Bad | Loss, low stock, decreasing demand |
| 🟠 Orange | Neutral | Stable trend, moderate metrics |
| 🔵 Blue | Action | Edit/interact with item |
| ⚪ Gray | Info | Neutral information |

---

## 💡 AI Suggestions by Scenario

| Scenario | Suggestion |
|----------|-----------|
| High demand + Low stock | "URGENT: Reorder immediately!" |
| Low demand + High stock | "Avoid reordering; demand recovering" |
| Stable trend | "Sales are stable; monitor regularly" |
| Rising sales | "High demand; maintain good stock" |
| Falling sales | "Slow-moving; careful on orders" |

---

## 📥 Input Form Fields

```
Product Name:           [Text input]
Day 1 Sales:           [0-999]
Day 2 Sales:           [0-999]
... (Days 3-7)
Current Stock:         [0-99999]
Minimum Threshold:     [0-99999]
Cost Price (PKR):      [0-999999]
Selling Price (PKR):   [0-999999]
```

**Tips:**
- Use actual sales data
- Set realistic thresholds
- Cost < Selling price (for profit)

---

## 🔄 Data Flow

```
User Input
    ↓
Validation
    ↓
AI Analysis
    ↓
Database Save
    ↓
UI Update
    ↓
Dashboard Display
```

---

## ⚡ Quick Tips

1. **First Launch**
   - App comes with sample products
   - Edit or delete to start fresh
   - Add your own products

2. **Daily Use**
   - Check dashboard in morning
   - Act on ⚠️ alerts
   - Update sales figures daily

3. **Best Results**
   - Use accurate sales data
   - Set proper thresholds
   - Monitor trends regularly

4. **Avoid Issues**
   - Don't delete products with old data
   - Keep cost < selling price
   - Minimum > 0 for alerts to work

---

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| No products showing | Add new product with [+] |
| Data not saving | Check device storage |
| App crashes | Reinstall fresh from APK |
| Icons not visible | Clear app cache |
| Database empty | Load sample products |

---

## 📈 Making Good Decisions

### When to Reorder?
- Follow AI suggestion
- Check current vs minimum
- Look at demand trend

### When to Hold?
- Decreasing demand detected
- Stock above threshold
- AI suggests waiting

### When to Investigate?
- Loss-making products
- Sudden trend changes
- Unexpected sales spikes

---

## 📊 Dashboard At a Glance

**Healthy Business:** 🟢 Green cards, few ⚠️, Profit > 0
**Needs Attention:** 🔴 Red cards, multiple ⚠️, Profit < 0
**Okay:** 🟠 Mixed colors, manageable alerts

---

## 🚀 Workflow

```
1. Open App
   ↓
2. View Dashboard
   ↓
3. Check for ⚠️ alerts
   ↓
4. Review Collective Analysis
   ↓
5. Click on any product for details
   ↓
6. Act on AI suggestions
   ↓
7. Update sales data daily
   ↓
8. Repeat
```

---

## 🎯 Key Features

✅ See all products at once
✅ Get AI suggestion for each product
✅ Monitor overall business health
✅ Track 7-day sales trends
✅ Calculate profits/losses
✅ Get low stock alerts
✅ Analyze demand patterns
✅ Data persists locally

---

**Version:** 2.0.0
**Last Updated:** Dec 20, 2025
**For:** SmartStock AI App
