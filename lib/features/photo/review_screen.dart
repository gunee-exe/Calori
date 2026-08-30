/// Reviewing what the model proposed (UC-03).
///
/// Nothing is written until the user presses Save. The screen's job is to make
/// disagreeing easy — every number here is a proposal, and the design treats it
/// as one.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/food_name.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/calori_card.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/section_label.dart';
import '../../core/widgets/shimmer_box.dart';
import '../../data/ai/vision_service.dart';
import '../../data/providers.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/food.dart';
import '../../domain/repositories/diary_repository.dart';
import '../search/search_screen.dart';
import 'providers.dart';
import 'widgets/proposed_card.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key, required this.photo, required this.dayKey});

  final File photo;
  final int dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(photoAnalysisProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppLayout.screenPadding,
                children: [
                  _Photo(photo: photo),
                  const SizedBox(height: 20),
                  switch (analysis) {
                    AsyncLoading() => const _Analysing(),
                    AsyncError(:final error) => _Failed(
                      error: error,
                      photo: photo,
                      dayKey: dayKey,
                    ),
                    AsyncData(:final value) when value != null && value.isNotEmpty =>
                      _Items(items: value, dayKey: dayKey),
                    _ => const SizedBox.shrink(),
                  },
                ],
              ),
            ),
            if (analysis.value != null && analysis.value!.isNotEmpty)
              _SaveBar(items: analysis.value!, photo: photo, dayKey: dayKey),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.photo});

  final File photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(photo, fit: BoxFit.cover),
            Positioned(
              top: 10,
              right: 10,
              child: _CircleButton(
                icon: Icons.close,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: AppLayout.minTapTarget,
        height: AppLayout.minTapTarget,
        decoration: const BoxDecoration(
          // Solid white rather than a scrim: the control has to stay legible
          // over a photo whose colours are unknown.
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: AppShadows.card,
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

class _Analysing extends StatelessWidget {
  const _Analysing();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Reading your photo'),
        SizedBox(height: 12),
        // Skeletons in the shape of the answer, not a spinner. The user is
        // about to be asked to check numbers; showing where they will appear
        // makes that a shorter wait than a rotating circle does.
        ShimmerBox(height: 92),
        SizedBox(height: 10),
        ShimmerBox(height: 92),
        SizedBox(height: 10),
        ShimmerBox(height: 92),
        SizedBox(height: 16),
        Text('This usually takes a few seconds.', style: AppType.caption),
      ],
    );
  }
}

class _Failed extends ConsumerWidget {
  const _Failed({
    required this.error,
    required this.photo,
    required this.dayKey,
  });

  final Object error;
  final File photo;
  final int dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failure = error is VisionException
        ? error as VisionException
        : const VisionException(VisionFailure.server);

    // A failure never costs the user their meal. The photo is kept, retry is
    // one tap, and manual logging — which always works — is offered right
    // here rather than left to be discovered.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CaloriCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(failure.message, style: AppType.body.copyWith(height: 1.55)),
              const SizedBox(height: 16),
              if (failure.failure != VisionFailure.rateLimited) ...[
                PillButton(
                  label: 'Try again',
                  onPressed: () => ref
                      .read(photoAnalysisProvider.notifier)
                      .run(photo),
                ),
                const SizedBox(height: 10),
              ],
              PillButton(
                label: 'Add by hand instead',
                variant: PillVariant.surface,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => SearchScreen(dayKey: dayKey),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Items extends ConsumerWidget {
  const _Items({required this.items, required this.dayKey});

  final List<ProposedItem> items;
  final int dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(photoAnalysisProvider.notifier);
    final total = items.fold(Macros.zero, (sum, item) => sum + item.macros);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('What we found')),
            Text('${formatKcal(total.kcal)} kcal', style: AppType.bodyStrong),
          ],
        ),
        const SizedBox(height: 12),
        for (final (index, item) in items.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ProposedCard(
              // Keyed on name and position so confirming one item does not
              // reset the confirmed state of its neighbours when the list
              // rebuilds.
              key: ValueKey('${item.name}-$index'),
              item: item,
              onResize: (grams) => notifier.resize(index, grams),
              onRemove: () => notifier.removeAt(index),
            ),
          ),
        const SizedBox(height: 4),
        PillButton(
          label: '+ Add something it missed',
          variant: PillVariant.ghost,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SearchScreen(dayKey: dayKey),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveBar extends ConsumerStatefulWidget {
  const _SaveBar({
    required this.items,
    required this.photo,
    required this.dayKey,
  });

  final List<ProposedItem> items;
  final File photo;
  final int dayKey;

  @override
  ConsumerState<_SaveBar> createState() => _SaveBarState();
}

class _SaveBarState extends ConsumerState<_SaveBar> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: PillButton(
        label: _saving ? 'Saving…' : 'Save to log',
        onPressed: _saving ? null : _save,
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final diary = ref.read(diaryRepositoryProvider);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await diary.addEntry(
        dayKey: widget.dayKey,
        mealType: mealTypeForNow(),
        source: ItemSource.ai,
        photoPath: widget.photo.path,
        items: [
          for (final item in widget.items)
            NewItem(
              name: item.name,
              grams: item.grams,
              macros: item.macros,
              source: item.fromCache ? ItemSource.cache : ItemSource.ai,
              portionDesc: item.portionDesc,
              confidence: item.confidence,
              confidenceReason: item.confidenceReason,
            ),
        ],
      );

      // Learn from what was *accepted*, not from what was proposed. This is
      // what makes the cache converge on the user's corrections rather than on
      // the model's first guess — and why the same meal reports the same
      // numbers next time.
      for (final item in widget.items) {
        if (item.grams <= 0) continue;
        await diary.rememberFood(
          normaliseFoodName(item.name),
          item.macros.scaled(100 / item.grams),
        );
      }

      ref.read(photoAnalysisProvider.notifier).clear();
      ref.read(photoCaptureProvider.notifier).clear();

      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Meal added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't save that. Try again."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
