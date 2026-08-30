/// Design tokens transcribed from the "Bright Blue" prototype
/// (`Ui/Calorie Tracker v3 - Bright Blue.dc.html`), which is the visual source
/// of truth for this app.
///
/// These are literal values, deliberately. Do not regenerate them from a
/// Material seed colour — `ColorScheme.fromSeed` will not reproduce this
/// palette, and the relationships between the greys carry meaning.
library;

import 'package:flutter/material.dart';

/// The palette.
///
/// One rule governs the whole scheme: **there is no red.** Over-target state is
/// carried by [AppColors.neutralOver], a desaturated grey-blue. Section 4 of
/// `01-concept.md` is explicit that going over budget is information, not
/// failure, and colour is the loudest place that promise gets broken.
abstract final class AppColors {
  /// App background. Every screen sits on this.
  static const bg = Color(0xFFEAEFF9);

  /// Cards, the nav bar, bottom sheets.
  static const surface = Color(0xFFFFFFFF);

  /// The calorie ring, the camera FAB, the active tab, the daily target figure.
  static const primary = Color(0xFF2E5BFF);
  static const primaryPressed = Color(0xFF1B3FCC);

  /// Selected chips, the active tab pill, the selected calendar day.
  static const primaryContainer = Color(0xFFEAF0FF);
  static const primaryContainerPressed = Color(0xFFDCE6FF);

  static const textPrimary = Color(0xFF0B0D12);
  static const textSecondary = Color(0xFF5A6273);
  static const textTertiary = Color(0xFF9AA2B4);

  /// Hairline borders and dividers.
  static const border = Color(0xFFE9EDF5);

  /// Over-target arcs and the "not logged" calendar dot.
  ///
  /// This token replaces red. If you ever reach for [Colors.red] in this app,
  /// use this instead.
  static const neutralOver = Color(0xFFC7CEDC);

  /// Unfilled track of the 224px home ring.
  static const ringTrack = Color(0xFFD9E1F0);

  /// Unfilled track of the small calendar-cell rings.
  static const miniRingTrack = Color(0xFFEDF1F8);

  /// Skeleton shimmer: [shimmerBase] swept by [shimmerHighlight].
  static const shimmerBase = Color(0xFFEEF1F7);
  static const shimmerHighlight = Color(0xFFF8FAFD);

  /// Macro dots, used at 8px diameter and nowhere else. Carbs and fat are
  /// secondary information and never get a filled bar or a large surface.
  static const carbs = Color(0xFFFFA114);
  static const fat = Color(0xFF8B5CF6);

  /// Backdrop behind the capture details sheet.
  static const scrim = Color(0x660B0D12);
}

/// Corner radii. Cards are 20; anything small and interactive is a stadium.
abstract final class AppRadius {
  static const xs = 10.0;

  /// Date chips and square icon buttons.
  static const sm = 16.0;

  /// The default card radius.
  static const md = 20.0;

  /// The calendar card, slightly larger than a standard card.
  static const lg = 22.0;

  /// The floating camera FAB (52px diameter).
  static const fab = 26.0;

  /// Top corners of a bottom sheet.
  static const sheet = 28.0;

  /// The floating bottom nav bar (64px tall).
  static const nav = 32.0;
}

/// Elevation is expressed as composited shadow pairs, not Material elevation.
/// A single soft shadow reads flat against this palette; the near shadow
/// supplies the edge and the far shadow supplies the lift.
abstract final class AppShadows {
  /// Standard card.
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0A0B0D12), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0F0B0D12), blurRadius: 32, offset: Offset(0, 12)),
  ];

  /// Card under press or hover.
  static const cardRaised = <BoxShadow>[
    BoxShadow(color: Color(0x0F0B0D12), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x1A0B0D12), blurRadius: 40, offset: Offset(0, 16)),
  ];

  /// The nav bar and buttons that float over content.
  static const floating = <BoxShadow>[
    BoxShadow(color: Color(0x1A0B0D12), blurRadius: 32, offset: Offset(0, 8)),
  ];

  /// The blue FAB carries a tinted shadow, not a neutral one.
  static const primaryGlow = <BoxShadow>[
    BoxShadow(color: Color(0x522E5BFF), blurRadius: 20, offset: Offset(0, 6)),
  ];
}

