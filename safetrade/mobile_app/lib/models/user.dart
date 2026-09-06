class AppUser {
  final String id;
  final String username;
  final String role; // owner, storekeeper, cashier, customer, super_admin
  final String? store;
  final String phoneNumber;
  final bool isActive;

  AppUser({
    required this.id,
    required this.username,
    required this.role,
    this.store,
    required this.phoneNumber,
    required this.isActive,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json["id"],
        username: json["username"],
        role: json["role"],
        store: json["store"],
        phoneNumber: json["phone_number"] ?? "",
        isActive: json["is_active"] ?? true,
      );
}
