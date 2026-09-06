class StockTransfer {
  final String id;
  final String product;
  final int quantitySent;
  final int? quantityReceived;
  final String status; // pending_transfer | accepted | rejected
  final String createdAt;

  StockTransfer({
    required this.id, required this.product, required this.quantitySent,
    this.quantityReceived, required this.status, required this.createdAt,
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) => StockTransfer(
        id: json["id"], product: json["product"], quantitySent: json["quantity_sent"],
        quantityReceived: json["quantity_received"], status: json["status"],
        createdAt: json["created_at"] ?? "",
      );
}
