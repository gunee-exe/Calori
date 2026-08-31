// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(visionService)
final visionServiceProvider = VisionServiceProvider._();

final class VisionServiceProvider
    extends $FunctionalProvider<VisionService, VisionService, VisionService>
    with $Provider<VisionService> {
  VisionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visionServiceHash();

  @$internal
  @override
  $ProviderElement<VisionService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VisionService create(Ref ref) {
    return visionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VisionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VisionService>(value),
    );
  }
}

String _$visionServiceHash() => r'4d672de4877f8f94ff041dfffcc689f69b5b15b5';

/// A random id generated once per install and kept in the diary database.
///
/// Not a user id: it identifies a copy of the app for rate limiting only, is
/// never sent anywhere except the Worker, and dies with the install.

@ProviderFor(deviceId)
final deviceIdProvider = DeviceIdProvider._();

/// A random id generated once per install and kept in the diary database.
///
/// Not a user id: it identifies a copy of the app for rate limiting only, is
/// never sent anywhere except the Worker, and dies with the install.

final class DeviceIdProvider extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// A random id generated once per install and kept in the diary database.
  ///
  /// Not a user id: it identifies a copy of the app for rate limiting only, is
  /// never sent anywhere except the Worker, and dies with the install.
  DeviceIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceIdHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return deviceId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$deviceIdHash() => r'e58205a814b084d0d2aa5495e2b583b418100b59';

/// Whether the photo path can be offered at all.
///
/// The secret is checked, not just the endpoint. Now that the endpoint carries
/// a default its presence proves nothing about the build, while the secret is
/// exactly what a build has or has not been given — and without it the Worker
/// rejects every request. Testing it here is what keeps a plain
/// `flutter build apk` honest: the button explains itself instead of sending a
/// request that is certain to come back 401.

@ProviderFor(photoLoggingAvailable)
final photoLoggingAvailableProvider = PhotoLoggingAvailableProvider._();

/// Whether the photo path can be offered at all.
///
/// The secret is checked, not just the endpoint. Now that the endpoint carries
/// a default its presence proves nothing about the build, while the secret is
/// exactly what a build has or has not been given — and without it the Worker
/// rejects every request. Testing it here is what keeps a plain
/// `flutter build apk` honest: the button explains itself instead of sending a
/// request that is certain to come back 401.

final class PhotoLoggingAvailableProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the photo path can be offered at all.
  ///
  /// The secret is checked, not just the endpoint. Now that the endpoint carries
  /// a default its presence proves nothing about the build, while the secret is
  /// exactly what a build has or has not been given — and without it the Worker
  /// rejects every request. Testing it here is what keeps a plain
  /// `flutter build apk` honest: the button explains itself instead of sending a
  /// request that is certain to come back 401.
  PhotoLoggingAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoLoggingAvailableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoLoggingAvailableHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return photoLoggingAvailable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$photoLoggingAvailableHash() =>
    r'e82504226157da3eb8dba54b84665fe8b76726a7';

/// Picks a photo and downscales it.
///
/// `image_picker` resizes during decode, so the full-size original never enters
/// memory — which matters on the low-end Androids this app targets, where a
/// 50 MP camera image is enough to be killed for.
///
/// **keepAlive is required, not an optimisation.** Nothing watches this while
/// the camera is open: the caller holds only the notifier. An auto-dispose
/// provider is therefore torn down during the await, and writing `state` on the
/// way back throws on a disposed notifier — which surfaces as the camera
/// closing and absolutely nothing happening. On a real phone the camera app can
/// also background the whole activity for a minute or more, which makes the
/// disposal a certainty rather than a race.

@ProviderFor(PhotoCapture)
final photoCaptureProvider = PhotoCaptureProvider._();