/// Layout constants that recur across screens.
abstract final class AppLayout {
  static const screenTop = 16.0;
  static const screenSide = 20.0;

  /// Bottom padding on scrollable screens, sized to clear the floating nav bar.
  static const screenBottom = 96.0;

  static const screenPadding = EdgeInsets.fromLTRB(
    screenSide,
    screenTop,
    screenSide,
    screenBottom,
  );

  /// Minimum interactive target. Every button in the prototype respects this.
  static const minTapTarget = 44.0;

  static const navInset = 16.0;
  static const navBottomInset = 20.0;
  static const navHeight = 64.0;

  static const fabSize = 52.0;

  /// The centre FAB overhangs the top edge of the nav bar.
  static const fabOverlap = -12.0;

  /// Home ring geometry.
  static const ringSize = 224.0;
  static const ringStroke = 26.0;

  /// The dim second lap drawn inside the main ring when over target.
  static const ringOverStroke = 8.0;

  /// Radius of the over-target lap relative to the main ring (68 / 94).
  static const ringOverRadiusFactor = 68.0 / 94.0;

  /// Number of discrete pips in the protein bar.
  static const proteinPips = 12;
}

/// Type scale. Poppins 400/500/600, bundled in `assets/fonts` so the app has no
/// runtime font dependency and works offline on first launch.
///
/// Every style that can render a number carries [FontFeature.tabularFigures].
/// Without it, digit widths shift as values animate and the ring percentage and
/// macro totals visibly jitter.
/// Type scale.
///
/// **Every style carries an explicit colour.** That is not redundancy: this
/// theme assigns these tokens straight into `TextTheme`, replacing Material's
/// own coloured defaults. A style with a null colour therefore resolves to
/// Flutter's fallback, which is **white** — invisible on this app's near-white
/// background, and invisible in widget tests too, because `find.text()` does
/// not care what colour something rendered in.
abstract final class AppType {
  static const family = 'Poppins';

  static const _tabular = <FontFeature>[FontFeature.tabularFigures()];

  /// The daily target on the Goal and onboarding result screens.
  static const goalTarget = TextStyle(
    fontFamily: family,
    color: AppColors.textPrimary,
    fontSize: 56,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: -1.12,
    fontFeatures: _tabular,
  );

  /// The percentage inside the home ring.
  static const ringPercent = TextStyle(
    fontFamily: family,
    color: AppColors.textPrimary,
    fontSize: 48,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: -0.96,
    fontFeatures: _tabular,
  );

  /// Screen titles: "Add food", "Goal".
  static const screenTitle = TextStyle(
    fontFamily: family,
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.28,
  );

  /// The date numeral inside a calendar cell.
  ///
  /// Small and light: inside a ring, the ring carries the information and the
  /// number is only there to say which day it belongs to.
  static const calendarDay = TextStyle(
    fontFamily: family,
    color: AppColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.1,
    fontFeatures: _tabular,
  );

  /// The selected day's calorie figure on the calendar summary card.
  static const dayKcal = TextStyle(
    fontFamily: family,
    color: AppColors.textPrimary,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.26,
    fontFeatures: _tabular,
  );

  /// Numbers on the calendar stat cards.
  static const statNumber = TextStyle(
    fontFamily: family,
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );

  /// Section headers, month label, stepper values.
  static const sectionHeader = TextStyle(
    fontFamily: family,
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );

  /// The calorie figure on a meal card.
  static const mealKcal = TextStyle(
    fontFamily: family,
    color: AppColors.textPrimary,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );

  static const bodyStrong = TextStyle(
    fontFamily: family,
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );

  static const body = TextStyle(
    fontFamily: family,
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static const secondary = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  /// The small uppercase label above every card section: "PROTEIN", "TODAY",
  /// "DAILY TARGET". The wide tracking is what makes it read as a label rather
  /// than as shouting.
  static const sectionLabel = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.32,
    color: AppColors.textSecondary,
  );

  /// Source provenance badges: "USDA", "INDB", "CoFID".
  static const sourceBadge = TextStyle(
    fontFamily: family,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    color: AppColors.textSecondary,
  );
}
