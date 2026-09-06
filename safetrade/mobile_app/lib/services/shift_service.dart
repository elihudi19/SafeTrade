import 'dart:convert';
import 'api_client.dart';
import '../models/shift.dart';
import '../models/receipt.dart';

class ShiftService {
  final ApiClient _client = ApiClient();

  /// Inarudisha Shift inayoendelea, au null kama hakuna (404).
  Future<Shift?> activeShift() async {
    final res = await _client.get("/shifts/active/");
    if (res.statusCode != 200) return null;
    return Shift.fromJson(jsonDecode(res.body));
  }

  Future<Map<String, dynamic>> clockIn() async {
    final res = await _client.post("/shifts/clock-in/", {});
    return {"statusCode": res.statusCode, "data": jsonDecode(res.body)};
  }

  Future<Map<String, dynamic>> clockOut(String shiftId) async {
    final res = await _client.post("/shifts/$shiftId/clock-out/", {});
    return {"statusCode": res.statusCode, "data": jsonDecode(res.body)};
  }

  Future<List<Receipt>> currentShiftHistory() async {
    final res = await _client.get("/shifts/current-history/");
    if (res.statusCode != 200) return [];
    final List data = jsonDecode(res.body);
    return data.map((e) => Receipt.fromJson(e)).toList();
  }
}
