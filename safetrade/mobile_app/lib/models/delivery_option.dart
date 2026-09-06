class DeliveryOption {
  final String id;
  final String store;
  final String kind; // free | bolt | custom
  final double? customFlatFee;

  DeliveryOption({
    required this.id, required this.store, required this.kind, this.customFlatFee,
  });

  factory DeliveryOption.fromJson(Map<String, dynamic> json) => DeliveryOption(
        id: json["id"], store: json["store"], kind: json["kind"],
        customFlatFee: json["custom_flat_fee"] != null
            ? double.tryParse(json["custom_flat_fee"].toString())
            : null,
      );

  String get label {
    switch (kind) {
      case "free":
        return "Delivery Bure";
      case "bolt":
        return "Bolt (kulingana na umbali)";
      case "custom":
        return "Delivery ya Duka — TZS ${customFlatFee?.toStringAsFixed(0) ?? '0'}";
      default:
        return kind;
    }
  }
}
