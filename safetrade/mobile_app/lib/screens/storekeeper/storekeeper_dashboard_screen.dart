import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../services/stock_transfer_service.dart';
import '../../models/product.dart';
import '../../l10n/tr.dart';
import '../../widgets/language_switcher.dart';
import '../login_screen.dart';
import '../../services/api_client.dart';
import 'stock_intake_create_screen.dart';
import 'expense_create_screen.dart';

class StorekeeperDashboardScreen extends StatefulWidget {
  const StorekeeperDashboardScreen({super.key});

  @override
  State<StorekeeperDashboardScreen> createState() => _StorekeeperDashboardScreenState();
}

class _StorekeeperDashboardScreenState extends State<StorekeeperDashboardScreen> {
  final _productService = ProductService();
  final _transferService = StockTransferService();
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await _productService.listProducts();
    final synced = await _transferService.syncPendingTransfers();
    setState(() { _products = products; _loading = false; });
    if (synced > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$synced ${tr(context, "offline_transfer_synced_message")}")),
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

  void _openTransferDialog(Product product) {
    final qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("${tr(context, "transfer_dialog_title")}: ${product.name}"),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr(context, "transfer_quantity_label")),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(context, "cancel"))),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text) ?? 0;
              if (qty <= 0) return;
              final result = await _transferService.initiateTransfer(product.id, qty);
              if (mounted) {
                Navigator.pop(context);
                String message;
                if (result["offline"] == true) {
                  message = result["message"];
                } else if (result["statusCode"] == 201) {
                  message = tr(context, "transfer_initiated_message");
                } else {
                  message = tr(context, "transfer_failed_message");
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
              }
            },
            child: Text(tr(context, "transfer_button")),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, "storekeeper_dashboard_title")),
        actions: [
          const LanguageSwitcher(),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "add_expense",
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExpenseCreateScreen()),
              );
              if (result == true) _load();
            },
            icon: const Icon(Icons.receipt),
            label: Text(tr(context, "add_expense_button")),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: "add_stock_intake",
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StockIntakeCreateScreen()),
              );
              if (result == true) _load();
            },
            icon: const Icon(Icons.add_box),
            label: Text(tr(context, "add_stock_intake_button")),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final p = _products[index];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text("SKU: ${p.sku} — TZS ${p.unitPrice}"),
                    trailing: ElevatedButton(
                      onPressed: () => _openTransferDialog(p),
                      child: Text(tr(context, "transfer_button")),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
