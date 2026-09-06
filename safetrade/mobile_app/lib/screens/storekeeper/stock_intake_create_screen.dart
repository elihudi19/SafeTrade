import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../services/stock_intake_service.dart';
import '../../models/product.dart';
import '../../l10n/tr.dart';
import '../../widgets/language_switcher.dart';

/// "Kila mzigo unapoingia Stoo" - Storekeeper anaandika gharama halisi.
/// Inaonyesha moja kwa moja bei ya kipande (ikiwa bundle) na bei ya
/// chini kabisa isiyo na hasara KABLA ya kuhifadhi, ili aone matokeo
/// ya hesabu kabla hajathibitisha.
class StockIntakeCreateScreen extends StatefulWidget {
  const StockIntakeCreateScreen({super.key});

  @override
  State<StockIntakeCreateScreen> createState() => _StockIntakeCreateScreenState();
}

class _StockIntakeCreateScreenState extends State<StockIntakeCreateScreen> {
  final _productService = ProductService();
  final _intakeService = StockIntakeService();

  List<Product> _products = [];
  String? _selectedProductId;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  final _quantityController = TextEditingController();
  bool _isBundle = false;
  final _unitsPerBundleController = TextEditingController(text: "1");
  final _bundleCostController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _transportCostController = TextEditingController(text: "0");
  final _otherCostsController = TextEditingController(text: "0");

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await _productService.listProducts();
    setState(() {
      _products = products;
      if (products.isNotEmpty) _selectedProductId = products.first.id;
      _loading = false;
    });
  }

  double get _computedUnitCost {
    if (_isBundle) {
      final bundleCost = double.tryParse(_bundleCostController.text) ?? 0;
      final units = int.tryParse(_unitsPerBundleController.text) ?? 1;
      if (units <= 0) return 0;
      return bundleCost / units;
    }
    return double.tryParse(_unitCostController.text) ?? 0;
  }

  double get _totalShipmentCost {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    final transport = double.tryParse(_transportCostController.text) ?? 0;
    final other = double.tryParse(_otherCostsController.text) ?? 0;
    return (_computedUnitCost * qty) + transport + other;
  }

  double get _suggestedMinPrice {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    if (qty <= 0) return 0;
    return _totalShipmentCost / qty;
  }

  Future<void> _submit() async {
    if (_selectedProductId == null) return;
    final qty = int.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) {
      setState(() => _error = tr(context, "stock_intake_failed_message"));
      return;
    }

    setState(() { _submitting = true; _error = null; });
    final result = await _intakeService.recordIntake(
      productId: _selectedProductId!,
      quantityReceived: qty,
      isBundlePurchase: _isBundle,
      unitsPerBundle: int.tryParse(_unitsPerBundleController.text) ?? 1,
      bundleCostPrice: _isBundle ? double.tryParse(_bundleCostController.text) : null,
      unitCostPrice: !_isBundle ? double.tryParse(_unitCostController.text) : null,
      transportCost: double.tryParse(_transportCostController.text) ?? 0,
      otherCosts: double.tryParse(_otherCostsController.text) ?? 0,
    );
    setState(() => _submitting = false);

    if (result["statusCode"] == 201) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, "stock_intake_saved_message"))),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() => _error = tr(context, "stock_intake_failed_message"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, "stock_intake_title")),
        actions: const [LanguageSwitcher(), SizedBox(width: 8)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedProductId,
                    decoration: InputDecoration(labelText: tr(context, "product_label")),
                    items: _products
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedProductId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: tr(context, "quantity_received_label")),
                    onChanged: (_) => setState(() {}),
                  ),
                  SwitchListTile(
                    title: Text(tr(context, "is_bundle_switch")),
                    value: _isBundle,
                    onChanged: (v) => setState(() => _isBundle = v),
                  ),
                  if (_isBundle) ...[
                    TextField(
                      controller: _unitsPerBundleController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: tr(context, "units_per_bundle_label")),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bundleCostController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: tr(context, "bundle_cost_price_label")),
                      onChanged: (_) => setState(() {}),
                    ),
                  ] else
                    TextField(
                      controller: _unitCostController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: tr(context, "unit_cost_price_label")),
                      onChanged: (_) => setState(() {}),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _transportCostController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: tr(context, "transport_cost_label")),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _otherCostsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: tr(context, "other_costs_label")),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${tr(context, "computed_unit_cost_label")}: TZS ${_computedUnitCost.toStringAsFixed(2)}",
                          ),
                          Text(
                            "${tr(context, "total_shipment_cost_label")}: TZS ${_totalShipmentCost.toStringAsFixed(0)}",
                          ),
                          Text(
                            "${tr(context, "suggested_min_price_label")}: TZS ${_suggestedMinPrice.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const CircularProgressIndicator()
                          : Text(tr(context, "save_stock_intake_button")),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
