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
import 'providers.dart';
import 'review_screen.dart';

/// Opens the camera, then the review screen.
Future<void> onCapturePressed(BuildContext context, WidgetRef ref) =>
    _capture(context, ref, ImageSource.camera);

/// Opens the photo library, then the review screen.
Future<void> onGalleryPressed(BuildContext context, WidgetRef ref) =>
    _capture(context, ref, ImageSource.gallery);

Future<void> _capture(
  BuildContext context,
  WidgetRef ref,
  ImageSource source,
) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  // Without a deployed Worker the photo path cannot work. Say so plainly and
  // point at the path that always can, rather than opening a camera whose
  // result has nowhere to go.
  if (!ref.read(photoLoggingAvailableProvider)) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Photo estimates are not set up in this build.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final File? photo;
  try {
    photo = await ref.read(photoCaptureProvider.notifier).pick(source);
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
