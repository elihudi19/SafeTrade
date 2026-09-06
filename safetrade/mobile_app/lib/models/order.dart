class OrderItem {
  final String productName;
  final int quantity;
  final double unitPrice;

  OrderItem({required this.productName, required this.quantity, required this.unitPrice});

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productName: json["product_name"] ?? "", quantity: json["quantity"],
        unitPrice: double.tryParse(json["unit_price"].toString()) ?? 0,
      );
}

class Order {
  final String id;
  final String status;
  final double totalAmount;
  final double deliveryFee;
  final String createdAt;
  final String? deliveryOptionKind; // pickup | free | bolt | custom | null
  final String? deliveryStatus; // requested | driver_assigned | picked_up | delivered | failed | null
  final List<OrderItem> items;

  Order({
    required this.id, required this.status, required this.totalAmount,
    required this.deliveryFee, required this.createdAt, this.deliveryOptionKind,
    this.deliveryStatus, required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json["id"], status: json["status"],
        totalAmount: double.tryParse(json["total_amount"].toString()) ?? 0,
        deliveryFee: double.tryParse(json["delivery_fee"].toString()) ?? 0,
        createdAt: json["created_at"] ?? "",
        deliveryOptionKind: json["delivery_option_kind"],
        deliveryStatus: json["delivery_status"],
        items: (json["items"] as List? ?? []).map((e) => OrderItem.fromJson(e)).toList(),
      );

  /// Kitufe cha "Nimepokea Mzigo" kinaonekana tu kama kuna delivery HALISI
  /// (siyo Pickup) na bado haijathibitishwa kupokelewa.
  bool get canConfirmDelivery =>
      deliveryOptionKind != null &&
      deliveryOptionKind != "pickup" &&
      deliveryStatus != null &&
      deliveryStatus != "delivered";
}
