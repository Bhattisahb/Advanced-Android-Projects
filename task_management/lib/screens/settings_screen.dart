import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedSound = 'default';
  bool _enableNotifications = true;
  final List<String> _availableSounds = ['default', 'bell', 'chime', 'ding'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSound = prefs.getString('notificationSound') ?? 'default';
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notificationSound', _selectedSound);
    await prefs.setBool('enableNotifications', _enableNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle dark/light theme'),
                value: themeProvider.darkMode,
                onChanged: (bool value) {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Show notifications for upcoming tasks'),
            value: _enableNotifications,
            onChanged: (bool value) {
              setState(() {
                _enableNotifications = value;
                _saveSettings();
              });
            },
          ),
          ListTile(
            title: const Text('Notification Sound'),
            subtitle: DropdownButton<String>(
              value: _selectedSound,
              isExpanded: true,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedSound = newValue;
                    _saveSettings();
                  });
                }
              },
              items: _availableSounds.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Task Management App v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Task Management',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 Your Name',
              );
            },
          ),
        ],
      ),
    );
  }
}