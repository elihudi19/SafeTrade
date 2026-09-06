import 'dart:convert';
import 'api_client.dart';
import '../models/marketplace_listing.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../models/delivery_option.dart';

class MarketplaceService {
  final ApiClient _client = ApiClient();

  Future<List<MarketplaceListing>> listListings() async {
    final res = await _client.get("/marketplace-listings/");
    if (res.statusCode != 200) return [];
    final List data = jsonDecode(res.body);
    return data.map((e) => MarketplaceListing.fromJson(e)).toList();
  }

  Future<List<DeliveryOption>> listDeliveryOptions(String storeId) async {
    final res = await _client.get("/delivery-options/?store=$storeId");
    if (res.statusCode != 200) return [];
    final List data = jsonDecode(res.body);
    return data.map((e) => DeliveryOption.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> createCart() async {
    final res = await _client.post("/carts/", {});
    return {"statusCode": res.statusCode, "data": jsonDecode(res.body)};
  }

  Future<Cart?> getCart(String cartId) async {
    final res = await _client.get("/carts/$cartId/");
    if (res.statusCode != 200) return null;
    return Cart.fromJson(jsonDecode(res.body));
  }

  Future<List<Order>> listOrders() async {
    final res = await _client.get("/orders/");
    if (res.statusCode != 200) return [];
    final List data = jsonDecode(res.body);
    return data.map((e) => Order.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> confirmDelivery(String orderId) async {
    final res = await _client.post("/orders/$orderId/confirm-delivery/", {});
    return {"statusCode": res.statusCode, "data": jsonDecode(res.body)};
  }

  Future<Map<String, dynamic>> addItem(String cartId, String listingId, int quantity) async {
    final res = await _client.post(
      "/carts/$cartId/add-item/", {"listing": listingId, "quantity": quantity},
    );
    return {"statusCode": res.statusCode, "data": jsonDecode(res.body)};
  }

  Future<Map<String, dynamic>> checkout(String cartId, {String? deliveryOptionId, String? paymentMethod}) async {
    final res = await _client.post("/carts/$cartId/checkout/", {
      if (deliveryOptionId != null) "delivery_option": deliveryOptionId,
      if (paymentMethod != null) "payment_method": paymentMethod,
    });
    return {"statusCode": res.statusCode, "data": jsonDecode(res.body)};
  }
}
