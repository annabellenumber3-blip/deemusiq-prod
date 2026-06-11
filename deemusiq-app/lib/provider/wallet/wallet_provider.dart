import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:deemusiq/models/wallet/linked_account.dart';
import 'package:deemusiq/models/wallet/payment_method.dart';
import 'package:deemusiq/models/wallet/pushed_song.dart';
import 'package:deemusiq/models/wallet/region_pricing.dart';
import 'package:deemusiq/models/wallet/supported_creator.dart';
import 'package:deemusiq/models/wallet/token_pack.dart';
import 'package:deemusiq/models/wallet/token_transaction.dart';
import 'package:deemusiq/models/wallet/wallet_state.dart';
import 'package:deemusiq/services/integrity/integrity_service.dart';
import 'package:deemusiq/services/logger/logger.dart';
import 'package:deemusiq/services/wallet/wallet_api.dart';
import 'package:deemusiq/services/wallet/wallet_persistence.dart';
import 'package:uuid/uuid.dart';

/// Owns the user's wallet: balance (derived from the ledger), top-ups, song
/// pushes, creator support and linked accounts. State is persisted locally
/// after every mutation.
class WalletNotifier extends Notifier<WalletState> {
  static const _uuid = Uuid();

  /// Human-readable reason the last online push/support failed (null = none).
  /// Set right before [pushSong]/[supportCreator] return false so the UI can
  /// distinguish a backend refusal from a plain insufficient balance.
  String? lastActionError;

  @override
  WalletState build() {
    return WalletPersistence.load();
  }

  /// Money features are disabled when the integrity check has flagged a
  /// tampered/repackaged build. Sets [lastActionError] for the UI.
  bool _integrityLocked() {
    if (IntegrityService.instance.walletLocked) {
      lastActionError =
          "Wallet disabled — this app may be modified. Reinstall the official DeeMusiq.";
      return true;
    }
    return false;
  }

  Future<void> _commit(WalletState next) async {
    state = next;
    await WalletPersistence.save(next);
  }

  List<TokenTransaction> _prepend(TokenTransaction tx) =>
      [tx, ...state.transactions];

  /// Credits tokens for a completed/ simulated top-up.
  Future<void> applyTopUp({
    required TokenPack pack,
    required PaymentMethodKind method,
    required RegionTier region,
  }) async {
    final tx = TokenTransaction(
      id: _uuid.v4(),
      type: TokenTransactionType.topUp,
      tokens: pack.totalTokens,
      timestamp: DateTime.now(),
      description: "${pack.label} pack · ${pack.totalTokens} tokens",
      fiatAmount: region.localPrice(pack.basePriceZar),
      currencyCode: region.currencyCode,
      paymentMethod: method,
    );

    await _commit(state.copyWith(transactions: _prepend(tx)));
  }

  /// One-off promotional credit (e.g. a welcome bonus).
  Future<void> grantBonus(int tokens, {String reason = "Welcome bonus"}) async {
    if (tokens <= 0) return;
    final tx = TokenTransaction(
      id: _uuid.v4(),
      type: TokenTransactionType.bonus,
      tokens: tokens,
      timestamp: DateTime.now(),
      description: reason,
    );
    await _commit(state.copyWith(transactions: _prepend(tx)));
  }

