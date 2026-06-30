import 'package:flutter/material.dart';

/// Widget to display sales trend as a simple line chart
/// Shows last 7 days sales data in an easy-to-understand visual format
class SalesTrendChart extends StatelessWidget {
  /// List of sales quantities for the last 7 days
  final List<int> last7DaysSales;
  
  /// Name of the product (displayed in title)
  final String productName;

  const SalesTrendChart({
    Key? key,
    required this.last7DaysSales,
    required this.productName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get max value for scaling
    final maxSales = last7DaysSales.isNotEmpty 
        ? last7DaysSales.reduce((a, b) => a > b ? a : b)
        : 1;
    
    // Add some padding to the max value for better visualization
    final scaledMax = (maxSales * 1.2).toInt();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              '📈 Sales Trend - Last 7 Days',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Chart Area
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  last7DaysSales.length,
                  (index) => _BarColumn(
                    dayNumber: index + 1,
                    value: last7DaysSales[index],
                    maxValue: scaledMax,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBox(
                  label: 'Highest',
                  value: maxSales.toString(),
                  color: Colors.green,
                ),
                _StatBox(
                  label: 'Average',
                  value: (last7DaysSales.reduce((a, b) => a + b) / 
                      last7DaysSales.length).toStringAsFixed(1),
                  color: Colors.blue,
                ),
                _StatBox(
                  label: 'Total',
                  value: last7DaysSales.reduce((a, b) => a + b).toString(),
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget representing a single bar in the chart
class _BarColumn extends StatelessWidget {
  final int dayNumber;
  final int value;
  final int maxValue;

  const _BarColumn({
    required this.dayNumber,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate height percentage
    final heightPercentage = value / maxValue;
    
    return Expanded(
      child: Tooltip(
        message: 'Day $dayNumber: $value units',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Value label on top
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            
            // Bar
            Expanded(
              flex: (heightPercentage * 100).toInt(),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _getBarColor(dayNumber),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
            
            // Day label at bottom
            const SizedBox(height: 4),
            Text(
              'D$dayNumber',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns color gradient based on day position
  Color _getBarColor(int day) {
    if (day <= 3) {
      // First 3 days - Blue (baseline)
      return Colors.blue.withOpacity(0.6);
    } else if (day <= 5) {
      // Middle days - Purple (transition)
      return Colors.purple.withOpacity(0.6);
    } else {
      // Last 3 days - Green (recent trend)
      return Colors.green.withOpacity(0.6);
    }
  }
}

/// Widget to display statistics
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
