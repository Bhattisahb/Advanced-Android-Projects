import '../models/demand_prediction_result.dart';

/// Service class containing all AI-based demand prediction logic
/// Uses simple rule-based algorithms to analyze sales trends
class DemandPredictionService {
  
  /// Analyzes product data and generates demand prediction
  /// 
  /// Parameters:
  /// - productName: Name of the product
  /// - last7DaysSales: List of sales quantities for last 7 days
  /// - currentStock: Current stock quantity
  /// - minimumStockThreshold: Minimum stock level before reordering
  /// - costPrice: Cost per unit
  /// - sellingPrice: Selling price per unit
  /// 
  /// Returns: DemandPredictionResult with AI analysis
  static DemandPredictionResult analyzeDemand({
    required String productName,
    required List<int> last7DaysSales,
    required int currentStock,
    required int minimumStockThreshold,
    required double costPrice,
    required double sellingPrice,
  }) {
    // ==========================================
    // 1. DEMAND TREND DETECTION LOGIC
    // ==========================================
    
    // Calculate average sales of first 3 days
    final firstThreeDaysAvg = 
        (last7DaysSales[0] + last7DaysSales[1] + last7DaysSales[2]) / 3;
    
    // Calculate average sales of last 3 days
    final lastThreeDaysAvg = 
        (last7DaysSales[4] + last7DaysSales[5] + last7DaysSales[6]) / 3;
    
    // Check if sales decreased continuously for last 4 days
    bool isContinuouslyDecreasing = 
        last7DaysSales[3] > last7DaysSales[4] &&
        last7DaysSales[4] > last7DaysSales[5] &&
        last7DaysSales[5] > last7DaysSales[6];
    
    // Determine demand trend
    String demandTrend = 'Stable';
    String suggestion = 'Sales are stable. Monitor regularly.';
    
    if (lastThreeDaysAvg > firstThreeDaysAvg) {
      // Demand is increasing
      demandTrend = 'Increasing';
      suggestion = 'This product is in high demand. Reorder stock immediately!';
    } else if (isContinuouslyDecreasing) {
      // Demand is decreasing
      demandTrend = 'Decreasing';
      suggestion = 'This product is slow-moving. Avoid reordering until demand recovers.';
    }
    
    // ==========================================
    // 2. LOW STOCK ALERT LOGIC
    // ==========================================
    
    bool lowStockAlert = currentStock < minimumStockThreshold;
    
    // If stock is low and demand is increasing, add urgent message
    if (lowStockAlert && demandTrend == 'Increasing') {
      suggestion = 'URGENT: Low stock + High demand! Reorder immediately!';
    }
    
    // ==========================================
    // 3. REORDER QUANTITY CALCULATION
    // ==========================================
    
    // Calculate average daily sales
    final averageDailySales = 
        last7DaysSales.reduce((a, b) => a + b) / last7DaysSales.length;
    
    // Formula: SuggestedReorderQty = (AverageDailySales × 7) - currentStock
    int suggestedReorderQty = 
        ((averageDailySales * 7) - currentStock).toInt();
    
    // Ensure quantity is never negative
    if (suggestedReorderQty < 0) {
      suggestedReorderQty = 0;
    }
    
    // ==========================================
    // 4. PROFIT ANALYSIS LOGIC
    // ==========================================
    
    // Total quantity sold in last 7 days
    final totalQuantitySold = last7DaysSales.reduce((a, b) => a + b);
    
    // Calculate profit: (SellingPrice - CostPrice) × TotalQuantitySold
    final profit = (sellingPrice - costPrice) * totalQuantitySold;
    
    // Check if product is causing loss
    bool isLosingMoney = profit < 0;
    
    // Add loss warning to suggestion if applicable
    if (isLosingMoney) {
      suggestion += '\n⚠️ Product is causing loss. Review pricing strategy.';
    }
    
    // ==========================================
    // 5. CREATE AND RETURN RESULT
    // ==========================================
    
    return DemandPredictionResult(
      demandTrend: demandTrend,
      suggestion: suggestion,
      lowStockAlert: lowStockAlert,
      suggestedReorderQty: suggestedReorderQty,
      profit: profit,
      averageDailySales: averageDailySales,
      totalSalesLast7Days: totalQuantitySold,
      isLosingMoney: isLosingMoney,
    );
  }
  
  /// Returns color code for demand trend indicator
  /// Green: Increasing, Red: Decreasing, Gray: Stable
  static String getTrendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'increasing':
        return '#4CAF50'; // Green
      case 'decreasing':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Gray for Stable
    }
  }
  
  /// Returns emoji indicator for demand trend
  static String getTrendEmoji(String trend) {
    switch (trend.toLowerCase()) {
      case 'increasing':
        return '📈'; // Upward trend
      case 'decreasing':
        return '📉'; // Downward trend
      default:
        return '➡️'; // Horizontal for stable
    }
  }
  
  /// Generates a detailed analysis report as text
  static String generateDetailedAnalysis({
    required String productName,
    required DemandPredictionResult result,
    required int currentStock,
    required int minimumStockThreshold,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('📊 DEMAND ANALYSIS REPORT');
    buffer.writeln('========================\n');
    
    buffer.writeln('Product: $productName');
    buffer.writeln('Trend: ${getTrendEmoji(result.demandTrend)} ${result.demandTrend}');
    buffer.writeln('Avg Daily Sales: ${result.averageDailySales.toStringAsFixed(2)} units');
    buffer.writeln('Total Sales (7 days): ${result.totalSalesLast7Days} units');
    buffer.writeln('Profit: PKR ${result.profit.toStringAsFixed(2)}');
    buffer.writeln('\n');
    
    buffer.writeln('📦 STOCK STATUS');
    buffer.writeln('===============');
    buffer.writeln('Current Stock: $currentStock units');
    buffer.writeln('Minimum Threshold: $minimumStockThreshold units');
    if (result.lowStockAlert) {
      buffer.writeln('⚠️ WARNING: Stock below minimum threshold!');
    } else {
      buffer.writeln('✓ Stock level is healthy');
    }
    buffer.writeln('Suggested Reorder Qty: ${result.suggestedReorderQty} units');
    buffer.writeln('\n');
    
    buffer.writeln('💡 RECOMMENDATION');
    buffer.writeln('=================');
    buffer.writeln(result.suggestion);
    
    return buffer.toString();
  }
}
