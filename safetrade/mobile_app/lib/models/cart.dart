class CartItem {
  final String id;
  final String listing;
  final int quantity;
  final String productName;
  final double unitPrice;
  final String? store;

  CartItem({
    required this.id, required this.listing, required this.quantity,
    required this.productName, required this.unitPrice, this.store,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json["id"], listing: json["listing"], quantity: json["quantity"],
        productName: json["product_name"] ?? "",
        unitPrice: double.tryParse(json["unit_price"].toString()) ?? 0,
        store: json["store"],
      );
}

class Cart {
  final String id;
  final List<CartItem> items;

  Cart({required this.id, required this.items});

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        id: json["id"],
        items: (json["items"] as List? ?? []).map((e) => CartItem.fromJson(e)).toList(),
      );

  double get total => items.fold(0, (sum, i) => sum + (i.quantity * i.unitPrice));
}
