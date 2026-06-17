import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dark_theme_provider.dart';

class Utils {
  BuildContext context;
  Utils(this.context);
  bool get getTheme => Provider.of<DarkThemeProvider>(context).getDarkTheme;
  Color get color => getTheme ? Colors.white : Colors.black;
  Size get getScreenSize => MediaQuery.of(context).size;
}

/// Product catalog stores amounts in **Pakistani Rupees (PKR)**.
String formatPkr(num value) {
  final d = value.toDouble();
  final formatted = _withThousands(
    d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(2),
  );
  return 'PKR $formatted';
}

String _withThousands(String value) {
  final parts = value.split('.');
  final whole = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(whole[i]);
  }
  if (parts.length > 1) {
    buffer.write('.${parts[1]}');
  }
  return buffer.toString();
}