  /// Pays [tokens] to push a song up the charts. Returns false (no-op) if the
  /// balance is insufficient or, online, if the backend refuses the spend
  /// ([lastActionError] then carries the reason).
  Future<bool> pushSong({
    required String songId,
    required String title,
    required String artist,
    String? artistId,
    String? imageUrl,
    required int tokens,
  }) async {
    lastActionError = null;
    if (_integrityLocked()) return false;
    if (tokens <= 0) return false;
    // Offline, the local ledger gates the spend. Online, the server is the
    // ledger — a stale-low local balance must not block a server-valid spend.
    if (!WalletApiClient.instance.isConfigured && tokens > state.balance) {
      return false;
    }

    final now = DateTime.now();

    if (WalletApiClient.instance.isConfigured) {
      // Online: the server is the ledger. Only mutate local state after the
      // spend succeeded — an API failure must never debit the wallet here too.
      if (!await _spendOnline(() => WalletApiClient.instance.pushSong(
            songId: songId,
            title: title,
            artist: artist,
            artistId: artistId,
            imageUrl: imageUrl,
            tokens: tokens,
          ))) {
        return false;
      }
      // Keep this device's push aggregate for the offline trending view; the
      // authoritative ledger/creators are pulled from the server below.
      await _commit(state.copyWith(
        pushedSongs: _withPushAggregate(
          songId: songId,
          title: title,
          artist: artist,
          artistId: artistId,
          imageUrl: imageUrl,
          tokens: tokens,
          at: now,
        ),
      ));
      await syncFromBackend();
      return true;
    }

    final tx = TokenTransaction(
      id: _uuid.v4(),
      type: TokenTransactionType.push,
      tokens: -tokens,
      timestamp: now,
      description: "Pushed \"$title\"",
      songId: songId,
      songTitle: title,
      artistId: artistId,
      artistName: artist,
    );

    await _commit(state.copyWith(
      transactions: _prepend(tx),
      pushedSongs: _withPushAggregate(
        songId: songId,
        title: title,
        artist: artist,
        artistId: artistId,
        imageUrl: imageUrl,
        tokens: tokens,
        at: now,
      ),
      supportedCreators: _withCreatorContribution(
        creatorId: artistId ?? artist,
        name: artist,
        imageUrl: imageUrl,
        tokens: tokens,
        at: now,
      ),
    ));
    return true;
  }

  /// Directly supports a creator with tokens. Returns false if balance is low
  /// or, online, if the backend refuses ([lastActionError] carries the reason).
  Future<bool> supportCreator({
    required String creatorId,
    required String name,
    String? imageUrl,
    required int tokens,
  }) async {
    lastActionError = null;
    if (_integrityLocked()) return false;
    if (tokens <= 0) return false;
    // Same gating as pushSong: local balance only matters offline.
    if (!WalletApiClient.instance.isConfigured && tokens > state.balance) {
      return false;
    }

    if (WalletApiClient.instance.isConfigured) {
      if (!await _spendOnline(() => WalletApiClient.instance.supportCreator(
            creatorId: creatorId,
            name: name,
            tokens: tokens,
          ))) {
        return false;
      }
      await syncFromBackend();
      return true;
    }

    final now = DateTime.now();
    final tx = TokenTransaction(
      id: _uuid.v4(),
      type: TokenTransactionType.support,
      tokens: -tokens,
      timestamp: now,
      description: "Supported $name",
      artistId: creatorId,
      artistName: name,
    );

    await _commit(state.copyWith(
      transactions: _prepend(tx),
      supportedCreators: _withCreatorContribution(
        creatorId: creatorId,
        name: name,
        imageUrl: imageUrl,
        tokens: tokens,
        at: now,
      ),
    ));
    return true;
  }

  /// Runs one backend spend call; on failure records a friendly reason in
  /// [lastActionError] and returns false WITHOUT touching local state.
  Future<bool> _spendOnline(Future<int> Function() spend) async {
    try {
      await spend();
      return true;
    } on WalletApiException catch (e) {
      lastActionError = e.message == "insufficient_balance"
          ? "Not enough tokens — your balance may have changed."
          : e.message;
      return false;
    } catch (e, stack) {
      AppLogger.reportError(e, stack);
      lastActionError = "Couldn't reach DeeMusiq — nothing was charged.";
      return false;
    }
  }

  /// The per-song push aggregate with one more push applied.
  List<PushedSong> _withPushAggregate({
    required String songId,
    required String title,
    required String artist,
    String? artistId,
    String? imageUrl,
    required int tokens,
    required DateTime at,
  }) {
    final pushed = [...state.pushedSongs];
    final songIdx = pushed.indexWhere((s) => s.id == songId);
    if (songIdx >= 0) {
      final existing = pushed[songIdx];
      pushed[songIdx] = existing.copyWith(
        totalTokens: existing.totalTokens + tokens,
        pushCount: existing.pushCount + 1,
        lastPushedAt: at,
      );
    } else {
      pushed.add(PushedSong(
        id: songId,
        title: title,
        artist: artist,
        artistId: artistId,
        imageUrl: imageUrl,
        totalTokens: tokens,
        pushCount: 1,
        lastPushedAt: at,
      ));
    }
    return pushed;
  }

