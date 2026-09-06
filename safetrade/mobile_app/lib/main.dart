import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/connectivity_watcher.dart';
import 'state/locale_controller.dart';

void main() {
  ConnectivityWatcher.start();
  runApp(const SafeTradeApp());
}

class SafeTradeApp extends StatelessWidget {
  const SafeTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleController()..loadSaved(),
      child: MaterialApp(
        title: "SafeTrade",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF1E6091), // rangi ya logo (bluu)
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
