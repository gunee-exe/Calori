/// The viewfinder (UC-03, UC-04).
///
/// A live preview with a shutter, a Gallery button, and an optional "Add
/// details" field. The details are the point of UC-04: a free-text hint like
/// *"chicken biryani, one plate, about 300g"* goes to the model as `user_hint`,
/// so it applies the numbers the user supplied instead of inferring scale from
/// pixels. Portion estimation is the documented weak point of every app in this
/// category, and this is the cheapest available fix.
///
/// UC-04's constraint is load-bearing: **the field never takes focus
/// automatically.** Capture stays one tap for the majority who skip it.
library;

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/section_label.dart';
import '../home/providers.dart';
import 'capture.dart';
import 'providers.dart';
import 'review_screen.dart';

/// 720p. `image_picker` produced 1024px at q80 (~120 KB); this is a little
/// larger and still far inside the Worker's 8 MB cap. Going lower starts
/// costing the detail that portion size is judged from.
const _resolution = ResolutionPreset.high;

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _ready;

  /// Set when the camera cannot be opened at all — refused permission, or no
  /// camera on the device. The screen then offers the gallery instead, which
  /// needs no permission.
  String? _unavailable;

  bool _taking = false;

  /// The photo that has been taken but not yet sent.
  ///
  /// Null means the live viewfinder is showing. Non-null freezes the screen on
  /// the shot with Retake and Send, which is the whole point: the details field
  /// is directly above the shutter, and sending on the shutter press made it
  /// unreachable at the only moment it is any use.
  File? _shot;

  /// The optional hint. Held here rather than in a provider: it belongs to this
  /// capture and should not survive it.
  String _details = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    // Android reclaims the camera when the app goes to the background, and a
    // controller that survives the trip renders a black rectangle on return.
    // Tear it down and build a new one rather than trying to revive it.
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      controller.dispose();
      setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      _start();
    }
  }

  Future<void> _start() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _unavailable = 'This device has no camera.');
        return;
      }

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        back,
        _resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      final ready = controller.initialize();
      setState(() {
        _controller = controller;
        _ready = ready;
        _unavailable = null;
      });
      await ready;
      if (mounted) setState(() {});
    } on CameraException catch (error) {
      // The common case is a refused permission. Say which, and offer the path
      // that still works rather than a dead screen.
      setState(() {
        _unavailable = error.code == 'CameraAccessDenied'
            ? 'Calori does not have permission to use the camera.'
            : 'The camera could not be opened.';
      });
    }
  }

  /// Takes the photo and stops there.
  ///
  /// Deliberately does **not** send it. Firing the request on the shutter press
  /// made the "Add details" pill directly above it useless: you frame the shot,
  /// take it, and only then think "that was a chicken karahi, about 300 g".
  /// Nothing reaches the model until [_send].
  Future<void> _shoot() async {
    final controller = _controller;
    if (_taking || controller == null || !controller.value.isInitialized) return;

    setState(() => _taking = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      final shot = await controller.takePicture();
      final photo = await ref
          .read(photoCaptureProvider.notifier)
          .adopt(File(shot.path));

      if (!mounted) return;
      setState(() {
        _taking = false;
        _shot = photo;
      });
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'calori',
          context: ErrorDescription('taking a photo'),
        ),
      );
      if (!mounted) return;
      setState(() => _taking = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't take that photo. Try the gallery instead."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Discards the shot and returns to the live preview.
  ///
  /// The file is deleted, not just forgotten. `adopt` copies every frame into
  /// app storage, so without this each rejected attempt is kept for the life of
  /// the install — and a rejected photo is one the user has already decided
  /// they do not want.
  Future<void> _discardShot() async {
    final photo = _shot;
    if (mounted) setState(() => _shot = null);
    if (photo == null) return;

    try {
      if (photo.existsSync()) await photo.delete();
    } catch (_) {
      // A file that will not delete is a leak, not something the user can act
      // on, and certainly not a reason to interrupt them.
    }
  }

  /// Sends the photo, with whatever details were typed alongside it.
  Future<void> _send() async {
    final photo = _shot;
    if (photo == null) return;

    final navigator = Navigator.of(context);
    final dayKey = ref.read(selectedDayProvider);
    final hint = _details.trim();

    // Started before the route is pushed, so the request is already in flight
    // while the transition plays.
    unawaited(
      ref
          .read(photoAnalysisProvider.notifier)
          .run(photo, hint: hint.isEmpty ? null : hint),
    );

    // Replaces rather than stacks: coming back from the review screen should
    // land on Home, not on a viewfinder pointed at a meal already logged.
    await navigator.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ReviewScreen(photo: photo, dayKey: dayKey),
      ),
    );
  }

  /// Leaves the screen, discarding an unsent shot rather than orphaning it.
  Future<void> _close() async {
    final navigator = Navigator.of(context);
    await _discardShot();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.viewfinder,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _Preview(
            controller: _controller,
            ready: _ready,
            unavailable: _unavailable,
            shot: _shot,
          ),

          Positioned(
            top: 12,
            left: 16,
            child: _RoundButton(
              icon: Icons.close,
              label: 'Close',
              onTap: _close,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The details pill stays put across both states. That is
                    // the point of the change: it is reachable *after* the
                    // shutter, when the user actually knows what they shot.
                    _DetailsButton(
                      details: _details,
                      onEdit: _editDetails,
                    ),
                    const SizedBox(height: 20),
                    if (_shot == null)
                      _ShutterRow(
                        onGallery: () => onGalleryPressed(context, ref),
                        onShoot: _unavailable == null && !_taking
                            ? _shoot
                            : null,
                      )
                    else
                      _ConfirmRow(onRetake: _discardShot, onSend: _send),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editDetails() async {
    final entered = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.scrim,
      builder: (_) => _DetailsSheet(initial: _details),
    );

    if (entered != null) setState(() => _details = entered);
  }
}

/// The live preview, the shot just taken, or the reason there is neither.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.controller,
    required this.ready,
    required this.unavailable,
    this.shot,
  });

  final CameraController? controller;
  final Future<void>? ready;
  final String? unavailable;

  /// A photo taken and not yet sent. Freezes the screen on it so the user can
  /// see what they are about to send, and add details to it.
  final File? shot;

  @override
  Widget build(BuildContext context) {
    final taken = shot;
    if (taken != null) {
      // Cover, matching the live preview it replaces, so the framing does not
      // appear to jump at the moment the shutter fires.
      return Image.file(taken, fit: BoxFit.cover);
    }

    if (unavailable != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                unavailable!,
                style: AppType.body.copyWith(height: 1.55),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choosing an existing photo still works.',
                style: AppType.secondary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final camera = controller;
    if (camera == null || ready == null) return const SizedBox.shrink();

    return FutureBuilder<void>(
      future: ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            !camera.value.isInitialized) {
          return const SizedBox.shrink();
        }
        // Cover rather than contain: a letterboxed preview inside a full-bleed
        // design reads as a broken image.
        return FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: camera.value.previewSize?.height ?? 1,
            height: camera.value.previewSize?.width ?? 1,
            child: CameraPreview(camera),
          ),
        );
      },
    );
  }
}

