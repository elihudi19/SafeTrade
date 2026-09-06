import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'local_database.dart';

/// Foleni ya Stock Transfer zilizoanzishwa na Storekeeper akiwa OFFLINE.
class PendingStockTransferStore {
  static Future<void> queueTransfer(String localUuid, Map<String, dynamic> payload) async {
    final db = await LocalDatabase.instance();
    await db.insert(
      "pending_stock_transfers",
      {
        "local_uuid": localUuid,
        "payload": jsonEncode(payload),
        "synced": 0,
        "created_at": DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> unsyncedTransfers() async {
    final db = await LocalDatabase.instance();
    final rows = await db.query("pending_stock_transfers", where: "synced = 0");
    return rows.map((r) => jsonDecode(r["payload"] as String) as Map<String, dynamic>).toList();
  }

  static Future<void> markSynced(String localUuid) async {
    final db = await LocalDatabase.instance();
    await db.update(
      "pending_stock_transfers", {"synced": 1},
      where: "local_uuid = ?", whereArgs: [localUuid],
    );
  }
}
