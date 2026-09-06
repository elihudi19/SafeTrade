class Product {
  final String id;
  final String business;
  final String sku;
  final String name;
  final double unitPrice; // bei ya REJAREJA chaguo-msingi
  final double? wholesalePrice; // bei ya JUMLA chaguo-msingi (hiari)
  final double costPrice; // bei ya ununuzi ya sasa (inasasishwa na StockIntake)
  final int reorderLevel;
  final int leadTimeDays;

  Product({
    required this.id, required this.business, required this.sku,
    required this.name, required this.unitPrice, this.wholesalePrice,
    required this.costPrice, required this.reorderLevel, required this.leadTimeDays,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json["id"], business: json["business"], sku: json["sku"],
        name: json["name"], unitPrice: double.parse(json["unit_price"].toString()),
        wholesalePrice: json["wholesale_price"] != null
            ? double.tryParse(json["wholesale_price"].toString())
            : null,
        costPrice: double.tryParse(json["cost_price"]?.toString() ?? "0") ?? 0,
        reorderLevel: json["reorder_level"] ?? 0,
        leadTimeDays: json["lead_time_days"] ?? 3,
      );
}
