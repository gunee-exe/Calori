/// The goal, viewed and changed in place (UC-10).
///
/// The design edits the goal here rather than behind a separate screen: three
/// steppers, with the target recalculating as you press them. Changing a goal
/// is nearly always a nudge, and a nudge should not cost a round trip through
/// a form.
///
/// The calorie and protein figures can also be **set by hand**. The engine is
/// still run, and still shown underneath the number it was overruled by, but it
/// does not get the last word. Someone who has a target from a coach, a
/// dietitian, or their own experience should not have to argue with a phone
/// about it.
///
/// Changes take effect **from today forward**. Past days keep the target that
/// was in force when they were logged — a day you hit is a day you hit, and
/// retroactively re-judging history would be both dishonest and demoralising.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/units.dart';
import '../../core/widgets/calori_card.dart';
import '../../core/widgets/macro_row.dart';
import '../../core/widgets/number_field.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/section_label.dart';
import '../../core/widgets/stepper_row.dart';
import '../../data/providers.dart';
import '../../domain/goal_engine.dart';
import '../../domain/goal_result.dart';
import '../../domain/models/enums.dart';
import '../../domain/repositories/diary_repository.dart';
import '../home/providers.dart';
import '../sources/sources_screen.dart';

/// How long after the last stepper press the change is written.
///
/// Pressing "+" five times should be one save, not five. Long enough to absorb
/// a run of taps, short enough that putting the phone down saves the goal.
const _saveDelay = Duration(milliseconds: 700);

class GoalScreen extends ConsumerStatefulWidget {
  const GoalScreen({super.key});

