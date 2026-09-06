import 'dart:convert';
import 'api_client.dart';

class DashboardService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>?> ownerOverview() async {
    final res = await _client.get("/dashboard/store-overview/");
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body);
  }
}
