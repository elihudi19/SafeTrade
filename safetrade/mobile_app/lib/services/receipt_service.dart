import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'api_client.dart';
import '../models/receipt.dart';
import '../local/offline_receipt_store.dart';

class ReceiptService {
  final ApiClient _client = ApiClient();
  final _uuid = const Uuid();

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Cashier anakata risiti. Online -> inatumwa moja kwa moja. Offline ->
  /// inawekwa kwenye foleni ya ndani (OfflineReceiptStore) kusubiri sync.
  Future<Map<String, dynamic>> createReceipt({
    required String storeId,
    required String paymentMethod,
    required String receiptSource,
    required List<ReceiptItemInput> items,
    bool smsOrSoftcopySent = false,
    String customerName = "",
    String customerPhone = "",
  }) async {
    final localUuid = _uuid.v4();
    final payload = {
      "local_uuid": localUuid,
      "store": storeId,
      "payment_method": paymentMethod,
      "receipt_source": receiptSource,
      "sms_or_softcopy_sent": smsOrSoftcopySent,
      "customer_name": customerName,
      "customer_phone": customerPhone,
      "items": items.map((i) => i.toJson()).toList(),
    };

    if (await _isOnline()) {
      final res = await _client.post("/receipts/", payload);
      if (res.statusCode == 201) {
        return {"statusCode": 201, "offline": false, "data": jsonDecode(res.body)};
      }
      // Kama server imekataa kwa sababu isiyo ya mtandao (mfano validation),
      // HATUWEKI offline queue - tunarudisha error moja kwa moja kwa Cashier.
      return {"statusCode": res.statusCode, "offline": false, "data": jsonDecode(res.body)};
    }

    await OfflineReceiptStore.queueReceipt(localUuid, payload);
    return {
      "statusCode": 202, "offline": true,
      "message": "Hakuna mtandao - risiti imehifadhiwa kifaa chako na "
          "itatumwa moja kwa moja mtandao utakaporudi.",
    };
  }

  /// Inatuma risiti zote zilizosubiri (offline queue) kwenda server.
  /// Piga hii mara mtandao unaporudi (mfano kwenye app resume / connectivity
  /// listener - angalia mobile_app/README.md kwa muundo unaopendekezwa).
  Future<int> syncPendingReceipts() async {
    if (!await _isOnline()) return 0;
    final pending = await OfflineReceiptStore.unsyncedReceipts();
    if (pending.isEmpty) return 0;

    final res = await _client.post("/sync/receipts/", {"receipts": pending});
    if (res.statusCode != 200) return 0;

    final data = jsonDecode(res.body);
    int syncedCount = 0;
    for (final result in data["results"]) {
      if (result["status"] == "synced" || result["status"] == "already_synced") {
        await OfflineReceiptStore.markSynced(result["local_uuid"]);
        syncedCount++;
      }
    }
    return syncedCount;
  }
}
