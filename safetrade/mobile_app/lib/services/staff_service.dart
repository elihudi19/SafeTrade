import 'dart:convert';
import 'api_client.dart';

class StaffService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> createStaff({
    required String username,
    required String password,
    required String role, // storekeeper | cashier
    required String storeId,
    String phoneNumber = "",
  }) async {
    final res = await _client.post("/staff/", {
      "username": username, "password": password, "role": role,
      "store": storeId, "phone_number": phoneNumber,
    });
    return {"statusCode": res.statusCode, "data": jsonDecode(res.body)};
  }
}