/// "Add details", or a preview of what was typed.
class _DetailsButton extends StatelessWidget {
  const _DetailsButton({required this.details, required this.onEdit});

  final String details;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final has = details.trim().isNotEmpty;

    return Semantics(
      button: true,
      label: has ? 'Details: $details. Tap to edit.' : 'Add details',
      child: GestureDetector(
        onTap: onEdit,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.overlaySurface,
            borderRadius: BorderRadius.circular(999),
            boxShadow: AppShadows.floating,
          ),
          child: Text(
            has ? details.trim() : 'Add details',
            style: AppType.overlayLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ShutterRow extends StatelessWidget {
  const _ShutterRow({required this.onGallery, required this.onShoot});

  final VoidCallback onGallery;
  final VoidCallback? onShoot;

  @override
  Widget build(BuildContext context) {
    // A Stack, not a Row with a balancing spacer. The prototype pads the right
    // with a fixed 84 to centre the shutter against the Gallery pill, which
    // overflows a 320pt phone by a few pixels. Centring the shutter outright
    // gives the same result at every width and cannot overflow.
    return SizedBox(
      height: AppLayout.shutterSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _GalleryButton(onTap: onGallery),
          ),
          _Shutter(onTap: onShoot),
        ],
      ),
    );
  }
}

/// Retake or Send, shown once a photo has been taken.
///
/// Replaces the shutter row rather than sitting beside it: with a shot on
/// screen there is nothing to shoot, and leaving a live shutter there would
/// invite a second photo over the first.
class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.onRetake, required this.onSend});

  final VoidCallback onRetake;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppLayout.shutterSize,
      child: Row(
        children: [
          Expanded(child: _OverlayAction(label: 'Retake', onTap: onRetake)),
          const SizedBox(width: 12),
          Expanded(
            child: _OverlayAction(
              label: 'Send',
              onTap: onSend,
              primary: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// A pill sized for the viewfinder overlay.
class _OverlayAction extends StatelessWidget {
  const _OverlayAction({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primary ? AppColors.primary : AppColors.overlaySurface,
            borderRadius: BorderRadius.circular(999),
            boxShadow: primary ? AppShadows.primaryGlow : AppShadows.floating,
          ),
          child: Text(
            label,
            style: primary
                ? AppType.overlayAction.copyWith(color: AppColors.surface)
                : AppType.overlayAction,
          ),
        ),
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Choose an existing photo',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.overlaySurface,
            borderRadius: BorderRadius.circular(999),
            boxShadow: AppShadows.floating,
          ),
          child: const Text('Gallery', style: AppType.overlayAction),
        ),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Take photo',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          // Dimmed rather than hidden while the camera is starting or a shot is
          // in flight: a control that disappears makes the row reflow under
          // the thumb.
          opacity: enabled ? 1 : 0.5,
          duration: AppMotion.durationFor(context, AppMotion.fadeIn),
          child: Container(
            width: AppLayout.shutterSize,
            height: AppLayout.shutterSize,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 4),
              boxShadow: AppShadows.primaryGlow,
            ),
          ),
        ),
      ),
    );
  }
}

/// The details sheet.
///
/// Returns the entered text, or null if dismissed without pressing Done.
class _DetailsSheet extends StatefulWidget {
  const _DetailsSheet({required this.initial});

  final String initial;

  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the sheet above the keyboard rather than letting it cover the
      // field the sheet exists for.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Add details'),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              // Autofocus *here* is right and does not violate UC-04: the user
              // has already chosen to open this sheet. The constraint is that
              // the field never grabs focus on the capture screen itself.
              autofocus: true,
              style: AppType.body,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => Navigator.of(context).pop(_controller.text),
              decoration: const InputDecoration(
                hintText: 'chicken biryani, one plate, about 300g',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            const SizedBox(height: 22),
            PillButton(
              label: 'Done',
              minHeight: 50,
              onPressed: () => Navigator.of(context).pop(_controller.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: AppLayout.minTapTarget,
          height: AppLayout.minTapTarget,
          decoration: const BoxDecoration(
            // Solid enough to stay legible over a preview whose colours are
            // unknown.
            color: AppColors.overlaySurface,
            shape: BoxShape.circle,
            boxShadow: AppShadows.floating,
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
