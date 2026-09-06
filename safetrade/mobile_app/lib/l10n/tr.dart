import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/locale_controller.dart';
import 'app_strings.dart';

/// Helper kuu ya tafsiri - tumia hivi kila mahali badala ya Text ngumu:
///   Text(tr(context, 'login_button'))
///
/// Kama key haipo kwenye kamusi, inarudisha key yenyewe (badala ya
/// kung'oa app) ili iwe rahisi kuona neno gani halijaongezwa bado.
String tr(BuildContext context, String key) {
  final locale = context.watch<LocaleController>().languageCode;
  final entry = appStrings[key];
  if (entry == null) return key;
  return entry[locale] ?? entry["sw"] ?? key;
}
