# SmartStock AI - Dashboard Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────┐
│                   USER INTERFACE                    │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │         APPLICATION SCREEN                   │  │
│  │  ┌────────────────────────────────────────┐  │  │
│  │  │ Header Bar [+] [≡]                    │  │  │
│  │  └────────────────────────────────────────┘  │  │
│  │  ┌────────────────────────────────────────┐  │  │
│  │  │ Introduction Section                  │  │  │
│  │  └────────────────────────────────────────┘  │  │
│  │  ┌────────────────────────────────────────┐  │  │
│  │  │ Products Overview                     │  │  │
│  │  │ ┌──────────────────────────────────┐  │  │  │
│  │  │ │ Product Card 1                 │  │  │  │
│  │  │ │ - Name & Status               │  │  │  │
│  │  │ │ - Trend & Alert               │  │  │  │
│  │  │ │ - Metrics                     │  │  │  │
│  │  │ │ - AI Suggestion               │  │  │  │
│  │  │ │ - [✏️] [🗑️] [Details]         │  │  │  │
│  │  │ └──────────────────────────────────┘  │  │  │
│  │  │ ┌──────────────────────────────────┐  │  │  │
│  │  │ │ Product Card 2                 │  │  │  │
│  │  │ │ ...                            │  │  │  │
│  │  │ └──────────────────────────────────┘  │  │  │
│  │  └────────────────────────────────────────┘  │  │
│  │  ┌────────────────────────────────────────┐  │  │
│  │  │ Collective Analysis                   │  │  │
│  │  │ - Total Inventory                     │  │  │
│  │  │ - Inventory Health                    │  │  │
│  │  │ - Total Revenue                       │  │  │
│  │  │ - Avg Daily Sales                     │  │  │
│  │  │ - Low Stock Alerts                    │  │  │
│  │  │ - Market Trends                       │  │  │
│  │  └────────────────────────────────────────┘  │  │
│  │  ┌────────────────────────────────────────┐  │  │
│  │  │ Detail Modal (when clicked)           │  │  │
│  │  │ - All metrics                         │  │  │
│  │  │ - Sales chart                         │  │  │
│  │  │ - Analysis text                       │  │  │
│  │  └────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────┐
│              BUSINESS LOGIC LAYER                   │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  Demand Prediction Service                  │  │
│  │  - Analyze demand trend                     │  │
│  │  - Calculate stock alerts                   │  │
│  │  - Compute reorder quantity                 │  │
│  │  - Analyze profit/loss                      │  │
│  │  - Generate suggestions                     │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────┐
│             DATA PERSISTENCE LAYER                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  Database Helper (SQLite)                   │  │
│  │  - Save Product                             │  │
│  │  - Get All Products                         │  │
│  │  - Delete Product                           │  │
│  │  - Update Product                           │  │
│  │  - Database Initialization                  │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  SQLite Database (smartstock.db)            │  │
│  │  - Products Table                           │  │
│  │  - Product Data                             │  │
│  │  - Timestamps                               │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────┐
│          LOCAL DEVICE STORAGE                       │
├─────────────────────────────────────────────────────┤
│  /data/data/com.example.smart_stock_app/databases  │
│  └─ smartstock.db (SQLite database file)           │
└─────────────────────────────────────────────────────┘
```

---

## Data Flow Diagram

```
USER ACTION
    ↓
┌─────────────────┐
│  Add Product    │ ← User clicks "+" button
│  or             │ ← Fill form with data
│  Edit Product   │ ← Click "Save"
│  or             │
│  Delete Product │
└─────────────────┘
    ↓
┌──────────────────┐
│  Validate Input  │
│  - Check name    │
│  - Check sales   │
│  - Check prices  │
└──────────────────┘
    ↓
┌──────────────────┐
│  Save to         │
│  Database        │
└──────────────────┘
    ↓
┌──────────────────┐
│  Update Product  │
│  Map in Memory   │
└──────────────────┘
    ↓
┌──────────────────┐
│  Trigger         │
│  _updatePrediction│
└──────────────────┘
    ↓
┌──────────────────┐
│  Analyze with AI │
│  (Demand        │
│   Prediction    │
│   Service)      │
└──────────────────┘
    ↓
┌──────────────────┐
│  setState()      │
│  Rebuild UI      │
└──────────────────┘
    ↓
