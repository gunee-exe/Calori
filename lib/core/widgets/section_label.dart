/// The small uppercase label that heads every card section.
library;

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// "PROTEIN", "TODAY", "DAILY TARGET", "LUNCH".
///
/// Uppercased here rather than at every call site, so callers pass ordinary
/// prose and the widget owns the presentation. The wide tracking in
/// [AppType.sectionLabel] is what stops small caps reading as shouting.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: color == null
          ? AppType.sectionLabel
          : AppType.sectionLabel.copyWith(color: color),
    );
  }
}

/// The provenance chip on a food search result: "USDA", "INDB", "CoFID".
///
/// Small and quiet by design. It is there so a curious user can tell where a
/// number came from, not to decorate the row.
class SourceBadge extends StatelessWidget {
  const SourceBadge(this.source, {super.key});

  final String source;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(source.toUpperCase(), style: AppType.sourceBadge),
      ),
    );
  }
}

/// A macro legend entry: a coloured dot, a name, and a value.
///
/// Carbs and fat appear only in this form. They never get a filled bar or a
/// large surface, because the design puts calories first and protein second and
/// treats these two as secondary information.
class MacroDot extends StatelessWidget {
  const MacroDot({
    super.key,
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text('$label  $value', style: AppType.secondary),
      ],
    );
  }
}
