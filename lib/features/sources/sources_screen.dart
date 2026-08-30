/// Where the numbers come from (UC-11).
///
/// Read entirely from the shipped database's `meta` table, which the build
/// pipeline writes from the sources that actually ran. The screen therefore
/// cannot claim a dataset the build did not include, or omit one it did — which
/// matters, because several of these licences require attribution and a screen
/// that has drifted from the data is worse than none.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/calori_card.dart';
import '../../core/widgets/section_label.dart';
import '../../data/providers.dart';
import '../../domain/repositories/food_repository.dart';

class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(_sourcesProvider);
    final version = ref.watch(_buildVersionProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Food data', style: AppType.bodyStrong),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppLayout.screenPadding,
          children: [
            Text(
              'Calori looks food up in a database that ships with the app, so '
              'searching works with no connection and nothing you search for '
              'leaves your phone.',
              style: AppType.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),
            const SectionLabel('Sources'),
            const SizedBox(height: 12),
            ...switch (sources) {
              AsyncData(:final value) => [
                for (final source in value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SourceCard(source: source),
                  ),
              ],
              AsyncError() => [
                const Text(
                  'The source list could not be read from the food database.',
                  style: AppType.secondary,
                ),
              ],
              _ => [const SizedBox(height: 80)],
            },
            const SizedBox(height: 12),
            Text(
              'Nutrition figures are per 100 g as published by each source. '
              'Household portions are approximate.',
              style: AppType.caption.copyWith(height: 1.5),
            ),
            if (version != null) ...[
              const SizedBox(height: 10),
              Text('Database build $version', style: AppType.caption),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});

  final DataSourceInfo source;

  @override
  Widget build(BuildContext context) {
    return CaloriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(source.name, style: AppType.bodyStrong),
          const SizedBox(height: 8),
          // Rendered verbatim. Several of these licences specify the exact
          // wording, so it is stored as a single string by the build rather
          // than assembled here.
          Text(
            source.attribution,
            style: AppType.secondary.copyWith(height: 1.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SourceBadge(source.licence.split('(').first.trim()),
              if (source.url != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    source.url!,
                    style: AppType.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

final _sourcesProvider = FutureProvider.autoDispose<List<DataSourceInfo>>(
  (ref) => ref.watch(foodRepositoryProvider).sources(),
);

final _buildVersionProvider = FutureProvider.autoDispose<String?>(
  (ref) => ref.watch(foodRepositoryProvider).buildVersion(),
);
