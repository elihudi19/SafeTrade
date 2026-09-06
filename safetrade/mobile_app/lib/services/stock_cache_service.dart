import '../services/product_service.dart';
import '../local/offline_stock_store.dart';

/// Inaunganisha stock ya KAUNTA ya moja kwa moja (live, kutoka API) na
/// cache ya ndani (offline fallback) - hii ndiyo inayoruhusu
/// ReceiptCreateScreen kufanya kazi salama hata bila mtandao.
class StockCacheService {
  final ProductService _productService = ProductService();

  /// Inarudisha stock ya kaunta. Ikiwa mtandao upo, inachukua ya moja kwa
  /// moja (live) NA kusasisha cache kwa matumizi ya baadaye ya offline.
  /// Ikiwa mtandao haupo (au ombi limeshindikana), inarudi kwenye cache
  /// ya mwisho iliyojulikana.
  Future<List<Map<String, dynamic>>> getCounterStock() async {
    try {
      final products = await _productService.listProducts();
      final shelfStock = await _productService.listShelfStock();
      final priceById = {for (final p in products) p.id: p.unitPrice};
      final wholesalePriceById = {for (final p in products) p.id: p.wholesalePrice};
      final costPriceById = {for (final p in products) p.id: p.costPrice};

      final counterStock = shelfStock
          .where((s) => s.locationType == "counter" && s.quantity > 0)
          .map((s) => {
                "product_id": s.product,
                "product_name": s.productName,
                "unit_price": priceById[s.product] ?? 0,
                "wholesale_price": wholesalePriceById[s.product],
                "cost_price": costPriceById[s.product] ?? 0,
                "quantity": s.quantity,
                "store_id": s.store,
              })
          .toList();

      if (counterStock.isEmpty && shelfStock.isEmpty) {
        // Ombi limerudi tupu kabisa - inaweza kuwa ni kweli hakuna stock,
        // AU tokeni ya API imeisha muda. Hatuwezi kutofautisha hapa kwa
        // uhakika, kwa hiyo tunachukulia ni jibu halali na kusasisha cache.
      }

      await OfflineStockStore.refreshFromServer(counterStock);
      return counterStock;
    } catch (_) {
      // Mtandao haupo au ombi limeshindikana - tumia cache ya mwisho.
      return await OfflineStockStore.getAll();
    }
  }

  /// Baada ya risiti kukatwa OFFLINE, punguza cache ili muuzo unaofuata
  /// (bado offline) usiuze zaidi ya kilichopo kwenye cache.
  Future<void> reflectOfflineSale(String productId, int quantitySold) async {
    await OfflineStockStore.decrementLocal(productId, quantitySold);
  }
}
