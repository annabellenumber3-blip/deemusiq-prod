import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter_extension.dart';
import 'package:deemusiq/hooks/configurators/use_check_yt_dlp_installed.dart';
import 'package:deemusiq/modules/root/deemusiq_navigation_bar.dart';
import 'package:deemusiq/modules/root/bottom_player.dart';
import 'package:deemusiq/modules/root/sidebar/sidebar.dart';
import 'package:deemusiq/hooks/configurators/use_endless_playback.dart';
import 'package:deemusiq/modules/root/use_global_subscriptions.dart';
import 'package:deemusiq/provider/glance/glance.dart';

@RoutePage()
class RootAppPage extends HookConsumerWidget {
  const RootAppPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final backgroundColor = Theme.of(context).colorScheme.background;
    final brightness = Theme.of(context).brightness;

    ref.listen(glanceProvider, (_, __) {});

    useGlobalSubscriptions(ref);
    useEndlessPlayback(ref);
    useCheckYtDlpInstalled(ref);

    useEffect(() {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: backgroundColor, // status bar color
          statusBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
        ),
      );
      return null;
    }, [backgroundColor, brightness]);

    final scaffold = MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: SafeArea(
        top: false,
        child: Scaffold(
          footers: const [
            BottomPlayer(),
            DeeMusiqNavigationBar(),
          ],
          floatingFooter: true,
          child: Sidebar(
            child: Builder(builder: (context) {
              // Dynamically account for bottom player (63px collapsed) +
              // navigation bar (50px animated) so content never hides behind them.
              final navHeight = ref.watch(navigationPanelHeight);
              final playerHeight = 63.0; // PlayerOverlay collapsed minHeight
              final bottomPadding = (playerHeight + navHeight) * context.theme.scaling;
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: MediaQuery.paddingOf(context)
                      .copyWith(bottom: bottomPadding),
                ),
                child: const AutoRouter(),
              );
            }),
          ),
        ),
      ),
    );

    return scaffold;
  }
}
