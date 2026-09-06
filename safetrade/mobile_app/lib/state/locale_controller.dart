import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Inasimamia lugha ya app (sw/en), inahifadhi chaguo la mtumiaji kwenye
/// kifaa ili libaki hata baada ya kufunga app.
class LocaleController extends ChangeNotifier {
  static const _prefKey = "app_locale";
  String _languageCode = "sw"; // Kiswahili ndiyo default (soko la Tanzania)

  String get languageCode => _languageCode;

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_prefKey) ?? "sw";
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (code != "sw" && code != "en") return;
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
  }

  Future<void> toggle() => setLanguage(_languageCode == "sw" ? "en" : "sw");
}
