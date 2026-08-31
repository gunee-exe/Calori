/// Manual food logging (UC-05).
///
/// The path that works when there is no network, no camera, or no patience.
/// Everything here is local: an FTS5 query against the bundled database.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/calori_card.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/section_label.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/food.dart';
import '../home/providers.dart';
import 'providers.dart';
import 'widgets/food_result_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.dayKey, this.mealType});

  /// The day to log against. Null when this is the shell's search destination,
  /// which follows whatever day Home is showing; set only when pushed as a
  /// route, as the photo review screen does for "add something it missed".
  final int? dayKey;

  /// Preselected when arriving from a specific meal. Null means the screen
  /// picks a sensible default from the time of day.
  final MealType? mealType;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);

    final int dayKey = widget.dayKey ?? ref.watch(selectedDayProvider);

    // Pushed as a route it needs its own way out; as the shell's destination
    // the nav bar is the way out, and a close button beside it would be two
    // controls doing one job.
    final pushed = widget.dayKey != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          // Clears the floating nav bar when this is the shell's destination.
          padding: AppLayout.screenPadding.add(
            const EdgeInsets.only(bottom: AppLayout.navClearance),
          ),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Add food', style: AppType.screenTitle),
                ),
                if (pushed)
                  _CloseButton(onTap: () => Navigator.of(context).pop()),
              ],
            ),
            const SizedBox(height: 16),
            _SearchField(controller: _controller, focus: _focus),

            if (query.trim().isEmpty) ...[
              const SizedBox(height: 22),
              const _Suggestions(),
            ],

            const SizedBox(height: 20),
            _Results(
              results: results,
              query: query,
              dayKey: dayKey,
              mealType: widget.mealType,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField({required this.controller, required this.focus});

  final TextEditingController controller;
  final FocusNode focus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focus,
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: AppType.body,
              decoration: const InputDecoration(
                hintText: 'Search foods',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).set(value),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                ref.read(searchQueryProvider.notifier).clear();
              },
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Recent and frequent foods, before anything is typed.
class _Suggestions extends ConsumerWidget {
  const _Suggestions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(foodSuggestionsProvider);

    return suggestions.maybeWhen(
      data: (foods) {
        if (foods.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Recent'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final food in foods)
                  SelectableChip(
                    label: food.nameNormalised,
                    selected: false,
                    onTap: () => ref
                        .read(searchQueryProvider.notifier)
                        .set(food.nameNormalised),
                  ),
              ],
            ),
          ],
        );
      },
      // Suggestions are a convenience. While they load, or if they fail, the
      // search field above still works — so nothing is shown rather than a
      // spinner or an error the user can do nothing about.
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.results,
    required this.query,
    required this.dayKey,
    required this.mealType,
  });

  final AsyncValue<List<Food>> results;
  final String query;
  final int dayKey;
  final MealType? mealType;

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) return const SizedBox.shrink();

    return results.when(
      loading: () => const _ResultsSkeleton(),
      error: (error, _) => const _Message(
        title: 'Search stopped working',
        body:
            'Something went wrong reading the food database. Restarting the '
            'app usually clears it.',
      ),
      data: (foods) {
        if (foods.isEmpty) {
          return const _Message(
            title: 'No matches',
            body:
                'Try a shorter or more general word — "rice" finds more than '
                '"basmati rice, cooked".',
          );
        }

        return Column(
          children: [
            for (final (index, food) in foods.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RisingCard(
                  index: index,
                  child: FoodResultCard(
                    food: food,
                    dayKey: dayKey,
                    mealType: mealType,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Padding(padding: EdgeInsets.only(bottom: 10), child: _SkeletonRow()),
        Padding(padding: EdgeInsets.only(bottom: 10), child: _SkeletonRow()),
        Padding(padding: EdgeInsets.only(bottom: 10), child: _SkeletonRow()),
        Padding(padding: EdgeInsets.only(bottom: 10), child: _SkeletonRow()),
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppType.bodyStrong),
          const SizedBox(height: 6),
          Text(body, style: AppType.secondary),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const SizedBox(
        width: AppLayout.minTapTarget,
        height: AppLayout.minTapTarget,
        child: Icon(Icons.close, color: AppColors.textPrimary),
      ),
    );
  }
}
