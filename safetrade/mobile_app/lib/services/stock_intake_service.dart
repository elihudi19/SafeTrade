import 'dart:convert';
import 'api_client.dart';
import '../models/stock_intake.dart';

class StockIntakeService {
  final ApiClient _client = ApiClient();

  /// Storekeeper anaandika mzigo mpya. Kama ni bundle/kifungu, weka
  /// bundleCostPrice + unitsPerBundle (unitCostPrice inapuuzwa). Vinginevyo
  /// weka unitCostPrice moja kwa moja.
  Future<Map<String, dynamic>> recordIntake({
    required String productId,
    required int quantityReceived,
    required bool isBundlePurchase,
    int unitsPerBundle = 1,
    double? bundleCostPrice,
    double? unitCostPrice,
    double transportCost = 0,
    double otherCosts = 0,
  }) async {
    final res = await _client.post("/stock-intakes/", {
      "product": productId,
      "quantity_received": quantityReceived,
      "is_bundle_purchase": isBundlePurchase,
      "units_per_bundle": unitsPerBundle,
      if (bundleCostPrice != null) "bundle_cost_price": bundleCostPrice,
      if (unitCostPrice != null) "unit_cost_price": unitCostPrice,
      "transport_cost": transportCost,
      "other_costs": otherCosts,
    });
    return {"statusCode": res.statusCode, "data": jsonDecode(res.body)};
  }

  Future<List<StockIntake>> listIntakes() async {
    final res = await _client.get("/stock-intakes/");
    if (res.statusCode != 200) return [];
    final List data = jsonDecode(res.body);
    return data.map((e) => StockIntake.fromJson(e)).toList();
  }
}
