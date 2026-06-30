import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:deemusiq/collections/assets.gen.dart';
import 'package:deemusiq/components/dialogs/age_restriction_dialog.dart';
import 'package:deemusiq/components/titlebar/titlebar.dart';
import 'package:deemusiq/extensions/context.dart';
import 'package:deemusiq/pages/getting_started/sections/greeting.dart';
import 'package:deemusiq/pages/getting_started/sections/playback.dart';
import 'package:deemusiq/pages/getting_started/sections/privacy_consent.dart';
import 'package:deemusiq/pages/getting_started/sections/region.dart';
import 'package:deemusiq/pages/getting_started/sections/support.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class GettingStartedPage extends HookConsumerWidget {
  static const name = "getting_started";

  const GettingStartedPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final pageController = usePageController();

    final onNext = useCallback(() {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }, [pageController]);

    final onPrevious = useCallback(() {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }, [pageController]);

    // SA FPB Act: show age restriction on first visit
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final accepted = await AgeRestrictionDialog.showIfNeeded(context);
        if (!accepted && context.mounted) {
          // User declined — navigate away or show a blocked screen
          context.router.popForced();
        }
      });
      return null;
    }, []);

    return Scaffold(
      headers: [
        SafeArea(
          child: TitleBar(
            backgroundColor: Colors.transparent,
            surfaceBlur: 0,
            trailing: [
              ListenableBuilder(
                listenable: pageController,
                builder: (context, _) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: pageController.hasClients &&
                            (pageController.page == 0 ||
                                pageController.page == 4)
                        ? const SizedBox()
                        : Button.secondary(
                            onPressed: () {
                              pageController.animateToPage(
                                4,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Text(context.l10n.skip_this_nonsense),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
      floatingHeader: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: Assets.images.bengaliPatternsBg.provider(),
            fit: BoxFit.cover,
          ),
        ),
        child: PageView(
          controller: pageController,
          children: [
            GettingStartedPageGreetingSection(onNext: onNext),
            GettingStartedPageLanguageRegionSection(onNext: onNext),
            GettingStartedPagePlaybackSection(
              onNext: onNext,
              onPrevious: onPrevious,
            ),
            GettingStartedPagePrivacyConsentSection(
              onNext: onNext,
              onPrevious: onPrevious,
            ),
            const GettingStartedScreenSupportSection(),
          ],
        ),
      ),
    );
  }
}
