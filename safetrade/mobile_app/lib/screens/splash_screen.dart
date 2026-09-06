import 'package:flutter/material.dart';
import '../l10n/tr.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/branding/safetrade_logo.png", width: 220),
            const SizedBox(height: 16),
            Text(
              tr(context, "tagline"),
              style: const TextStyle(fontSize: 14, color: Colors.black54, letterSpacing: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}