┌──────────────────┐
│  Display Updated │
│  Dashboard       │
└──────────────────┘
```

---

## Product Card Component Structure

```
┌─────────────────────────────────────────────┐
│  Product Card                               │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────────────────────┐           │
│  │ [Product Name]         [✏️][🗑️] │          │
│  └──────────────────────────────┘           │
│                                             │
│  ┌──────────────────────────────┐           │
│  │ Status: [Badge] [Badge]      │          │
│  └──────────────────────────────┘           │
│                                             │
│  ┌──────────────────────────────┐           │
│  │ [Stock] [Avg Sales] [Profit] │          │
│  │   50      56.1 units    28K  │          │
│  └──────────────────────────────┘           │
│                                             │
│  ┌──────────────────────────────┐           │
│  │ 💡 Suggestion Box            │          │
│  │ "AI recommendation text"     │          │
│  └──────────────────────────────┘           │
│                                             │
│  ┌──────────────────────────────┐           │
│  │ [View Detailed Analysis]     │          │
│  └──────────────────────────────┘           │
│                                             │
└─────────────────────────────────────────────┘
```

---

## Collective Analysis Component Structure

```
┌───────────────────────────────────────────┐
│  Collective Analysis Section              │
├───────────────────────────────────────────┤
│                                           │
│  ┌─────────────────┐ ┌─────────────────┐ │
│  │  Total Stock    │ │  Health Status  │ │
│  │                 │ │                 │ │
│  │  345 units      │ │  Low ⚠️         │ │
│  └─────────────────┘ └─────────────────┘ │
│                                           │
│  ┌─────────────────┐ ┌─────────────────┐ │
│  │ Total Revenue   │ │ Avg Daily Sales │ │
│  │                 │ │                 │ │
│  │ PKR 150,000 💰  │ │ 225.3 units 📈  │ │
│  └─────────────────┘ └─────────────────┘ │
│                                           │
│  ┌───────────────────────────────────────┐ │
│  │ ⚠️ LOW STOCK ALERT                    │ │
│  │ 2 product(s) have low stock          │ │
│  └───────────────────────────────────────┘ │
│                                           │
│  ┌───────────────────────────────────────┐ │
│  │ 📊 MARKET TRENDS                      │ │
│  │                                       │ │
│  │ Increasing: 2  │  Stable: 1          │ │
│  │ Decreasing: 1                        │ │
│  └───────────────────────────────────────┘ │
│                                           │
└───────────────────────────────────────────┘
```

---

## Database Schema Diagram

```
┌────────────────────────────────────┐
│        PRODUCTS TABLE              │
├────────────────────────────────────┤
│                                    │
│ id: INTEGER (PK, AutoInc)          │
│ ├─ 1, 2, 3, ...                    │
│                                    │
│ name: TEXT (UNIQUE)                │
│ ├─ "Rice (10kg)"                   │
│ ├─ "Wheat Flour (5kg)"             │
│ └─ "Cooking Oil (1L)"              │
│                                    │
│ last7DaysSales: TEXT               │
│ ├─ "45,42,40,55,60,65,68"          │
│ └─ (comma-separated values)        │
│                                    │
│ currentStock: INTEGER              │
│ ├─ 50, 200, 80, ...                │
│                                    │
│ minimumThreshold: INTEGER          │
│ ├─ 100, 150, 50, ...               │
│                                    │
│ costPrice: REAL                    │
│ ├─ 1200.0, 250.0, 150.0, ...       │
│                                    │
│ sellingPrice: REAL                 │
│ ├─ 1500.0, 400.0, 250.0, ...       │
│                                    │
│ createdAt: TIMESTAMP               │
│ ├─ 2025-12-20 10:30:45             │
│ └─ (auto-generated)                │
│                                    │
└────────────────────────────────────┘
```

---

## UI State Management

```
┌─────────────────────────────────────┐
│    _DemandPredictionScreenState     │
├─────────────────────────────────────┤
│                                     │
│  products: Map<String, Map>         │
│  ├─ Rice → {sales, stock, ...}      │
│  ├─ Wheat → {sales, stock, ...}     │
│  └─ Oil → {sales, stock, ...}       │
│                                     │
│  selectedProduct: String            │
│  ├─ Current selected product        │
│  └─ For individual analysis         │
│                                     │
│  predictionResult: Result           │
│  ├─ Demand trend                    │
│  ├─ Stock alerts                    │
│  ├─ Profit/loss                     │
│  └─ Suggestions                     │
│                                     │
│  Methods:                           │
│  ├─ _loadProductsFromDatabase()     │
│  ├─ _updatePrediction()             │
│  ├─ _saveProductData()              │
│  ├─ _deleteProduct()                │
│  ├─ _showDataInputDialog()          │
│  ├─ _showProductsManagement()       │
│  ├─ _showProductDetails()           │
│  ├─ _buildProductCardsSection()     │
│  ├─ _buildProductCard()             │
│  └─ _buildCollectiveAnalysisSection()│
│                                     │
└─────────────────────────────────────┘
```

---

## Integration Points

```
┌──────────────────┐
│  Flutter App     │
└────────┬─────────┘
         │
         ├─→ Material Package (UI)
         │
         ├─→ sqflite Package (Database)
         │
         ├─→ path Package (Storage)
         │
         └─→ Custom Services
            ├─ DemandPredictionService (AI)
            └─ DatabaseHelper (Data)
```

---

**Architecture designed for scalability, maintainability, and user experience.**
