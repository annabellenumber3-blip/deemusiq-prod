import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:deemusiq/collections/deemusiq_icons.dart';
import 'package:deemusiq/services/kv_store/kv_store.dart';
import 'package:deemusiq/services/logger/logger.dart';

/// South Africa Films and Publications Act (FPB) compliance:
/// Dialog shown on first launch requiring users to confirm they are
/// 18 years or older to access explicit content.
class AgeRestrictionDialog extends StatelessWidget {
  const AgeRestrictionDialog({super.key});

  static Future<bool> showIfNeeded(BuildContext context) async {
    if (KVStoreService.ageVerified) return true;

    if (!context.mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AgeRestrictionDialog(),
    );

    if (result == true) {
      await KVStoreService.setAgeVerified(true);
      AppLogger.log.i('User confirmed age 18+');
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(DeeMusiqIcons.warning, color: Colors.amber),
          const Gap(8),
          const Text('Age Restriction').semiBold(),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This application may contain explicit music content.',
          ).large(),
          const Gap(8),
          Text(
            'In compliance with the South African Films and Publications Act '
            '(FPB), you must be 18 years or older to access explicit content.',
          ).muted(),
          const Gap(12),
          Text(
            'By proceeding, you confirm that you are at least 18 years old.',
          ).semiBold(),
        ],
      ),
      actions: [
        Button.secondary(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('I am under 18'),
        ),
        Button.primary(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('I am 18 or older'),
        ),
      ],
    );
  }
}
