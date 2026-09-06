class ReceiptItemInput {
  final String product;
  final int quantity;
  final double unitPrice;
  final String saleType; // retail | wholesale

  ReceiptItemInput({
    required this.product, required this.quantity, required this.unitPrice,
    this.saleType = "retail",
  });

  Map<String, dynamic> toJson() => {
        "product": product, "quantity": quantity, "unit_price": unitPrice,
        "sale_type": saleType,
      };
}

class Receipt {
  final String id;
  final String localUuid;
  final double totalAmount;
  final String paymentMethod;
  final String receiptSource;
  final bool createdOffline;
  final String createdAt;
  final double totalCostOfGoods;
  final double grossProfit;

  Receipt({
    required this.id, required this.localUuid, required this.totalAmount,
    required this.paymentMethod, required this.receiptSource,
    required this.createdOffline, required this.createdAt,
    this.totalCostOfGoods = 0, this.grossProfit = 0,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        id: json["id"] ?? "", localUuid: json["local_uuid"],
        totalAmount: double.tryParse(json["total_amount"].toString()) ?? 0,
        paymentMethod: json["payment_method"], receiptSource: json["receipt_source"],
        createdOffline: json["created_offline"] ?? false,
        createdAt: json["created_at"] ?? "",
        totalCostOfGoods: double.tryParse(json["total_cost_of_goods"]?.toString() ?? "0") ?? 0,
        grossProfit: double.tryParse(json["gross_profit"]?.toString() ?? "0") ?? 0,
      );
}
