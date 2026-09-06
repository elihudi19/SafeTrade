import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'local_database.dart';

/// Foleni ya risiti zilizokatwa bila mtandao - zinasubiri kutumwa server
/// (angalia ReceiptService.syncPendingReceipts).
class OfflineReceiptStore {
  static Future<void> queueReceipt(String localUuid, Map<String, dynamic> payload) async {
    final db = await LocalDatabase.instance();
    await db.insert(
      "pending_receipts",
      {
        "local_uuid": localUuid,
        "payload": jsonEncode(payload),
        "synced": 0,
        "created_at": DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> unsyncedReceipts() async {
    final db = await LocalDatabase.instance();
    final rows = await db.query("pending_receipts", where: "synced = 0");
    return rows.map((r) => jsonDecode(r["payload"] as String) as Map<String, dynamic>).toList();
  }

  static Future<void> markSynced(String localUuid) async {
    final db = await LocalDatabase.instance();
    await db.update(
      "pending_receipts", {"synced": 1},
      where: "local_uuid = ?", whereArgs: [localUuid],
    );
  }

  static Future<int> unsyncedCount() async {
    final db = await LocalDatabase.instance();
    final result = await db.rawQuery(
      "SELECT COUNT(*) as c FROM pending_receipts WHERE synced = 0",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
