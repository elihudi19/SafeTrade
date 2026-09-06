import 'dart:convert';
import 'api_client.dart';
import '../models/predictive_alert.dart';

class PredictiveAlertService {
  final ApiClient _client = ApiClient();

  Future<List<PredictiveAlert>> listAlerts() async {
    final res = await _client.get("/predictive-alerts/");
    if (res.statusCode != 200) return [];
    final List data = jsonDecode(res.body);
    return data.map((e) => PredictiveAlert.fromJson(e)).toList();
  }

  Future<void> recompute() async {
    await _client.post("/predictive-alerts/recompute/", {});
  }

  Future<void> acknowledge(String alertId) async {
    await _client.post("/predictive-alerts/$alertId/acknowledge/", {});
  }
}
