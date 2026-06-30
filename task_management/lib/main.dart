import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
// task_detail_screen not used here
import 'services/notification_service.dart';

import 'services/database_service.dart';
import 'screens/add_edit_task_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  // Listen for notification taps and navigate to the task edit screen
  NotificationService().onNotificationClick.listen((payload) async {
    if (payload != null) {
      final int? taskId = int.tryParse(payload);
      if (taskId != null) {
        final task = await DatabaseService.instance.readTask(taskId);
        if (task != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => AddEditTaskScreen(task: task),
            ),
          );
        }
      }
    }
  });
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Task Management',
          navigatorKey: navigatorKey,
          theme: themeProvider.themeData,
          home: const HomeScreen(),
        );
      },
    );
  }
}
