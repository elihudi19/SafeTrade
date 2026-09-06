class ShelfStock {
  final String id;
  final String store;
  final String product;
  final String productName;
  final String locationType; // warehouse | counter
  final int quantity;

  ShelfStock({
    required this.id, required this.store, required this.product,
    required this.productName, required this.locationType, required this.quantity,
  });

  factory ShelfStock.fromJson(Map<String, dynamic> json) => ShelfStock(
        id: json["id"], store: json["store"], product: json["product"],
        productName: json["product_name"] ?? "", locationType: json["location_type"],
        quantity: json["quantity"] ?? 0,
      );
}
