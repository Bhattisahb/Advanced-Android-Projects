/// Model class to hold demand prediction results
/// Contains all AI analysis outputs for a product
class DemandPredictionResult {
  /// The trend of demand: "Increasing", "Decreasing", or "Stable"
  final String demandTrend;

  /// AI-generated suggestion for the business
  final String suggestion;

  /// Flag indicating if current stock is below minimum threshold
  final bool lowStockAlert;

  /// Quantity recommended to reorder
  final int suggestedReorderQty;

  /// Total profit generated from this product
  final double profit;

  /// Average daily sales for the product
  final double averageDailySales;

  /// Total sales in last 7 days
  final int totalSalesLast7Days;

  /// Flag indicating if product is causing loss
  final bool isLosingMoney;

  DemandPredictionResult({
    required this.demandTrend,
    required this.suggestion,
    required this.lowStockAlert,
    required this.suggestedReorderQty,
    required this.profit,
    required this.averageDailySales,
    required this.totalSalesLast7Days,
    required this.isLosingMoney,
  });

  /// Convert to JSON for storage or API communication
  Map<String, dynamic> toJson() {
    return {
      'demandTrend': demandTrend,
      'suggestion': suggestion,
      'lowStockAlert': lowStockAlert,
      'suggestedReorderQty': suggestedReorderQty,
      'profit': profit,
      'averageDailySales': averageDailySales,
      'totalSalesLast7Days': totalSalesLast7Days,
      'isLosingMoney': isLosingMoney,
    };
  }

  /// Create from JSON
  factory DemandPredictionResult.fromJson(Map<String, dynamic> json) {
    return DemandPredictionResult(
      demandTrend: json['demandTrend'] ?? 'Stable',
      suggestion: json['suggestion'] ?? '',
      lowStockAlert: json['lowStockAlert'] ?? false,
      suggestedReorderQty: json['suggestedReorderQty'] ?? 0,
      profit: (json['profit'] ?? 0).toDouble(),
      averageDailySales: (json['averageDailySales'] ?? 0).toDouble(),
      totalSalesLast7Days: json['totalSalesLast7Days'] ?? 0,
      isLosingMoney: json['isLosingMoney'] ?? false,
    );
  }
}
