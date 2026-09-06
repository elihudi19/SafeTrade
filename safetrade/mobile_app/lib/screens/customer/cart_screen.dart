import 'package:flutter/material.dart';
import '../../services/marketplace_service.dart';
import '../../models/cart.dart';
import '../../models/delivery_option.dart';
import '../../l10n/tr.dart';
import '../../widgets/language_switcher.dart';
import 'order_history_screen.dart';

const String _pickupOptionId = "__pickup__"; // synthetic - siyo DeliveryOption ya database

class CartScreen extends StatefulWidget {
  final String cartId;
  const CartScreen({super.key, required this.cartId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _marketplaceService = MarketplaceService();
  Cart? _cart;
  List<DeliveryOption> _deliveryOptions = [];
  String _selectedOptionId = _pickupOptionId;
  bool _loading = true;
  bool _checkingOut = false;
  String _paymentMethod = "mpesa";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cart = await _marketplaceService.getCart(widget.cartId);
    List<DeliveryOption> options = [];
    if (cart != null && cart.items.isNotEmpty && cart.items.first.store != null) {
      options = await _marketplaceService.listDeliveryOptions(cart.items.first.store!);
    }
    setState(() {
      _cart = cart;
      _deliveryOptions = options;
      _loading = false;
    });
  }

  DeliveryOption? get _selectedOption {
    if (_selectedOptionId == _pickupOptionId) return null;
    try {
      return _deliveryOptions.firstWhere((o) => o.id == _selectedOptionId);
    } catch (_) {
      return null;
    }
  }

  double get _deliveryFee {
    final option = _selectedOption;
    if (option == null) return 0;
    if (option.kind == "custom") return option.customFlatFee ?? 0;
    return 0;
  }

  bool get _isBoltSelected => _selectedOption?.kind == "bolt";

  Future<void> _checkout() async {
    setState(() => _checkingOut = true);
    final result = await _marketplaceService.checkout(
      widget.cartId,
      paymentMethod: _paymentMethod,
      deliveryOptionId: _selectedOptionId == _pickupOptionId ? null : _selectedOptionId,
    );
    setState(() => _checkingOut = false);

    if (result["statusCode"] == 201) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${tr(context, "checkout_failed_message")}: ${result["data"]}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart?.items ?? [];
    final allOptions = <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: _pickupOptionId,
        child: Text(tr(context, "pickup_option_label")),
      ),
      ..._deliveryOptions.map((o) => DropdownMenuItem(value: o.id, child: Text(o.label))),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, "cart_title")),
        actions: const [LanguageSwitcher(), SizedBox(width: 8)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: items.isEmpty
                      ? Center(child: Text(tr(context, "cart_empty_message")))
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              title: Text(item.productName),
                              subtitle: Text("${item.quantity} x TZS ${item.unitPrice}"),
                              trailing: Text(
                                "TZS ${(item.quantity * item.unitPrice).toStringAsFixed(0)}",
                              ),
                            );
                          },
                        ),
                ),
                if (items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedOptionId,
                          decoration: InputDecoration(labelText: tr(context, "delivery_type_label")),
                          items: allOptions,
                          onChanged: (v) => setState(() => _selectedOptionId = v!),
                        ),
                        if (_isBoltSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              tr(context, "bolt_note"),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          "${tr(context, "product_total_label")}: TZS ${_cart!.total.toStringAsFixed(0)}\n"
                          "${tr(context, "delivery_label")}: TZS ${_deliveryFee.toStringAsFixed(0)}"
                          "${_isBoltSelected ? ' ${tr(context, "bolt_estimate_note")}' : ''}\n"
                          "${tr(context, "grand_total_label")}: TZS ${(_cart!.total + _deliveryFee).toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: InputDecoration(labelText: tr(context, "payment_method_label")),
                          items: [
                            DropdownMenuItem(value: "mpesa", child: Text(tr(context, "mpesa_payment"))),
                            DropdownMenuItem(value: "tigopesa", child: Text(tr(context, "tigopesa_payment"))),
                            DropdownMenuItem(
                              value: "cash_on_delivery",
                              child: Text(tr(context, "cash_on_delivery_payment")),
                            ),
                          ],
                          onChanged: (v) => setState(() => _paymentMethod = v!),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _checkingOut ? null : _checkout,
                            child: _checkingOut
                                ? const CircularProgressIndicator()
                                : Text(tr(context, "checkout_button")),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
