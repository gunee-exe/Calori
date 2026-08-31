/// Starting the photo path.
///
/// The nav bar's camera button calls [onCapturePressed] directly — no
/// intermediate sheet. The prototype puts the camera in the centre of the nav
/// precisely so that photographing a meal is one tap from anywhere, and a menu
/// in between would spend that tap on a question.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../home/providers.dart';
import '../shell/providers.dart';
import 'capture_screen.dart';
import 'providers.dart';
import 'review_screen.dart';

/// Opens the viewfinder.
///
/// The capture screen owns the shutter, the gallery shortcut and the optional
/// details field, and pushes the review screen itself once a photo exists.
Future<void> onCapturePressed(BuildContext context, WidgetRef ref) async {
  if (!ref.read(photoLoggingAvailableProvider)) {
    _notConfigured(context);
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const CaptureScreen()),
  );
}

void _notConfigured(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Photo estimates are not set up in this build.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Opens the photo library, then the review screen.
///
/// Still `image_picker`, and still needs no permission: the Android 13+ photo
/// picker returns the one image the user chose. This is also what the capture
/// screen falls back to when camera permission is refused.
Future<void> onGalleryPressed(BuildContext context, WidgetRef ref) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  // Without a deployed Worker the photo path cannot work. Say so plainly and
  // point at the path that always can, rather than opening a picker whose
  // result has nowhere to go.
  if (!ref.read(photoLoggingAvailableProvider)) {
    _notConfigured(context);
    return;
  }

  final File? photo;
  try {
    photo = await ref
        .read(photoCaptureProvider.notifier)
        .pick(ImageSource.gallery);
  } catch (error, stack) {
    // Never fail silently here. The original version let an exception escape
    // into an async gap with no catch, so the camera closed and *nothing
    // happened* — no screen, no message, no way to tell whether the app had
    // even registered the photo.
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'calori',
        context: ErrorDescription('picking a meal photo'),
      ),
    );
    messenger.showSnackBar(
      const SnackBar(
        content: Text("Couldn't read that photo. You can add food by hand."),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  if (photo == null) {
    // Backing out of the camera is not an error and needs no comment. Only a
    // genuine failure to open it does.
    if (ref.read(photoCaptureProvider).hasError) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't open that. You can add food by hand."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return;
  }

  final captured = photo;
  final dayKey = ref.read(selectedDayProvider);

  // Started before the route is pushed, so the request is already in flight
  // while the transition plays.
  unawaited(ref.read(photoAnalysisProvider.notifier).run(captured));

  await navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => ReviewScreen(photo: captured, dayKey: dayKey),
    ),
  );
}

/// Opens manual food search for the selected day.
///
/// This is what the `+` button on Home does. It goes straight to Add food
/// rather than offering a menu: manual entry is a first-class path, not one
/// option among several.
///
/// A shell destination rather than a pushed route, so the nav bar stays
/// visible — which is what the prototype does, and what lets someone abandon a
/// search with one tap on Home instead of a back gesture.
void onAddFoodPressed(WidgetRef ref) {
  ref.read(shellScreenControllerProvider.notifier).go(ShellScreen.search);
}
