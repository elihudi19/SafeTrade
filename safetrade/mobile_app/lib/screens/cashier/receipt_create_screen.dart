import 'package:flutter/material.dart';
import '../../services/stock_cache_service.dart';
import '../../services/receipt_service.dart';
import '../../services/thermal_printer_service.dart';
import '../../models/receipt.dart';
import '../../state/session.dart';
import '../../l10n/tr.dart';
import '../../widgets/language_switcher.dart';

/// Cashier anachagua bidhaa kutoka Kaunta, anaweka idadi, ANACHAGUA bei
/// ya kuuzia (Rejareja/Jumla - au bei yoyote nyingine kwa makubaliano na
/// Mmiliki), kisha anakata risiti.
///
/// MUHIMU (kwa mujibu wa maombi): Cashier ANARUHUSIWA kubadilisha bei ya
/// kuuzia kwa kila bidhaa - bei za "unit_price"/"wholesale_price" za
/// Product ni CHAGUO-MSINGI za kumsaidia tu, siyo kikomo kigumu. Kama
/// akiweka bei chini ya gharama ya ununuzi (cost_price), anaonywa lakini
/// HAZUIWI - uamuzi wa mwisho ni wake/Mmiliki.
class ReceiptCreateScreen extends StatefulWidget {
  const ReceiptCreateScreen({super.key});

  @override
  State<ReceiptCreateScreen> createState() => _ReceiptCreateScreenState();
}

class _ReceiptCreateScreenState extends State<ReceiptCreateScreen> {
  final _stockCacheService = StockCacheService();
  final _receiptService = ReceiptService();
  final _printerService = ThermalPrinterService();
  final _session = Session();

