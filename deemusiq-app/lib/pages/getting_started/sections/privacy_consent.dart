import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:deemusiq/collections/deemusiq_icons.dart';
import 'package:deemusiq/modules/getting_started/blur_card.dart';
import 'package:deemusiq/extensions/context.dart';
import 'package:deemusiq/services/kv_store/kv_store.dart';
import 'package:deemusiq/services/logger/logger.dart';

/// South Africa POPIA Act compliance: privacy notice and consent step
/// shown during onboarding.
class GettingStartedPagePrivacyConsentSection extends HookConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const GettingStartedPagePrivacyConsentSection({
    super.key,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context, ref) {
    final consentAccepted = useState(KVStoreService.privacyConsentGiven);

    return SafeArea(
      child: Center(
        child: BlurCard(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(DeeMusiqIcons.shield, size: 16),
                    const Gap(8),
                    Text('Privacy & Consent').semiBold().large(),
                  ],
                ),
                const Gap(16),
                Text(
                  'Your privacy matters. This notice explains how DeeMusiq '
                  'handles your personal information in compliance with the '
                  'South African Protection of Personal Information Act (POPIA).',
                ).muted(),
                const Gap(12),
                _infoRow(
                  DeeMusiqIcons.lock,
                  'No personal data collected without consent',
                  'We only collect data you explicitly provide — nothing is '
                  'harvested automatically.',
                ),
                const Gap(8),
                _infoRow(
                  DeeMusiqIcons.eye,
                  'Data minimization',
                  'We collect only what is strictly necessary to provide the '
                  'service: your music preferences, playback history, and '
                  'account details if you choose to create one.',
                ),
                const Gap(8),
                _infoRow(
                  DeeMusiqIcons.trash,
                  'Your rights under POPIA',
                  'You have the right to access, correct, or delete your '
                  'personal data at any time. Contact us at privacy@deemusiq.com.',
                ),
                const Gap(8),
                _infoRow(
                  DeeMusiqIcons.server,
                  'Data storage',
                  'Your data is stored securely and processed only for the '
                  'purpose of delivering and improving the DeeMusiq service.',
                ),
                const Gap(20),
                Row(
                  children: [
                    Checkbox(
                      value: consentAccepted.value,
                      onChanged: (value) {
                        consentAccepted.value = value!;
                      },
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'I have read and understand this privacy notice. '
                        'I consent to the processing of my personal information '
                        'as described above.',
                      ).small(),
                    ),
                  ],
                ),
                const Gap(24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Button.secondary(
                      leading: const Icon(DeeMusiqIcons.angleLeft),
                      onPressed: onPrevious,
                      child: Text(context.l10n.previous),
                    ),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Button.primary(
                        leading: const Icon(DeeMusiqIcons.angleRight),
                        disabled: !consentAccepted.value,
                        onPressed: () async {
                          await KVStoreService.setPrivacyConsentGiven(true);
                          AppLogger.log.i('User accepted privacy consent (POPIA)');
                          onNext();
                        },
                        child: Text(context.l10n.next),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const Gap(8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title).semiBold(),
              Text(description).small().muted(),
            ],
          ),
        ),
      ],
    );
  }
}