  @override
  ConsumerState<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends ConsumerState<GoalScreen> {
  Timer? _save;

  /// Pending edits, held until they settle. Null means "nothing pending, use
  /// the stored profile", which is what keeps this screen correct if the goal
  /// is changed anywhere else.
  double? _weight;
  double? _target;
  double? _rate;

  /// Pending override edits.
  ///
  /// [_overridesTouched] separates "nothing pending" from "pending change back
  /// to the engine", which null alone cannot express — clearing an override
  /// *is* setting it to null.
  bool _overridesTouched = false;
  int? _kcalOverride;
  int? _proteinOverride;

  @override
  void dispose() {
    _save?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    if (profile == null) return const _Empty();

    final imperial = profile.usesImperial;
    final weight = _weight ?? profile.weightKg;
    final target = _target ?? profile.targetWeightKg;
    final rate = _rate ?? _rateFrom(profile);

    final kcalOverride =
        _overridesTouched ? _kcalOverride : profile.kcalOverride;
    final proteinOverride =
        _overridesTouched ? _proteinOverride : profile.proteinOverrideG;

    // Until something is actually changed, show what is *saved* rather than a
    // fresh computation. Re-deriving the rate from a stored target date is
    // lossy, so recomputing on open can show a number a few kcal from the one
    // the user agreed to — which reads as the app quietly moving the goalposts.
    final edited = _weight != null || _target != null || _rate != null;
    final live = _evaluate(profile, weight, target, rate);
    final liveTarget = switch (live) {
      GoalAccepted(:final target) => target,
      GoalAdjusted(:final target) => target,
      GoalRefused() => null,
    };

    final baseKcal = edited ? liveTarget?.dailyKcal : profile.dailyKcal;
    final shownKcal = kcalOverride ?? baseKcal;

    final macros = _macrosToShow(
      profile: profile,
      kcal: shownKcal,
      weightKg: weight,
      proteinOverride: proteinOverride,
      untouched: !edited && kcalOverride == null && proteinOverride == null,
    );

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          // Clears the floating nav bar, which draws over this content.
          padding: AppLayout.screenPadding.add(
            const EdgeInsets.only(bottom: AppLayout.navClearance),
          ),
          children: [
            const Text('Goal', style: AppType.screenTitle),
            const SizedBox(height: 18),
            _TargetCard(
              kcal: shownKcal,
              macros: macros,
              caption: _caption(edited ? live : null, profile),
              // What the engine would say, shown only where it was overruled.
              // Recomputed live rather than stored, so it can sit a few kcal
              // from the figure originally agreed to; that is acceptable for an
              // advisory line and is why the headline still prefers what is
              // saved.
              suggestedKcal: kcalOverride == null ? null : liveTarget?.dailyKcal,
              suggestedProteinG:
                  proteinOverride == null ? null : liveTarget?.proteinG,
              advisory: _advisory(profile, shownKcal, kcalOverride),
              onEditKcal: () => _editKcal(profile, shownKcal),
              onEditProtein: () => _editProtein(profile, macros.protein),
              onResetKcal: () =>
                  _setOverrides(kcal: null, protein: proteinOverride),
              onResetProtein: () =>
                  _setOverrides(kcal: kcalOverride, protein: null),
            ),
            const SizedBox(height: 14),

            StepperRow(
              label: 'Current weight',
              detail: imperial ? 'pounds' : 'kilograms',
              value: _forDisplay(weight, imperial),
              suffix: imperial ? ' lb' : ' kg',
              min: _forDisplay(25, imperial),
              max: _forDisplay(400, imperial),
              onChanged: (v) => _edit(() => _weight = _toKg(v, imperial)),
            ),
            const SizedBox(height: 10),
            StepperRow(
              label: 'Goal weight',
              detail: imperial ? 'pounds' : 'kilograms',
              value: _forDisplay(target, imperial),
              suffix: imperial ? ' lb' : ' kg',
              min: _forDisplay(25, imperial),
              max: _forDisplay(400, imperial),
              onChanged: (v) => _edit(() => _target = _toKg(v, imperial)),
            ),
            const SizedBox(height: 10),
            StepperRow(
              label: target > weight ? 'Rate of gain' : 'Rate of loss',
              detail: '% of bodyweight per week',
              value: rate,
              suffix: ' %',
              step: 0.1,
              // The engine caps at 1%/week and corrects anything faster, so
              // the stepper stops there too: the limit is something you can
              // see coming rather than something that happens to you.
              min: 0.1,
              max: 1.0,
              decimals: 1,
              onChanged: (v) => _edit(() => _rate = v),
            ),

            const SizedBox(height: 26),
            const SectionLabel('About'),
            const SizedBox(height: 12),
            _UnitsRow(
              imperial: imperial,
              onChanged: (value) => _setUnits(profile, value),
            ),
            const SizedBox(height: 10),
            _AboutRow(
              label: 'Where the food data comes from',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SourcesScreen(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Changes apply from today. Days you have already logged keep the '
              'target they were measured against.\n\n'
              'Calori estimates. It does not diagnose, treat, or replace '
              'advice from a doctor or dietitian.',
              style: AppType.caption.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // -- Units --------------------------------------------------------------

  /// Pounds are shown whole. Stepping from an unrounded 171.96 lb would land
  /// on 171 on the first press, which reads as the number jumping.
  static double _forDisplay(double kg, bool imperial) =>
      imperial ? kgToPounds(kg).roundToDouble() : kg;

  static double _toKg(double shown, bool imperial) =>
      imperial ? poundsToKg(shown) : shown;

  Future<void> _setUnits(UserProfile profile, bool imperial) async {
    // Written straight through rather than debounced: this is a preference,
    // not a nudge, and the steppers beneath it change units as it lands.
    await ref
        .read(diaryRepositoryProvider)
        .saveProfile(_copy(profile, usesImperial: imperial));
  }

  // -- Overrides ----------------------------------------------------------

  /// The split to render, which is not always a fresh computation.
  ///
  /// With nothing hand-set and nothing being edited it is what was *saved* —
  /// re-deriving would risk showing a split a gram or two from the one the user
  /// agreed to. Otherwise the engine re-derives it, so carbs and fat follow an
  /// overridden calorie or protein figure rather than contradicting it.
  ({int protein, int carbs, int fat}) _macrosToShow({
    required UserProfile profile,
    required int? kcal,
    required double weightKg,
    required int? proteinOverride,
    required bool untouched,
  }) {
    if (untouched || kcal == null) {
      return (
        protein: profile.dailyProteinG,
        carbs: profile.dailyCarbsG,
        fat: profile.dailyFatG,
      );
    }
    return GoalEngine.macrosFor(
      kcal: kcal,
      weightKg: weightKg,
      proteinG: proteinOverride,
    );
  }

  void _setOverrides({required int? kcal, required int? protein}) {
    setState(() {
      _overridesTouched = true;
      _kcalOverride = kcal;
      _proteinOverride = protein;
    });
    _save?.cancel();
    _save = Timer(_saveDelay, _commit);
  }

  Future<void> _editKcal(UserProfile profile, int? current) async {
    final value = await _askForNumber(
      title: 'Daily calories',
      unit: 'kcal',
      initial: current,
      hint:
          'Calori works a target out from your height, weight, age and '
          'activity. If you have one you trust more, use that.',
    );
    if (value == null) return;
    _setOverrides(
      kcal: value,
      protein: _overridesTouched ? _proteinOverride : profile.proteinOverrideG,
    );
  }

  Future<void> _editProtein(UserProfile profile, int current) async {
    final value = await _askForNumber(
      title: 'Daily protein',
      unit: 'g',
      initial: current,
      hint:
          'Carbs and fat are worked out from whatever is left of your calories '
          'once this is set aside.',
    );
    if (value == null) return;
    _setOverrides(
      kcal: _overridesTouched ? _kcalOverride : profile.kcalOverride,
      protein: value,
    );
  }

  /// A one-field sheet. Null if it was dismissed without a usable number.
  Future<int?> _askForNumber({
    required String title,
    required String unit,
    required int? initial,
    required String hint,
  }) async {
    final value = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      builder: (_) => _NumberSheet(
        title: title,
        unit: unit,
        initial: initial,
        hint: hint,
      ),
    );

    // Zero and negatives are not a target, they are a typo or an empty field.
    return value == null || value <= 0 ? null : value;
  }

  /// The quiet note under a hand-set target that sits below the safety floor.
  ///
  /// Deliberately not a block, and deliberately not a warning triangle. Saying
  /// the thing once, plainly, and then getting out of the way is what respects
  /// someone's right to decide without pretending the app has no opinion.
  String? _advisory(UserProfile profile, int? kcal, int? kcalOverride) {
    if (kcal == null || kcalOverride == null) return null;
    final floor = profile.sex.calorieFloor;
    if (kcal >= floor) return null;
    return 'That is below the $floor kcal a day Calori would suggest as a '
        'minimum. Your call — worth mentioning to a doctor or dietitian.';
  }

  // -- Saving -------------------------------------------------------------

  void _edit(VoidCallback change) {
    setState(change);
    _save?.cancel();
    _save = Timer(_saveDelay, _commit);
  }

  /// The rate implied by a stored profile's target date.
  ///
  /// The profile records a date rather than a rate, so this runs the
  /// arithmetic backwards. Falls back to half a percent — the engine's own
  /// comfortable middle — when there is no date, which is every maintenance
  /// goal.
  double _rateFrom(UserProfile profile) {
    final date = profile.targetDate;
    final delta = (profile.targetWeightKg - profile.weightKg).abs();

    if (date == null || delta < 0.05 || profile.weightKg <= 0) return 0.5;

    final weeks = date.difference(DateTime.now()).inDays / 7;
    if (weeks <= 0) return 0.5;

    return ((delta / weeks) / profile.weightKg * 100).clamp(0.1, 1.0);
  }

  /// Runs the same engine onboarding uses, converting rate into weeks.
  ///
  /// The design thinks in "% per week"; [GoalEngine] thinks in weeks. Neither
  /// is wrong — a rate is what a person chooses, a duration is what the
  /// arithmetic needs.
  GoalResult _evaluate(
    UserProfile profile,
    double weight,
    double target,
    double rate,
  ) {
    final delta = (target - weight).abs();
    final weekly = weight * rate / 100;
    final weeks = delta < 0.05 || weekly <= 0
        ? 12
        : (delta / weekly).ceil().clamp(1, 520);

    return GoalEngine.calculate(
      GoalRequest(
        sex: profile.sex,
        age: profile.age,
        heightCm: profile.heightCm,
        weightKg: weight,
        targetWeightKg: target,
        activity: profile.activity,
        weeks: weeks,
        today: DateTime.now(),
      ),
    );
  }

  String _caption(GoalResult? result, UserProfile saved) => switch (result) {
    null => _savedCaption(saved),
    GoalRefused(:final message) => message,
    GoalAdjusted(:final explanation) => explanation,
    GoalAccepted(:final target) => switch (target.direction) {
      GoalDirection.maintain => 'Enough to hold your current weight.',
      _ => _pace(target),
    },
  };

  String _savedCaption(UserProfile saved) {
    final date = saved.targetDate;
    if (date == null || saved.targetWeightKg == saved.weightKg) {
      return 'Enough to hold your current weight.';
    }
    final key = date.year * 10000 + date.month * 100 + date.day;
    return 'On track to reach your target by ${formatDayKeyShort(key)}.';
  }

  String _pace(GoalTarget target) {
    final rate = target.ratePercentPerWeek.abs().toStringAsFixed(1);
    final date = target.targetDate;

    if (date == null) return 'At $rate % per week.';

    final key = date.year * 10000 + date.month * 100 + date.day;
    return 'At $rate % per week you reach your target '
        'by ${formatDayKeyShort(key)}.';
  }

  /// [targetDate], [kcalOverride] and [proteinOverrideG] are passed through
  /// verbatim rather than defaulted to the existing value, because null is a
  /// meaningful state for all three and `??` cannot clear one.
  UserProfile _copy(
    UserProfile p, {
    double? weightKg,
    double? targetWeightKg,
    int? dailyKcal,
    int? dailyProteinG,
    int? dailyCarbsG,
    int? dailyFatG,
    DateTime? targetDate,
    int? kcalOverride,
    int? proteinOverrideG,
    bool? usesImperial,
  }) => UserProfile(
    sex: p.sex,
    age: p.age,
    heightCm: p.heightCm,
    weightKg: weightKg ?? p.weightKg,
    targetWeightKg: targetWeightKg ?? p.targetWeightKg,
    activity: p.activity,
    dailyKcal: dailyKcal ?? p.dailyKcal,
    dailyProteinG: dailyProteinG ?? p.dailyProteinG,
    dailyCarbsG: dailyCarbsG ?? p.dailyCarbsG,
    dailyFatG: dailyFatG ?? p.dailyFatG,
    targetDate: targetDate,
    kcalOverride: kcalOverride,
    proteinOverrideG: proteinOverrideG,
    usesImperial: usesImperial ?? p.usesImperial,
  );

  Future<void> _commit() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null || !mounted) return;

    final weight = _weight ?? profile.weightKg;
    final target = _target ?? profile.targetWeightKg;
    final rate = _rate ?? _rateFrom(profile);
    final kcalOverride =
        _overridesTouched ? _kcalOverride : profile.kcalOverride;
    final proteinOverride =
        _overridesTouched ? _proteinOverride : profile.proteinOverrideG;

    final goal = switch (_evaluate(profile, weight, target, rate)) {
      GoalAccepted(:final target) => target,
      GoalAdjusted(:final target) => target,
      // A refused goal is not written on its own. The card already says why,
      // and the steppers stay where they were left, so the correction is one
      // press away rather than a reset.
      GoalRefused() => null,
    };

    // A hand-set calorie target is the user overruling the engine, though, and
    // discarding it because the engine disapproves is exactly the restriction
    // they asked not to have. With one set, the goal is saved either way.
    final kcal = kcalOverride ?? goal?.dailyKcal;
    if (kcal == null) return;

    final macros = GoalEngine.macrosFor(
      kcal: kcal,
      weightKg: weight,
      proteinG: proteinOverride,
    );

    await ref.read(diaryRepositoryProvider).saveProfile(
      _copy(
        profile,
        weightKg: weight,
        targetWeightKg: target,
        // Mirrored into the plain daily figures, so the ring, the day totals
        // and the calendar need to know nothing about overrides.
        dailyKcal: kcal,
        dailyProteinG: macros.protein,
        dailyCarbsG: macros.carbs,
        dailyFatG: macros.fat,
        targetDate: goal?.targetDate,
        kcalOverride: kcalOverride,
        proteinOverrideG: proteinOverride,
      ),
    );
  }
}

/// The daily target, and one line saying what it means.
class _TargetCard extends StatelessWidget {
  const _TargetCard({
    required this.kcal,
    required this.macros,
    required this.caption,
    required this.suggestedKcal,
    required this.suggestedProteinG,
    required this.advisory,
    required this.onEditKcal,
    required this.onEditProtein,
    required this.onResetKcal,
    required this.onResetProtein,
  });

  final int? kcal;
  final ({int protein, int carbs, int fat}) macros;
  final String caption;

  /// Non-null only where the corresponding figure was set by hand. The engine's
  /// opinion stays on screen, so overruling it is a visible choice rather than
  /// a disappearance.
  final int? suggestedKcal;
  final int? suggestedProteinG;

  final String? advisory;

  final VoidCallback onEditKcal;
  final VoidCallback onEditProtein;
  final VoidCallback onResetKcal;
  final VoidCallback onResetProtein;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.durationFor(context, AppMotion.fadeIn),
      curve: AppMotion.standard,
      child: CaloriCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: SectionLabel('Daily target')),
            const SizedBox(height: 6),
            Semantics(
              button: true,
              label: 'Set your daily calories by hand',
              child: GestureDetector(
                onTap: onEditKcal,
                behavior: HitTestBehavior.opaque,
                // The pencil is the only thing that says this number can be
                // changed. Without it the card looks like a readout, and the
                // hand-set target may as well not exist for anyone who does not
                // happen to tap it.
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Flexible and scaled down: at this type size a
                    // four-figure target is already wider than a 320pt phone's
                    // card, and the Center it used to sit in was quietly
                    // wrapping it. Inside a Row it takes its natural width and
                    // overflows, so it has to be allowed to shrink instead.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          kcal == null ? '—' : formatKcal(kcal!.toDouble()),
                          style: AppType.goalTarget.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
            if (suggestedKcal != null)
              _Suggestion(
                text:
                    'Calori suggests ${formatKcal(suggestedKcal!.toDouble())}',
                onReset: onResetKcal,
              ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                caption,
                style: AppType.secondary.copyWith(height: 1.55),
                textAlign: TextAlign.center,
              ),
            ),
            if (advisory != null) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  advisory!,
                  style: AppType.caption.copyWith(height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (kcal != null) ...[
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // The whole row edits protein. Carbs and fat are derived from it
              // and the calorie target, so they are not separately settable —
              // offering that would invite an arithmetic the app would then
              // have to refuse, which is the opposite of the point.
              Semantics(
                button: true,
                label: 'Set your daily protein by hand',
                child: GestureDetector(
                  onTap: onEditProtein,
                  behavior: HitTestBehavior.opaque,
                  child: MacroRow(
                    proteinG: macros.protein.toDouble(),
                    carbsG: macros.carbs.toDouble(),
                    fatG: macros.fat.toDouble(),
                    editable: true,
                  ),
                ),
              ),
              if (suggestedProteinG != null)
                _Suggestion(
                  text: 'Calori suggests $suggestedProteinG g protein',
                  onReset: onResetProtein,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What the engine would have said, and the way back to it.
class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.text, required this.onReset});

  final String text;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text,
              style: AppType.caption,
              textAlign: TextAlign.center,
            ),
          ),
          const Text(' · ', style: AppType.caption),
          Semantics(
            button: true,
            child: GestureDetector(
              onTap: onReset,
              behavior: HitTestBehavior.opaque,
              child: Text(
                'Reset',
                style: AppType.caption.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One number, asked for on its own.
///
/// A StatefulWidget so the sheet owns its controller. Creating it in the caller
/// and disposing it when the sheet's future completes disposes it while the
/// dismiss animation is still painting the field.
class _NumberSheet extends StatefulWidget {
  const _NumberSheet({
    required this.title,
    required this.unit,
    required this.initial,
    required this.hint,
  });

  final String title;
  final String unit;
  final int? initial;
  final String hint;

  @override
  State<_NumberSheet> createState() => _NumberSheetState();
}

class _NumberSheetState extends State<_NumberSheet> {
  late final _controller = TextEditingController(
    text: widget.initial?.toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(int.tryParse(_controller.text));

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the field clear of the keyboard, which otherwise covers the only
      // control on the sheet.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(widget.title),
            const SizedBox(height: 12),
            NumberField(
              controller: _controller,
              suffix: widget.unit,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 14),
            Text(widget.hint, style: AppType.caption.copyWith(height: 1.5)),
            const SizedBox(height: 18),
            PillButton(label: 'Save', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

/// Metric or imperial, for every height and weight the app shows.
class _UnitsRow extends StatelessWidget {
  const _UnitsRow({required this.imperial, required this.onChanged});

  final bool imperial;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CaloriCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          const Expanded(child: Text('Units', style: AppType.body)),
          SelectableChip(
            label: 'kg / cm',
            selected: !imperial,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 8),
          SelectableChip(
            label: "lb / ft'in",
            selected: imperial,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CaloriCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppType.body)),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(child: Text('No goal set yet.', style: AppType.body)),
    );
  }
}
