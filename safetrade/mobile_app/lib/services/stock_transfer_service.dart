import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'api_client.dart';
import '../models/stock_transfer.dart';
import '../local/pending_stock_transfer_store.dart';

class StockTransferService {
  final ApiClient _client = ApiClient();
  final _uuid = const Uuid();

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Storekeeper anaanzisha uhamisho kwenda kaunta. Online -> moja kwa
  /// moja. Offline -> foleni ya ndani (itatumwa mtandao utakaporudi).
  Future<Map<String, dynamic>> initiateTransfer(String productId, int quantitySent) async {
    final localUuid = _uuid.v4();
    final payload = {
      "local_uuid": localUuid,
      "product": productId,
      "quantity_sent": quantitySent,
    };

    if (await _isOnline()) {
      final res = await _client.post("/stock-transfers/", payload);
      return {"statusCode": res.statusCode, "offline": false, "data": jsonDecode(res.body)};
    }

    await PendingStockTransferStore.queueTransfer(localUuid, payload);
    return {
      "statusCode": 202, "offline": true,
      "message": "Hakuna mtandao - uhamisho umehifadhiwa na utatumwa "
          "mtandao utakaporudi.",
    };
  }

  /// Inatuma uhamisho wote uliosubiri offline. Endpoint ya
  /// /stock-transfers/ ni idempotent kwa local_uuid (backend), kwa hiyo
  /// ni salama kutuma tena hata kama moja tayari lilishatumwa.
  Future<int> syncPendingTransfers() async {
    if (!await _isOnline()) return 0;
    final pending = await PendingStockTransferStore.unsyncedTransfers();
    int synced = 0;
    for (final payload in pending) {
      final res = await _client.post("/stock-transfers/", payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        await PendingStockTransferStore.markSynced(payload["local_uuid"]);
        synced++;
      }
    }
    return synced;
  }

  Future<List<StockTransfer>> listPendingTransfers() async {
    final res = await _client.get("/stock-transfers/");
    if (res.statusCode != 200) return [];
    final List data = jsonDecode(res.body);
    return data.map((e) => StockTransfer.fromJson(e))
        .where((t) => t.status == "pending_transfer").toList();
  }

  /// Cashier anathibitisha (ACCEPT) - LAZIMA aingize idadi HALISI aliyopokea.
  Future<Map<String, dynamic>> acceptTransfer(String transferId, int quantityReceived) async {
    final res = await _client.post(
      "/stock-transfers/$transferId/accept/", {"quantity_received": quantityReceived},
    );
    return {"statusCode": res.statusCode, "data": jsonDecode(res.body)};
  }
}
