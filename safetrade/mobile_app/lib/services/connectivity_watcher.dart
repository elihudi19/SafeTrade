import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'receipt_service.dart';
import 'stock_transfer_service.dart';

/// Inasikiliza mabadiliko ya mtandao wa kifaa chote na kujaribu kutuma
/// data zote zilizosubiri (risiti + stock transfers) MARA MOJA mtandao
/// unaporudi - badala ya kusubiri mtumiaji afungue upya dashboard yake.
///
/// Anzisha MARA MOJA tu kwenye app (main.dart), siyo kwa kila screen.
class ConnectivityWatcher {
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _wasOffline = false;

  static void start() {
    _subscription?.cancel();
    _subscription = Connectivity().onConnectivityChanged.listen((results) async {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline && _wasOffline) {
        // Mtandao umerudi baada ya kukosekana - jaribu sync ya kila kitu.
        await ReceiptService().syncPendingReceipts();
        await StockTransferService().syncPendingTransfers();
      }
      _wasOffline = !isOnline;
    });
  }

  static void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
