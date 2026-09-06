class MarketplaceListing {
  final String id;
  final String product;
  final String store;
  final String photo;
  final String description;

  MarketplaceListing({
    required this.id, required this.product, required this.store,
    required this.photo, required this.description,
  });

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) => MarketplaceListing(
        id: json["id"], product: json["product"], store: json["store"],
        photo: json["photo"] ?? "", description: json["description"] ?? "",
      );
}
