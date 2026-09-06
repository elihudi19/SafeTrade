import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database MOJA ya SQLite ya ndani inayotumiwa na sehemu zote za offline:
/// risiti zilizosubiri (pending_receipts), stock cache ya kaunta
/// (cached_counter_stock), na uhamisho wa mzigo uliosubiri
/// (pending_stock_transfers).
///
/// Kuwa na database moja (badala ya nyingi) kunarahisisha usimamizi wa
/// version/migrations na kuepuka gharama ya kufungua/kufunga faili nyingi.
class LocalDatabase {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), "safetrade_offline.db");
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_receipts (
            local_uuid TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cached_counter_stock (
            product_id TEXT PRIMARY KEY,
            product_name TEXT NOT NULL,
            unit_price REAL NOT NULL,
            wholesale_price REAL,
            cost_price REAL NOT NULL DEFAULT 0,
            quantity INTEGER NOT NULL,
            store_id TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_stock_transfers (
            local_uuid TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }
}
