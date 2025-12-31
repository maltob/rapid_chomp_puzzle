import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'features/menu/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable full immersive mode on mobile
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final storageService = await StorageService.init();

  runApp(
    Provider<StorageService>.value(
      value: storageService,
      child: const ChompPuzzleApp(),
    ),
  );
}

class ChompPuzzleApp extends StatelessWidget {
  const ChompPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chomp Puzzle',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainMenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
