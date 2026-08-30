// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Kept alive so switching tabs and coming back does not reset the shell.
///
/// A Notifier rather than StateProvider: Riverpod 3 dropped StateProvider, and
/// the rest of this codebase is generated notifiers anyway.

@ProviderFor(ShellScreenController)
final shellScreenControllerProvider = ShellScreenControllerProvider._();

/// Kept alive so switching tabs and coming back does not reset the shell.
///
/// A Notifier rather than StateProvider: Riverpod 3 dropped StateProvider, and
/// the rest of this codebase is generated notifiers anyway.
final class ShellScreenControllerProvider
    extends $NotifierProvider<ShellScreenController, ShellScreen> {
  /// Kept alive so switching tabs and coming back does not reset the shell.
  ///
  /// A Notifier rather than StateProvider: Riverpod 3 dropped StateProvider, and
  /// the rest of this codebase is generated notifiers anyway.
  ShellScreenControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shellScreenControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shellScreenControllerHash();

  @$internal
  @override
  ShellScreenController create() => ShellScreenController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShellScreen value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShellScreen>(value),
    );
  }
}

String _$shellScreenControllerHash() =>
    r'd36efc76af4e85fb0b6c6be46eacf12304557b93';

/// Kept alive so switching tabs and coming back does not reset the shell.
///
/// A Notifier rather than StateProvider: Riverpod 3 dropped StateProvider, and
/// the rest of this codebase is generated notifiers anyway.

abstract class _$ShellScreenController extends $Notifier<ShellScreen> {
  ShellScreen build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ShellScreen, ShellScreen>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ShellScreen, ShellScreen>,
              ShellScreen,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
