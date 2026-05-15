import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class BtVolumeProApp extends StatefulWidget {
  const BtVolumeProApp({super.key});

  @override
  State<BtVolumeProApp> createState() => _BtVolumeProAppState();
}

class _BtVolumeProAppState extends State<BtVolumeProApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BT Volume Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
