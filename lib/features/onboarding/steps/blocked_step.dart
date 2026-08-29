library;

import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// The under-18 stop.
///
/// The only screen in the app with no way forward. There is deliberately no
/// continue button, no "I understand" checkbox, and no back arrow: an
/// age check that can be undone by tapping back and typing 19 is not a
/// safeguard, and offering a bypass would make the refusal theatre.
///
/// The tone matters as much as the rule. `01-concept.md` asks for plain
/// language and a real alternative, not a scolding — someone reading this is
/// most likely a teenager worried about their body, and the last thing that
/// helps is being told off by a phone.
class BlockedStep extends StatelessWidget {
  const BlockedStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: ListView(
        children: [
          const SizedBox(height: 32),
          const Text(
            'Calori is built for adults',
            style: AppType.screenTitle,
          ),
          const SizedBox(height: 16),
          Text(
            'Calorie targets for under-18s depend on growth and development, '
            'and the equation behind this app does not account for either. '
            'Getting it wrong at your age does real harm, so Calori will not '
            'guess.',
            style: AppType.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'If you are thinking about what you eat, that is worth talking '
            'through with a doctor, a school nurse, or a parent or guardian. '
            'They can give you something this app cannot: advice that fits '
            'you.',
            style: AppType.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