  List<Map<String, dynamic>> _counterStock = [];
  final Map<String, int> _cart = {}; // productId -> quantity
  final Map<String, double> _priceOverrides = {}; // productId -> bei halisi ya kuuzia
  String _globalSaleType = "retail"; // retail | wholesale - inaathiri bei ya chaguo-msingi
  String _paymentMethod = "cash";
  bool _digitalReceiptRequested = false;
  bool _printOnCounter = true;
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _session.loadCurrentUser();
    final stock = await _stockCacheService.getCounterStock();
    setState(() {
      _counterStock = stock;
      _loading = false;
    });
  }

  double _defaultPriceFor(Map<String, dynamic> item) {
    if (_globalSaleType == "wholesale" && item["wholesale_price"] != null) {
      return (item["wholesale_price"] as num).toDouble();
    }
    return (item["unit_price"] as num).toDouble();
  }

  double _priceFor(Map<String, dynamic> item) {
    final productId = item["product_id"] as String;
    return _priceOverrides[productId] ?? _defaultPriceFor(item);
  }

  double get _total {
    double sum = 0;
    for (final item in _counterStock) {
      final productId = item["product_id"] as String;
      final qty = _cart[productId] ?? 0;
      if (qty > 0) sum += qty * _priceFor(item);
    }
    return sum;
  }

  void _editPrice(Map<String, dynamic> item) {
    final productId = item["product_id"] as String;
    final controller = TextEditingController(
      text: _priceFor(item).toStringAsFixed(0),
    );
    final costPrice = (item["cost_price"] as num?)?.toDouble() ?? 0;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final enteredPrice = double.tryParse(controller.text) ?? 0;
          final belowCost = costPrice > 0 && enteredPrice < costPrice;
          return AlertDialog(
            title: Text("${tr(context, "selling_price_label")}: ${item["product_name"]}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(labelText: tr(context, "selling_price_label")),
                  onChanged: (_) => setDialogState(() {}),
                ),
                if (belowCost)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      tr(context, "below_cost_warning"),
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(context, "cancel"))),
              ElevatedButton(
                onPressed: () {
                  final price = double.tryParse(controller.text);
                  if (price != null && price > 0) {
                    setState(() => _priceOverrides[productId] = price);
                  }
                  Navigator.pop(context);
                },
                child: Text(tr(context, "save")),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (_cart.isEmpty) return;
    setState(() => _submitting = true);

    final nameById = {
      for (final item in _counterStock)
        item["product_id"] as String: item["product_name"] as String,
    };
    final itemsData = {
      for (final item in _counterStock) item["product_id"] as String: item,
    };

    final items = _cart.entries
        .map((e) => ReceiptItemInput(
              product: e.key, quantity: e.value,
              unitPrice: _priceFor(itemsData[e.key]!),
              saleType: _globalSaleType,
            ))
        .toList();

    final storeId = _session.currentUser?.store ?? "";
    final result = await _receiptService.createReceipt(
      storeId: storeId,
      paymentMethod: _paymentMethod,
      receiptSource: _digitalReceiptRequested ? "softcopy_only" : "thermal_printer",
      smsOrSoftcopySent: _digitalReceiptRequested,
      items: items,
      customerName: _customerName.text.trim(),
      customerPhone: _customerPhone.text.trim(),
    );

    final isOffline = result["offline"] == true;
    final succeeded = result["statusCode"] == 201 || isOffline;

    if (succeeded && isOffline) {
      for (final entry in _cart.entries) {
        await _stockCacheService.reflectOfflineSale(entry.key, entry.value);
      }
    }

    if (succeeded && _printOnCounter) {
      await _printReceipt(items, nameById);
    }

    setState(() => _submitting = false);
    if (!mounted) return;

    if (succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isOffline ? result["message"] : tr(context, "receipt_created_message"))),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${tr(context, "receipt_failed_message")}: ${result["data"]}")),
      );
    }
  }

  Future<void> _printReceipt(
    List<ReceiptItemInput> items, Map<String, String> nameById,
  ) async {
    final printerItems = items
        .map((i) => {
              "name": nameById[i.product] ?? i.product,
              "quantity": i.quantity,
              "unitPrice": i.unitPrice,
            })
        .toList();
    try {
      final printed = await _printerService.printReceipt(
        storeName: "SafeTrade",
        items: printerItems,
        totalAmount: _total,
        paymentMethod: _paymentMethod,
        customerName: _customerName.text.trim(),
      );
      if (!printed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, "printer_not_found_message"))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(context, "print_failed_message"))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, "create_receipt_title")),
        actions: const [LanguageSwitcher(), SizedBox(width: 8)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: "retail", label: Text(tr(context, "retail_sale_type"))),
                      ButtonSegment(value: "wholesale", label: Text(tr(context, "wholesale_sale_type"))),
                    ],
                    selected: {_globalSaleType},
                    onSelectionChanged: (selection) => setState(() {
                      _globalSaleType = selection.first;
                      _priceOverrides.clear(); // rudi kwenye bei za chaguo-msingi za aina mpya
                    }),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _counterStock.length,
                    itemBuilder: (context, index) {
                      final item = _counterStock[index];
                      final productId = item["product_id"] as String;
                      final available = item["quantity"] as int;
                      final qty = _cart[productId] ?? 0;
                      final price = _priceFor(item);
                      return ListTile(
                        title: Text(item["product_name"] as String),
                        subtitle: GestureDetector(
                          onTap: () => _editPrice(item),
                          child: Row(
                            children: [
                              Text(
                                "${tr(context, "counter_stock_label")}: $available — TZS ${price.toStringAsFixed(0)}",
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit, size: 14, color: Colors.blueGrey),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: qty > 0
                                  ? () => setState(() => _cart[productId] = qty - 1)
                                  : null,
                            ),
                            Text("$qty"),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: qty < available
                                  ? () => setState(() => _cart[productId] = qty + 1)
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("${tr(context, "total_label")}: TZS ${_total.toStringAsFixed(0)}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customerName,
                        decoration: InputDecoration(labelText: tr(context, "customer_name_optional_label")),
                      ),
                      TextField(
                        controller: _customerPhone,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(labelText: tr(context, "customer_phone_digital_label")),
                      ),
                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: InputDecoration(labelText: tr(context, "payment_method_label")),
                        items: [
                          DropdownMenuItem(value: "cash", child: Text(tr(context, "cash_payment"))),
                          DropdownMenuItem(value: "lipa_namba", child: Text(tr(context, "lipa_namba_payment"))),
                          DropdownMenuItem(value: "mpesa", child: Text(tr(context, "mpesa_payment"))),
                          DropdownMenuItem(value: "tigopesa", child: Text(tr(context, "tigopesa_payment"))),
                        ],
                        onChanged: (v) => setState(() => _paymentMethod = v!),
                      ),
                      SwitchListTile(
                        title: Text(tr(context, "digital_receipt_switch_title")),
                        subtitle: Text(tr(context, "digital_receipt_switch_subtitle")),
                        value: _digitalReceiptRequested,
                        onChanged: (v) => setState(() => _digitalReceiptRequested = v),
                      ),
                      SwitchListTile(
                        title: Text(tr(context, "print_on_counter_switch")),
                        value: _printOnCounter,
                        onChanged: (v) => setState(() => _printOnCounter = v),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_cart.isEmpty || _submitting) ? null : _submit,
                          child: _submitting
                              ? const CircularProgressIndicator()
                              : Text(tr(context, "finish_create_receipt_button")),
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