  List<SupportedCreator> _withCreatorContribution({
    required String creatorId,
    required String name,
    String? imageUrl,
    required int tokens,
    required DateTime at,
  }) {
    final creators = [...state.supportedCreators];
    final idx = creators.indexWhere((c) => c.id == creatorId);
    if (idx >= 0) {
      final existing = creators[idx];
      creators[idx] = existing.copyWith(
        name: name,
        imageUrl: imageUrl ?? existing.imageUrl,
        totalTokens: existing.totalTokens + tokens,
        contributions: existing.contributions + 1,
        lastSupportedAt: at,
      );
    } else {
      creators.add(SupportedCreator(
        id: creatorId,
        name: name,
        imageUrl: imageUrl,
        totalTokens: tokens,
        contributions: 1,
        lastSupportedAt: at,
      ));
    }
    // Most-supported first.
    creators.sort((a, b) => b.totalTokens.compareTo(a.totalTokens));
    return creators;
  }

  Future<void> linkAccount(
    LinkedProvider provider, {
    required String displayName,
    String? externalId,
  }) async {
    final accounts =
        state.linkedAccounts.where((a) => a.provider != provider).toList();
    accounts.add(LinkedAccount(
      provider: provider,
      displayName: displayName,
      externalId: externalId,
      connectedAt: DateTime.now(),
    ));
    await _commit(state.copyWith(linkedAccounts: accounts));
  }

  /// Disconnects [provider]. Online this goes through the backend (throws
  /// [WalletApiException] on failure, leaving local state untouched) and then
  /// re-syncs; offline it is a purely local removal.
  Future<void> unlinkAccount(LinkedProvider provider) async {
    final online = WalletApiClient.instance.isConfigured;
    if (online) {
      await WalletApiClient.instance.unlinkAccount(provider.name);
    }
    await _commit(state.copyWith(
      linkedAccounts:
          state.linkedAccounts.where((a) => a.provider != provider).toList(),
    ));
    if (online) await syncFromBackend();
  }

  LinkedAccount? linkedAccountFor(LinkedProvider provider) {
    for (final account in state.linkedAccounts) {
      if (account.provider == provider) return account;
    }
    return null;
  }

  Future<void> setRegionOverride(String? code) async {
    await _commit(state.copyWith(regionCode: code, clearRegion: code == null));
  }

  /// Pulls authoritative wallet state from the backend when one is configured
  /// (see [WalletApiClient]). No-op locally, so the app stays fully offline-first
  /// until a backend URL is set. The server is the source of truth for balance,
  /// ledger and supported creators once connected.
  Future<void> syncFromBackend() async {
    if (!WalletApiClient.instance.isConfigured) return;
    try {
      final data = await WalletApiClient.instance
          .fetchWallet()
          .timeout(const Duration(seconds: 8));

      final txs = (data["transactions"] as List? ?? const [])
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            // Server field is `createdAt`; the app model expects `timestamp`.
            m["timestamp"] = m["createdAt"] ?? m["timestamp"];
            return TokenTransaction.fromJson(m);
          })
          .toList();

      final creators = (data["supportedCreators"] as List? ?? const [])
          .map((e) =>
              SupportedCreator.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      // Linked accounts are owned by the backend — pull the authoritative list.
      var accounts = state.linkedAccounts;
      try {
        final raw = await WalletApiClient.instance
            .fetchLinkedAccounts()
            .timeout(const Duration(seconds: 8));
        accounts = raw
            .map((e) =>
                LinkedAccount.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        // Keep last known accounts if this sub-call fails.
      }

      await _commit(state.copyWith(
        transactions: txs,
        supportedCreators: creators,
        linkedAccounts: accounts,
      ));
    } catch (e, stack) {
      // Unreachable/slow backend → keep the last known state, but record it so
      // a persistent sync failure is visible instead of silently stale.
      AppLogger.reportError(e, stack);
    }
  }

  /// Wipes the wallet (used by a "reset" affordance / testing).
  Future<void> reset() async {
    await _commit(const WalletState());
  }
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  () => WalletNotifier(),
);
