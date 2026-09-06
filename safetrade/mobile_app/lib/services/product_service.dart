import 'dart:convert';
import 'api_client.dart';
import '../models/product.dart';
import '../models/shelf_stock.dart';

class ProductService {
  final ApiClient _client = ApiClient();

  Future<List<Product>> listProducts() async {
    final res = await _client.get("/products/");
    if (res.statusCode != 200) return [];
    final List data = jsonDecode(res.body);
    return data.map((e) => Product.fromJson(e)).toList();
  }

  Future<List<ShelfStock>> listShelfStock() async {
    final res = await _client.get("/shelf-stock/");
    if (res.statusCode != 200) return [];
    final List data = jsonDecode(res.body);
    return data.map((e) => ShelfStock.fromJson(e)).toList();
  }
}
