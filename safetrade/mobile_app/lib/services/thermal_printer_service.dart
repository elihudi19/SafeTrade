import 'dart:typed_data';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Printer HALISI ya risiti kupitia Bluetooth (ESC/POS thermal printers -
/// aina inayotumika sana Tanzania: 58mm/80mm Bluetooth receipt printers).
///
/// MUHIMU KWA MWENYE MRADI: Package hii (`print_bluetooth_thermal`) haiwezi
/// kupimwa hapa kwa sababu mazingira niliyotengeneza nayo hayana kifaa cha
/// Bluetooth wala printer halisi. Nimefuata API rasmi ya package hii
/// (documented kwenye pub.dev) kwa usahihi, lakini LAZIMA ujaribu na
/// printer halisi kabla ya kuamini inafanya kazi 100%.
///
/// PIA MUHIMU: Kwa vile mradi huu HAUJAPITIA `flutter create` (hakuna
/// android/ios folders bado), LAZIMA uongeze permissions za Bluetooth
/// kwenye AndroidManifest.xml baada ya kuunda folda hizo - angalia
/// mobile_app/README.md sehemu ya "Bluetooth Permissions".
class ThermalPrinterService {
  static const _prefKeyMac = "thermal_printer_mac";
  static const _prefKeyName = "thermal_printer_name";

  Future<bool> isBluetoothEnabled() async {
    return await PrintBluetoothThermal.bluetoothEnabled;
  }

  Future<List<BluetoothInfo>> getPairedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  Future<void> saveSelectedPrinter(String mac, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyMac, mac);
    await prefs.setString(_prefKeyName, name);
  }

  Future<Map<String, String>?> getSelectedPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    final mac = prefs.getString(_prefKeyMac);
    final name = prefs.getString(_prefKeyName);
    if (mac == null) return null;
    return {"mac": mac, "name": name ?? "Printer"};
  }

  Future<bool> connectToSelectedPrinter() async {
    final selected = await getSelectedPrinter();
    if (selected == null) return false;
    return await PrintBluetoothThermal.connect(macPrinterAddress: selected["mac"]!);
  }

  Future<bool> get isConnected async => await PrintBluetoothThermal.connectionStatus;

  Future<void> disconnect() async {
    await PrintBluetoothThermal.disconnect;
  }

  /// Inachapisha risiti kamili: jina la duka, bidhaa, jumla, njia ya
  /// malipo, na tarehe/muda - muundo wa kawaida wa risiti ya 58mm/80mm.
  Future<bool> printReceipt({
    required String storeName,
    required List<Map<String, dynamic>> items, // [{name, quantity, unitPrice}]
    required double totalAmount,
    required String paymentMethod,
    String? customerName,
    PaperSize paperSize = PaperSize.mm58,
  }) async {
    final connected = await isConnected;
    if (!connected) {
      final reconnected = await connectToSelectedPrinter();
      if (!reconnected) return false;
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    bytes += generator.text(
      storeName,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    );
    bytes += generator.text(
      "SafeTrade - Mauzo bila kikomo",
      styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );
    bytes += generator.hr();

    if (customerName != null && customerName.isNotEmpty) {
      bytes += generator.text("Mteja: $customerName");
    }
    bytes += generator.text("Tarehe: ${DateTime.now().toString().substring(0, 16)}");
    bytes += generator.hr();

    for (final item in items) {
      final name = item["name"] as String;
      final qty = item["quantity"] as int;
      final unitPrice = (item["unitPrice"] as num).toDouble();
      final lineTotal = qty * unitPrice;
      bytes += generator.text(name);
      bytes += generator.row([
        PosColumn(text: "$qty x ${unitPrice.toStringAsFixed(0)}", width: 6),
        PosColumn(
          text: lineTotal.toStringAsFixed(0),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: "JUMLA (TZS)", width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: totalAmount.toStringAsFixed(0),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2),
      ),
    ]);
    bytes += generator.text("Malipo: $paymentMethod");
    bytes += generator.hr();
    bytes += generator.text(
      "Asante kwa kununua!",
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return await PrintBluetoothThermal.writeBytes(Uint8List.fromList(bytes));
  }
}
