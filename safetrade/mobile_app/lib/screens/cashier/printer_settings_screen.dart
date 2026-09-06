import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../services/thermal_printer_service.dart';
import '../../l10n/tr.dart';
import '../../widgets/language_switcher.dart';

/// Screen ya Cashier/Owner kuchagua printer ya Bluetooth ya kuchapisha
/// risiti. Muhimu: BluetoothInfo.macAdress (jina la field kwenye package
/// `print_bluetooth_thermal` - ONA muundo huu una typo ya kihistoria
/// "macAdress" siyo "macAddress"; kama toleo jipya la package limebadilika,
/// `flutter analyze` itaonyesha error hapa na urekebishe jina la field).
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final _printerService = ThermalPrinterService();
  List<BluetoothInfo> _devices = [];
  String? _selectedMac;
  bool _loading = true;
  bool _testing = false;
  bool _bluetoothOn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final btOn = await _printerService.isBluetoothEnabled();
    final devices = btOn ? await _printerService.getPairedDevices() : <BluetoothInfo>[];
    final selected = await _printerService.getSelectedPrinter();
    setState(() {
      _bluetoothOn = btOn;
      _devices = devices;
      _selectedMac = selected?["mac"];
      _loading = false;
    });
  }

  Future<void> _selectPrinter(BluetoothInfo device) async {
    await _printerService.saveSelectedPrinter(device.macAdress, device.name);
    setState(() => _selectedMac = device.macAdress);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${device.name} ${tr(context, "printer_selected_message")}")),
      );
    }
  }

  Future<void> _testPrint() async {
    setState(() => _testing = true);
    final success = await _printerService.printReceipt(
      storeName: "SafeTrade",
      items: [
        {"name": "Test", "quantity": 1, "unitPrice": 1000},
      ],
      totalAmount: 1000,
      paymentMethod: "cash",
    );
    setState(() => _testing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, success
            ? "test_print_success_message" : "test_print_failed_message"))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, "printer_settings_title")),
        actions: const [LanguageSwitcher(), SizedBox(width: 8)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_bluetoothOn
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      tr(context, "bluetooth_off_message"),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          tr(context, "printer_pick_instructions"),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      if (_devices.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(tr(context, "no_paired_printers_message")),
                        ),
                      ..._devices.map((d) => RadioListTile<String>(
                            title: Text(d.name),
                            subtitle: Text(d.macAdress),
                            value: d.macAdress,
                            groupValue: _selectedMac,
                            onChanged: (_) => _selectPrinter(d),
                          )),
                      if (_selectedMac != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.print),
                              onPressed: _testing ? null : _testPrint,
                              label: _testing
                                  ? const CircularProgressIndicator()
                                  : Text(tr(context, "test_print_button")),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
