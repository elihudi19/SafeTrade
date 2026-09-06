import 'package:flutter/material.dart';
import '../../services/marketplace_service.dart';
import '../../models/order.dart';
import '../../l10n/tr.dart';
import '../../widgets/language_switcher.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _marketplaceService = MarketplaceService();
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orders = await _marketplaceService.listOrders();
    setState(() { _orders = orders; _loading = false; });
  }

  Future<void> _confirmDelivery(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(context, "confirm_delivery_dialog_title")),
        content: Text(tr(context, "confirm_delivery_dialog_content")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr(context, "cancel"))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(context, "confirm_received_button")),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await _marketplaceService.confirmDelivery(order.id);
    if (result["statusCode"] == 200 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, "confirm_delivery_success_message"))),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, "order_history_title")),
        actions: const [LanguageSwitcher(), SizedBox(width: 8)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _orders.isEmpty
                  ? Center(child: Text(tr(context, "no_orders_message")))
                  : ListView.builder(
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final o = _orders[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ExpansionTile(
                            title: Text(
                              "${tr(context, "order_label")} #${o.id.substring(0, 8)} — ${o.status}",
                            ),
                            subtitle: Text(
                              "${tr(context, "total_label")}: TZS ${o.totalAmount.toStringAsFixed(0)}",
                            ),
                            children: [
                              ...o.items.map((i) => ListTile(
                                    title: Text(i.productName),
                                    trailing: Text("${i.quantity} x TZS ${i.unitPrice}"),
                                  )),
                              if (o.canConfirmDelivery)
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.check_circle_outline),
                                      onPressed: () => _confirmDelivery(o),
                                      label: Text(tr(context, "confirm_delivery_action_label")),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
