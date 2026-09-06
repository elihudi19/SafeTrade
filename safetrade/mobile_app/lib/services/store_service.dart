import 'dart:convert';
import 'api_client.dart';

class StoreService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> listStores() async {
    final res = await _client.get("/stores/");
    if (res.statusCode != 200) return [];
    final List data = jsonDecode(res.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createStore(String name, {String location = ""}) async {
    final res = await _client.post("/stores/", {"name": name, "location": location});
    return {"statusCode": res.statusCode, "data": jsonDecode(res.body)};
  }
}
