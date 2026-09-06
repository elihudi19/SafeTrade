import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Msingi wa mawasiliano na SafeTrade Backend (Django + DRF).
///
/// MUHIMU: [baseUrl] inabadilika kati ya mazingira (local dev, Render,
/// AWS baadaye) - HAIJAWEKWA HARD-CODE humu. Weka kupitia --dart-define
/// wakati wa kujenga app, mfano:
///   flutter run --dart-define=API_BASE_URL=https://safetrade-web.onrender.com/api
class ApiClient {
  static const String _defaultBaseUrl = "http://10.0.2.2:8000/api"; // Android emulator -> localhost
  static const String baseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: _defaultBaseUrl,
  );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {"Content-Type": "application/json"};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  Future<http.Response> get(String path, {bool auth = true}) async {
    return http.get(Uri.parse("$baseUrl$path"), headers: await _headers(auth: auth));
  }

  Future<http.Response> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    return http.post(
      Uri.parse("$baseUrl$path"),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
  }

  Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("access_token", access);
    await prefs.setString("refresh_token", refresh);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
  }
}
