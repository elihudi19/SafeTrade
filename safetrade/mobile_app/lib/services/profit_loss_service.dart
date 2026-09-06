import 'dart:convert';
import 'api_client.dart';

class ProfitLossService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>?> getReport(String storeId, {String period = "daily"}) async {
    final res = await _client.get("/reports/profit-loss/?store=$storeId&period=$period");
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body);
  }
}
