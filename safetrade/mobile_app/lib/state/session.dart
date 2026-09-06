import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import 'dart:convert';

/// Session ya mtumiaji aliyeingia - inatumika kuelekeza (route) kwenye
/// dashboard sahihi kulingana na role (Owner/Storekeeper/Cashier/Customer).
class Session extends ChangeNotifier {
  AppUser? currentUser;
  final ApiClient _client = ApiClient();

  Future<bool> loadCurrentUser() async {
    final res = await _client.get("/auth/me/");
    if (res.statusCode == 200) {
      currentUser = AppUser.fromJson(jsonDecode(res.body));
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _client.clearTokens();
    currentUser = null;
    notifyListeners();
  }
}
