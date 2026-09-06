import 'local_database.dart';

/// Cache ya ndani ya stock ya KAUNTA (counter) pekee - hii ndiyo
/// inayomruhusu Cashier kuuza akiwa OFFLINE bila hatari ya kuuza zaidi ya
/// kilichopo kimwili dukani.
///
/// MUHIMU: Cache hii ni "toleo la mwisho lililojulikana" (last-known-good
/// snapshot) - inasasishwa kila mara mtandao unapopatikana
/// (refreshFromServer). Ikiwa vifaa viwili tofauti vinauza bidhaa ile ile
/// wakati wote viko offline kwa wakati mmoja, kila kimoja kitatumia
/// nakala yake ya cache huru - MIGOGORO YA AINA HII (double-sell kati ya
/// vifaa viwili tofauti wakati wote viko offline) HAIWEZI kuzuiwa na
/// muundo huu peke yake; itaonekana tu kama DiscrepancyFlag baada ya
/// sync (server itagundua tofauti). Kwa maduka yenye Cashier mmoja tu
/// anayefanya kazi wakati mmoja, hatari hii ni ndogo sana kivitendo.
class OfflineStockStore {
  static Future<void> refreshFromServer(List<Map<String, dynamic>> counterStock) async {
    final db = await LocalDatabase.instance();
    final batch = db.batch();
    batch.delete("cached_counter_stock");
    for (final item in counterStock) {
      batch.insert("cached_counter_stock", {
        "product_id": item["product_id"],
        "product_name": item["product_name"],
        "unit_price": item["unit_price"],
        "wholesale_price": item["wholesale_price"],
        "cost_price": item["cost_price"] ?? 0,
        "quantity": item["quantity"],
        "store_id": item["store_id"],
        "updated_at": DateTime.now().toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getAll() async {
    final db = await LocalDatabase.instance();
    return await db.query("cached_counter_stock");
  }

  /// Baada ya risiti kukatwa OFFLINE, punguza cache ya ndani mara moja
  /// ili muuzo unaofuata (bado offline) usiuze zaidi ya kilichopo.
  static Future<void> decrementLocal(String productId, int quantitySold) async {
    final db = await LocalDatabase.instance();
    final rows = await db.query(
      "cached_counter_stock", where: "product_id = ?", whereArgs: [productId],
    );
    if (rows.isEmpty) return;
    final currentQty = rows.first["quantity"] as int;
    final newQty = (currentQty - quantitySold).clamp(0, currentQty);
    await db.update(
      "cached_counter_stock", {"quantity": newQty},
      where: "product_id = ?", whereArgs: [productId],
    );
  }
}
