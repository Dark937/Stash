import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  await storageService.init();

  runApp(StashApp(storageService: storageService));
}

class StashApp extends StatelessWidget {
  final StorageService storageService;

  const StashApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stash',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Dark by default as requested
      debugShowCheckedModeBanner: false,
      home: MainShell(storageService: storageService),
    );
  }
}
