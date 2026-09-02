// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The draft must outlive any individual step.
///
/// `@riverpod` is auto-dispose by default, and each step only reads this while
/// it is on screen — so without keepAlive the provider is torn down the instant
/// a step unmounts and every answer is silently discarded. The flow still
/// advances, which is what makes it so easy to miss: you reach the last screen
/// with an empty draft.

@ProviderFor(Onboarding)
final onboardingProvider = OnboardingProvider._();

/// The draft must outlive any individual step.
///
/// `@riverpod` is auto-dispose by default, and each step only reads this while
/// it is on screen — so without keepAlive the provider is torn down the instant
/// a step unmounts and every answer is silently discarded. The flow still
/// advances, which is what makes it so easy to miss: you reach the last screen
/// with an empty draft.
final class OnboardingProvider
    extends $NotifierProvider<Onboarding, OnboardingDraft> {
  /// The draft must outlive any individual step.
  ///
  /// `@riverpod` is auto-dispose by default, and each step only reads this while
  /// it is on screen — so without keepAlive the provider is torn down the instant
  /// a step unmounts and every answer is silently discarded. The flow still
  /// advances, which is what makes it so easy to miss: you reach the last screen
  /// with an empty draft.
  OnboardingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingHash();

  @$internal
  @override
  Onboarding create() => Onboarding();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingDraft value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingDraft>(value),
    );
  }
}

String _$onboardingHash() => r'73541274153b76e0f521a304d7383cc057dd44dd';

/// The draft must outlive any individual step.
///
/// `@riverpod` is auto-dispose by default, and each step only reads this while
/// it is on screen — so without keepAlive the provider is torn down the instant
/// a step unmounts and every answer is silently discarded. The flow still
/// advances, which is what makes it so easy to miss: you reach the last screen
/// with an empty draft.

abstract class _$Onboarding extends $Notifier<OnboardingDraft> {
  OnboardingDraft build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OnboardingDraft, OnboardingDraft>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OnboardingDraft, OnboardingDraft>,
              OnboardingDraft,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The current step.
///
/// Kept alive for the same reason as the draft: the two must not be able to
/// disagree about how far through the flow the user is.

@ProviderFor(OnboardingCursor)
final onboardingCursorProvider = OnboardingCursorProvider._();

/// The current step.
///
/// Kept alive for the same reason as the draft: the two must not be able to
/// disagree about how far through the flow the user is.
final class OnboardingCursorProvider
    extends $NotifierProvider<OnboardingCursor, OnboardingStep> {
  /// The current step.
  ///
  /// Kept alive for the same reason as the draft: the two must not be able to
  /// disagree about how far through the flow the user is.
  OnboardingCursorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingCursorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingCursorHash();

  @$internal
  @override
  OnboardingCursor create() => OnboardingCursor();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingStep value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingStep>(value),
    );
  }
}

String _$onboardingCursorHash() => r'7637aa878113de0288e49e57e4994e4b3ecf3472';

/// The current step.
///
/// Kept alive for the same reason as the draft: the two must not be able to
/// disagree about how far through the flow the user is.

abstract class _$OnboardingCursor extends $Notifier<OnboardingStep> {
  OnboardingStep build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OnboardingStep, OnboardingStep>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OnboardingStep, OnboardingStep>,
              OnboardingStep,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The engine's verdict on the draft as it currently stands.
///
/// Null until there is enough to judge. Recomputed on every keystroke, which is
/// what lets the target screen correct a too-fast rate while the user is still
/// looking at the input that caused it.

@ProviderFor(goalPreview)
final goalPreviewProvider = GoalPreviewProvider._();

/// The engine's verdict on the draft as it currently stands.
///
/// Null until there is enough to judge. Recomputed on every keystroke, which is
/// what lets the target screen correct a too-fast rate while the user is still
/// looking at the input that caused it.

final class GoalPreviewProvider
    extends $FunctionalProvider<GoalResult?, GoalResult?, GoalResult?>
    with $Provider<GoalResult?> {
  /// The engine's verdict on the draft as it currently stands.
  ///
  /// Null until there is enough to judge. Recomputed on every keystroke, which is
  /// what lets the target screen correct a too-fast rate while the user is still
  /// looking at the input that caused it.
  GoalPreviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalPreviewProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalPreviewHash();

  @$internal
  @override
  $ProviderElement<GoalResult?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoalResult? create(Ref ref) {
    return goalPreview(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalResult? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalResult?>(value),
    );
  }
}

String _$goalPreviewHash() => r'f6d55bc856e37ba9df3011df8ea37f021a20cbf4';
