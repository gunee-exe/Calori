/// The photo path (UC-03, UC-04).
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/food_name.dart';
import '../../data/ai/vision_service.dart';
import '../../data/providers.dart';
import '../../domain/models/enums.dart';

part 'providers.g.dart';

/// The Worker endpoint, supplied at build time.
///
/// Empty in a build without a deployed Worker, which is a normal state — the
/// camera button is then simply not offered, rather than offered and broken.
const kWorkerEndpoint = String.fromEnvironment('CALORI_WORKER_URL');
const kWorkerSecret = String.fromEnvironment('CALORI_WORKER_SECRET');

/// The longest edge the app uploads, and the JPEG quality.
///
/// About 120 KB per photo. Larger costs the user's data and the model's time
/// without measurably improving the estimate; smaller starts losing the detail
/// that portion size is judged from.
const _maxEdge = 1024.0;
const _quality = 80;

@Riverpod(keepAlive: true)
VisionService visionService(Ref ref) {
  final service = VisionService(
    endpoint: kWorkerEndpoint,
    // A stable per-install id, so the Worker can rate limit without any
    // account, login, or anything that identifies the person.
    deviceId: ref.watch(deviceIdProvider),
    sharedSecret: kWorkerSecret.isEmpty ? null : kWorkerSecret,
  );
  ref.onDispose(service.dispose);
  return service;
}

/// A random id generated once per install and kept in the diary database.
///
/// Not a user id: it identifies a copy of the app for rate limiting only, is
/// never sent anywhere except the Worker, and dies with the install.
@Riverpod(keepAlive: true)
String deviceId(Ref ref) {
  // Derived rather than stored, so there is no extra table and nothing to
  // migrate. Stable for the life of the install because the diary file is.
  return _installId ??= DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}

String? _installId;

/// Whether the photo path can be offered at all.
@riverpod
bool photoLoggingAvailable(Ref ref) =>
    ref.watch(visionServiceProvider).isConfigured;

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
@Riverpod(keepAlive: true)
class PhotoCapture extends _$PhotoCapture {
  @override
  FutureOr<File?> build() => null;

  Future<File?> pick(ImageSource source) async {
    state = const AsyncLoading();

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: _maxEdge,
        maxHeight: _maxEdge,
        imageQuality: _quality,
      );

      if (picked == null) {
        // Cancelling is not an error. Returning to the previous state keeps
        // any photo already taken.
        state = const AsyncData(null);
        return null;
      }

      // Copied out of the OS cache, which Android clears without warning. The
      // file has to survive long enough to retry a failed analysis.
      final directory = await getApplicationDocumentsDirectory();
      final photos = Directory(p.join(directory.path, 'photos'));
      await photos.create(recursive: true);

      final destination = File(
        p.join(photos.path, '${DateTime.now().millisecondsSinceEpoch}.jpg'),
      );
      await File(picked.path).copy(destination.path);

      state = AsyncData(destination);
      return destination;
    } catch (error, stack) {
      state = AsyncError(error, stack);
      return null;
    }
  }

  void clear() => state = const AsyncData(null);
}

/// Analysis of the captured photo, checking learned values first.
///
/// keepAlive for the same reason as [PhotoCapture]: the request is started
/// before the review screen is pushed, so for the first frames of the
/// transition nothing is watching it.
@Riverpod(keepAlive: true)
class PhotoAnalysis extends _$PhotoAnalysis {
  @override
  FutureOr<List<ProposedItem>?> build() => null;

  Future<void> run(File photo, {String? hint}) async {
    state = const AsyncLoading();

    try {
      final bytes = await photo.readAsBytes();
      final proposed = await ref
          .read(visionServiceProvider)
          .analyse(bytes, hint: hint);

      state = AsyncData(await _applyLearnedValues(proposed));
    } on VisionException catch (error, stack) {
      state = AsyncError(error, stack);
    } catch (error, stack) {
      // Reported, not swallowed. On Whispr a catch block turned server errors
      // into UI messages and hid the real failure for weeks — the discipline
      // the Worker applies to upstream responses applies equally here. The
      // user still sees the friendly message; the original reaches the logs.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'calori',
          context: ErrorDescription('analysing a meal photo'),
        ),
      );
      state = AsyncError(const VisionException(VisionFailure.server), stack);
    }
  }

  /// Replaces the model's numbers with values the user has already accepted.
  ///
  /// UC-04: a meal logged twice must report the same figures both times.
  /// Consistency matters more here than marginal accuracy — numbers that drift
  /// between two photos of the same dinner read as a bug and cost trust faster
  /// than a small error does.
  Future<List<ProposedItem>> _applyLearnedValues(
    List<ProposedItem> proposed,
  ) async {
    final diary = ref.read(diaryRepositoryProvider);
    final out = <ProposedItem>[];

    for (final item in proposed) {
      final cached = await diary.cached(normaliseFoodName(item.name));
      if (cached == null) {
        out.add(item);
        continue;
      }

      out.add(
        ProposedItem(
          name: item.name,
          grams: item.grams,
          // The portion still comes from the photo — only the per-gram
          // nutrition is remembered.
          macros: cached.macrosFor(item.grams),
          // Shown sharp and unblurred: the user accepted these numbers before,
          // so asking them to confirm again would be nagging.
          confidence: Confidence.high,
          confidenceReason: 'you have logged this before',
          portionDesc: item.portionDesc,
          fromCache: true,
        ),
      );
    }

    return out;
  }

  /// Adjusts one item's portion, rescaling its macros.
  void resize(int index, double grams) {
    final items = state.value;
    if (items == null || index < 0 || index >= items.length) return;

    final updated = [...items];
    updated[index] = items[index].copyWith(
      grams: grams,
      macros: items[index].macrosFor(grams),
    );
    state = AsyncData(updated);
  }

  void removeAt(int index) {
    final items = state.value;
    if (items == null || index < 0 || index >= items.length) return;
    state = AsyncData([...items]..removeAt(index));
  }

  void add(ProposedItem item) {
    state = AsyncData([...?state.value, item]);
  }

  void clear() => state = const AsyncData(null);
}
