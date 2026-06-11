import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:deemusiq/models/wallet/token_pack.dart';
import 'package:deemusiq/provider/wallet/region_provider.dart';
import 'package:deemusiq/services/wallet/wallet_api.dart';

/// A token pack as priced by the backend (`GET /pricing`): authoritative,
/// region-adjusted and possibly live-FX corrected. Mirrors the backend's
/// `PricedPack` JSON (pack fields + price/priceLabel/currency).
class ServerPricedPack {
  final TokenPack pack;
  final double price;
  final String priceLabel;
  final String currencyCode;

  const ServerPricedPack({
    required this.pack,
    required this.price,
    required this.priceLabel,
    required this.currencyCode,
  });

  factory ServerPricedPack.fromJson(Map<String, dynamic> json) {
    return ServerPricedPack(
      pack: TokenPack(
        id: json["id"] as String? ?? "",
        label: json["label"] as String? ?? "",
        tokens: (json["tokens"] as num?)?.toInt() ?? 0,
        bonusTokens: (json["bonusTokens"] as num?)?.toInt() ?? 0,
        basePriceZar: (json["basePriceZar"] as num?)?.toDouble() ?? 0,
        popular: json["popular"] == true,
      ),
      price: (json["price"] as num?)?.toDouble() ?? 0,
      priceLabel: json["priceLabel"] as String? ?? "",
      currencyCode: json["currencyCode"] as String? ?? "",
    );
  }
}

/// Server-authoritative pack pricing for the current region. Yields null when
/// no backend is configured OR the fetch fails for any reason, so the token
/// store silently falls back to the local [RegionTier] math — the store UI
/// never blocks on this provider.
final serverPricingProvider =
    FutureProvider.autoDispose<List<ServerPricedPack>?>((ref) async {
  if (!WalletApiClient.instance.isConfigured) return null;
  final region = ref.watch(regionTierProvider);
  try {
    final data = await WalletApiClient.instance.fetchPricing(region.code);
    final packs = (data["packs"] as List? ?? const [])
        .map((e) =>
            ServerPricedPack.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((p) => p.pack.id.isNotEmpty && p.priceLabel.isNotEmpty)
        .toList();
    return packs.isEmpty ? null : packs;
  } catch (_) {
    return null;
  }
});
