class StockIntake {
  final String id;
  final String productName;
  final int quantityReceived;
  final double unitCostPrice;
  final double transportCost;
  final double otherCosts;
  final double totalCost;
  final double suggestedMinSellingPrice;
  final String createdAt;

  StockIntake({
    required this.id, required this.productName, required this.quantityReceived,
    required this.unitCostPrice, required this.transportCost, required this.otherCosts,
    required this.totalCost, required this.suggestedMinSellingPrice, required this.createdAt,
  });

  factory StockIntake.fromJson(Map<String, dynamic> json) => StockIntake(
        id: json["id"], productName: json["product_name"] ?? "",
        quantityReceived: json["quantity_received"],
        unitCostPrice: double.tryParse(json["unit_cost_price"].toString()) ?? 0,
        transportCost: double.tryParse(json["transport_cost"].toString()) ?? 0,
        otherCosts: double.tryParse(json["other_costs"].toString()) ?? 0,
        totalCost: double.tryParse(json["total_cost"].toString()) ?? 0,
        suggestedMinSellingPrice: double.tryParse(json["suggested_min_selling_price"].toString()) ?? 0,
        createdAt: json["created_at"] ?? "",
      );
}
