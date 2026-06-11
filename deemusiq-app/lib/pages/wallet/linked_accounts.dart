import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter_extension.dart';
import 'package:deemusiq/collections/deemusiq_icons.dart';
import 'package:deemusiq/components/titlebar/titlebar.dart';
import 'package:deemusiq/components/wallet/wallet_common.dart';
import 'package:deemusiq/models/wallet/linked_account.dart';
import 'package:deemusiq/provider/wallet/wallet_provider.dart';
import 'package:deemusiq/services/wallet/wallet_api.dart';
import 'package:url_launcher/url_launcher_string.dart';

@RoutePage()
class LinkedAccountsPage extends HookConsumerWidget {
  static const name = "linked-accounts";

  const LinkedAccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(walletProvider.select((s) => s.linkedAccounts));
    final byProvider = {for (final a in accounts) a.provider: a};
    final backendConfigured = WalletApiClient.instance.isConfigured;

    return SafeArea(
      bottom: false,
      child: Scaffold(
        headers: [
          TitleBar(title: const Text("Linked accounts")),
        ],
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      filled: true,
                      fillColor: context.theme.colorScheme.muted,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        backendConfigured
                            ? "Connect your accounts on other services to bring "
                                "your playlists and favourites into DeeMusiq. "
                                "Connecting opens that provider's secure login "
                                "(OAuth) in your browser, then returns you here."
                            : "Account linking needs a DeeMusiq connection — "
                                "this build is offline, so connecting is "
                                "disabled. You can still disconnect accounts "
                                "stored on this device.",
                      ).muted().small(),
                    ),
                    const Gap(16),
                    for (final provider in LinkedProvider.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProviderTile(
                          provider: provider,
                          account: byProvider[provider],
                          backendConfigured: backendConfigured,
                        ),
                      ),
                    const Gap(40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderTile extends ConsumerWidget {
  final LinkedProvider provider;
  final LinkedAccount? account;
  final bool backendConfigured;

  const _ProviderTile({
    required this.provider,
    required this.backendConfigured,
    this.account,
  });

  /// Starts the real OAuth flow: the backend returns an authorize URL that we
  /// open in the external browser. The provider redirects back through the
  /// backend, which deep-links into the app (`deemusiq://link`) — the
  /// deep-link handler (see use_deep_linking.dart) then re-syncs the
  /// authoritative linked-accounts list.
  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    try {
      final url = await WalletApiClient.instance.startLinking(provider.name);
      final opened =
          await launchUrlString(url, mode: LaunchMode.externalApplication);
      if (context.mounted) {
        showWalletToast(
          context,
          opened
              ? "Finish connecting ${provider.label} in your browser"
              : "Couldn't open your browser — try again",
          icon: provider.icon,
        );
      }
    } on WalletApiException catch (e) {
      if (!context.mounted) return;
      showWalletToast(
        context,
        e.message == "provider_not_configured"
            ? "${provider.label} linking isn't available yet — coming soon."
            : e.message,
        icon: DeeMusiqIcons.info,
      );
    } catch (_) {
      // launchUrlString can throw (no browser/handler installed).
      if (!context.mounted) return;
      showWalletToast(
        context,
        "Couldn't open your browser — try again",
        icon: DeeMusiqIcons.info,
      );
    }
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(walletProvider.notifier).unlinkAccount(provider);
      if (context.mounted) {
        showWalletToast(context, "${provider.label} disconnected",
            icon: provider.icon);
      }
    } on WalletApiException catch (e) {
      if (context.mounted) {
        showWalletToast(context, e.message, icon: DeeMusiqIcons.info);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = account != null;
    return Card(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: provider.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(provider.icon, color: provider.accent),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(provider.label).semiBold(),
                    if (connected) ...[
                      const Gap(6),
                      const Icon(DeeMusiqIcons.verified,
                          size: 14, color: Color(0xFF2E7D32)),
                    ],
                  ],
                ),
                Text(
                  connected
                      ? "Connected as ${account!.displayName}"
                      : provider.description,
                ).muted().xSmall(),
              ],
            ),
          ),
          const Gap(10),
          if (connected)
            Button.outline(
              onPressed: () => _disconnect(context, ref),
              child: const Text("Disconnect"),
            )
          else
            Button.primary(
              onPressed:
                  backendConfigured ? () => _connect(context, ref) : null,
              child: const Text("Connect"),
            ),
        ],
      ),
    );
  }
}
