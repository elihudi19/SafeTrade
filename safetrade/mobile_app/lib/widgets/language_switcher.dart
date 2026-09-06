import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/locale_controller.dart';

/// Kitufe kidogo cha kubadilisha lugha (SW/EN) - kinawekwa kwenye AppBar
/// ya kila screen kuu. Kubonyeza kunabadilisha lugha MARA MOJA kote
/// kwenye app (Provider inasambaza mabadiliko papo hapo).
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    return TextButton(
      onPressed: () => controller.toggle(),
      child: Text(
        controller.languageCode == "sw" ? "EN" : "SW",
        style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14,
        ),
      ),
    );
  }
}
