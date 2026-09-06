import 'package:flutter/material.dart';
import '../../services/marketplace_service.dart';
import '../../models/marketplace_listing.dart';
import '../../services/api_client.dart';
import '../../l10n/tr.dart';
import '../../widgets/language_switcher.dart';
import '../login_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _marketplaceService = MarketplaceService();
  List<MarketplaceListing> _listings = [];
  String? _cartId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final listings = await _marketplaceService.listListings();
    final cartResult = await _marketplaceService.createCart();
    setState(() {
      _listings = listings;
      _cartId = cartResult["data"]?["id"];
      _loading = false;
    });
  }

  Future<void> _addToCart(MarketplaceListing listing) async {
    if (_cartId == null) return;
    await _marketplaceService.addItem(_cartId!, listing.id, 1);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, "added_to_cart_message"))),
      );
    }
  }

  Future<void> _logout() async {
    await ApiClient().clearTokens();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, "marketplace_title")),
        actions: [
          const LanguageSwitcher(),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: _cartId == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => CartScreen(cartId: _cartId!)),
                    ),
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _listings.length,
              itemBuilder: (context, index) {
                final listing = _listings[index];
                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: listing.photo.isNotEmpty
                            ? Image.network(listing.photo, fit: BoxFit.cover)
                            : Container(color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(listing.description,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ElevatedButton(
                          onPressed: () => _addToCart(listing),
                          child: Text(tr(context, "add_to_cart_button")),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
