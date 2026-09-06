import 'package:flutter/material.dart';
import '../../services/shift_service.dart';
import '../../services/stock_transfer_service.dart';
import '../../services/receipt_service.dart';
import '../../models/stock_transfer.dart';
import '../../l10n/tr.dart';
import '../../widgets/language_switcher.dart';
import '../login_screen.dart';
import '../../services/api_client.dart';
import 'receipt_create_screen.dart';
import 'printer_settings_screen.dart';

class CashierDashboardScreen extends StatefulWidget {
  const CashierDashboardScreen({super.key});

  @override
  State<CashierDashboardScreen> createState() => _CashierDashboardScreenState();
}

class _CashierDashboardScreenState extends State<CashierDashboardScreen> {
  final _shiftService = ShiftService();
  final _transferService = StockTransferService();
  final _receiptService = ReceiptService();

  bool _loading = true;
  bool _hasActiveShift = false;
  String? _activeShiftId;
  List<StockTransfer> _pendingTransfers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final transfers = await _transferService.listPendingTransfers();
    final shift = await _shiftService.activeShift();
    final synced = await _receiptService.syncPendingReceipts();
    setState(() {
      _pendingTransfers = transfers;
      _hasActiveShift = shift != null;
      _activeShiftId = shift?.id;
      _loading = false;
    });
    if (synced > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$synced ${tr(context, "offline_receipts_synced_message")}")),
      );
    }
  }

  Future<void> _clockIn() async {
    final result = await _shiftService.clockIn();
    if (result["statusCode"] == 201) {
      setState(() {
        _activeShiftId = result["data"]["id"];
        _hasActiveShift = true;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tayari uko kwenye shift, au hitilafu imetokea.")),
      );
    }
  }

  Future<void> _clockOut() async {
    if (_activeShiftId == null) return;
    final result = await _shiftService.clockOut(_activeShiftId!);
    if (result["statusCode"] == 200) {
      setState(() { _hasActiveShift = false; _activeShiftId = null; });
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(tr(context, "shift_report_title")),
            content: Text(result["data"]["summary_json"].toString()),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(context, "ok"))),
            ],
          ),
        );
      }
    }
  }

  Future<void> _acceptTransfer(StockTransfer transfer) async {
    final controller = TextEditingController(text: transfer.quantitySent.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(context, "confirm_receipt_dialog_title")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${tr(context, "quantity_sent_label")}: ${transfer.quantitySent}"),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr(context, "actual_quantity_received_label")),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(context, "cancel"))),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(controller.text) ?? transfer.quantitySent;
              await _transferService.acceptTransfer(transfer.id, qty);
              if (mounted) {
                Navigator.pop(context);
                _load();
              }
            },
            child: const Text("ACCEPT"),
          ),
        ],
      ),
    );
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
        title: Text(tr(context, "cashier_dashboard_title")),
        actions: [
          const LanguageSwitcher(),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: tr(context, "printer_settings_tooltip"),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
            ),
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReceiptCreateScreen()),
        ),
        icon: const Icon(Icons.receipt_long),
        label: Text(tr(context, "create_receipt_button")),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  Card(
                    margin: const EdgeInsets.all(12),
                    child: ListTile(
                      title: Text(tr(context, _hasActiveShift
                          ? "shift_active_label" : "shift_not_started_label")),
                      trailing: ElevatedButton(
                        onPressed: _hasActiveShift ? _clockOut : _clockIn,
                        child: Text(tr(context, _hasActiveShift
                            ? "close_shift_button" : "start_shift_button")),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(tr(context, "pending_transfers_title"),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  if (_pendingTransfers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(tr(context, "no_pending_transfers_message")),
                    ),
                  ..._pendingTransfers.map((t) => ListTile(
                        title: Text("${tr(context, "quantity_sent_label")}: ${t.quantitySent}"),
                        subtitle: Text(t.product),
                        trailing: ElevatedButton(
                          onPressed: () => _acceptTransfer(t),
                          child: const Text("ACCEPT"),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}
