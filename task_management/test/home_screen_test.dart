import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_management/screens/home_screen.dart';
import 'package:task_management/providers/task_provider.dart';
import 'package:task_management/providers/theme_provider.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('HomeScreen should display three tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TaskProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Verify the tabs are present
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Repeated'), findsOneWidget);
    });

    testWidgets('HomeScreen should have add task button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TaskProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Verify the floating action button is present
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('HomeScreen should have export and settings buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TaskProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Verify the export and settings buttons are present
      expect(find.byIcon(Icons.download), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}