/// Picks a photo and downscales it.
///
/// `image_picker` resizes during decode, so the full-size original never enters
/// memory — which matters on the low-end Androids this app targets, where a
/// 50 MP camera image is enough to be killed for.
///
/// **keepAlive is required, not an optimisation.** Nothing watches this while
/// the camera is open: the caller holds only the notifier. An auto-dispose
/// provider is therefore torn down during the await, and writing `state` on the
/// way back throws on a disposed notifier — which surfaces as the camera
/// closing and absolutely nothing happening. On a real phone the camera app can
/// also background the whole activity for a minute or more, which makes the
/// disposal a certainty rather than a race.
final class PhotoCaptureProvider
    extends $AsyncNotifierProvider<PhotoCapture, File?> {
  /// Picks a photo and downscales it.
  ///
  /// `image_picker` resizes during decode, so the full-size original never enters
  /// memory — which matters on the low-end Androids this app targets, where a
  /// 50 MP camera image is enough to be killed for.
  ///
  /// **keepAlive is required, not an optimisation.** Nothing watches this while
  /// the camera is open: the caller holds only the notifier. An auto-dispose
  /// provider is therefore torn down during the await, and writing `state` on the
  /// way back throws on a disposed notifier — which surfaces as the camera
  /// closing and absolutely nothing happening. On a real phone the camera app can
  /// also background the whole activity for a minute or more, which makes the
  /// disposal a certainty rather than a race.
  PhotoCaptureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoCaptureProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoCaptureHash();

  @$internal
  @override
  PhotoCapture create() => PhotoCapture();
}

String _$photoCaptureHash() => r'3efc8693e030bb9f771b6effd19a52d054315314';

/// Picks a photo and downscales it.
///
/// `image_picker` resizes during decode, so the full-size original never enters
/// memory — which matters on the low-end Androids this app targets, where a
/// 50 MP camera image is enough to be killed for.
///
/// **keepAlive is required, not an optimisation.** Nothing watches this while
/// the camera is open: the caller holds only the notifier. An auto-dispose
/// provider is therefore torn down during the await, and writing `state` on the
/// way back throws on a disposed notifier — which surfaces as the camera
/// closing and absolutely nothing happening. On a real phone the camera app can
/// also background the whole activity for a minute or more, which makes the
/// disposal a certainty rather than a race.

abstract class _$PhotoCapture extends $AsyncNotifier<File?> {
  FutureOr<File?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<File?>, File?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<File?>, File?>,
              AsyncValue<File?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Analysis of the captured photo, checking learned values first.
///
/// keepAlive for the same reason as [PhotoCapture]: the request is started
/// before the review screen is pushed, so for the first frames of the
/// transition nothing is watching it.

@ProviderFor(PhotoAnalysis)
final photoAnalysisProvider = PhotoAnalysisProvider._();

/// Analysis of the captured photo, checking learned values first.
///
/// keepAlive for the same reason as [PhotoCapture]: the request is started
/// before the review screen is pushed, so for the first frames of the
/// transition nothing is watching it.
final class PhotoAnalysisProvider
    extends $AsyncNotifierProvider<PhotoAnalysis, List<ProposedItem>?> {
  /// Analysis of the captured photo, checking learned values first.
  ///
  /// keepAlive for the same reason as [PhotoCapture]: the request is started
  /// before the review screen is pushed, so for the first frames of the
  /// transition nothing is watching it.
  PhotoAnalysisProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'photoAnalysisProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$photoAnalysisHash();

  @$internal
  @override
  PhotoAnalysis create() => PhotoAnalysis();
}

String _$photoAnalysisHash() => r'2cccfb9618803900da47fbad75a8e299af0fb9f8';

/// Analysis of the captured photo, checking learned values first.
///
/// keepAlive for the same reason as [PhotoCapture]: the request is started
/// before the review screen is pushed, so for the first frames of the
/// transition nothing is watching it.

abstract class _$PhotoAnalysis extends $AsyncNotifier<List<ProposedItem>?> {
  FutureOr<List<ProposedItem>?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ProposedItem>?>, List<ProposedItem>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ProposedItem>?>, List<ProposedItem>?>,
              AsyncValue<List<ProposedItem>?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
