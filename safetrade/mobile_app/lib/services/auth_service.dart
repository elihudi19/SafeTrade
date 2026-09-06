import 'dart:convert';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _client.post(
      "/auth/login/", {"username": username, "password": password}, auth: false,
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      await _client.saveTokens(data["access"], data["refresh"]);
    }
    return {"statusCode": res.statusCode, "data": data};
  }

  /// Hatua 1: Owner anajisajili kwa NIDA + namba ya simu (SIYO leseni).
  Future<Map<String, dynamic>> registerOwner({
    required String username,
    required String password,
    required String nidaNumber,
    required String phoneNumber,
    required String businessName,
  }) async {
    final res = await _client.post("/auth/register-owner/", {
      "username": username,
      "password": password,
      "nida_number": nidaNumber,
      "phone_number": phoneNumber,
      "business_name": businessName,
    }, auth: false);
    return {"statusCode": res.statusCode, "data": jsonDecode(res.body)};
  }

  /// Hatua 2: Owner anaingiza OTP aliyopokea kwa SMS.
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String code) async {
    final res = await _client.post("/auth/verify-otp/", {
      "phone_number": phoneNumber,
      "code": code,
    }, auth: false);
    return {"statusCode": res.statusCode, "data": jsonDecode(res.body)};
  }

  Future<Map<String, dynamic>> resendOtp(String phoneNumber) async {
    final res = await _client.post(
      "/auth/resend-otp/", {"phone_number": phoneNumber}, auth: false,
    );
    return {"statusCode": res.statusCode, "data": jsonDecode(res.body)};
  }
}
