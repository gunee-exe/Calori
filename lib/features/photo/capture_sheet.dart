/// The choice between camera, gallery, and typing it in.
///
/// Manual entry is listed alongside the two photo options rather than hidden
/// behind them. It is the path that always works — no network, no permission,
/// no model — and `01-concept.md` is explicit that it must never feel like the
/// fallback you resort to when the clever thing fails.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/section_label.dart';
import '../search/search_screen.dart';
import 'providers.dart';
import 'review_screen.dart';

Future<void> showCaptureSheet(
  BuildContext context,
  WidgetRef ref, {
  required int dayKey,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) => _CaptureSheet(dayKey: dayKey),
  );
}

class _CaptureSheet extends ConsumerWidget {
  const _CaptureSheet({required this.dayKey});

  final int dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoAvailable = ref.watch(photoLoggingAvailableProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Add food'),
            const SizedBox(height: 14),
            if (photoAvailable) ...[
              _Option(
                icon: Icons.photo_camera_outlined,
                label: 'Take a photo',
                detail: 'Estimate from a picture of your meal',
                onTap: () => _capture(context, ref, ImageSource.camera),
              ),
              const SizedBox(height: 10),
              _Option(
                icon: Icons.image_outlined,
                label: 'Choose a photo',
                detail: 'Use a picture you already have',
                onTap: () => _capture(context, ref, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
            ],
            _Option(
              icon: Icons.search,
              label: 'Search for a food',
              detail: photoAvailable
                  ? 'Works offline, and always exact'
                  : 'Search 11,000 foods, offline',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SearchScreen(dayKey: dayKey),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _capture(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    navigator.pop();

    final photo = await ref.read(photoCaptureProvider.notifier).pick(source);
    if (photo == null) {
      // Either the user backed out, which needs no comment, or the picker
      // failed. Only the latter is worth a message.
      final state = ref.read(photoCaptureProvider);
      if (state.hasError) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Couldn't open that. You can add food by hand."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Started before the screen is pushed, so the request is already in flight
    // while the route transition plays.
    unawaited(ref.read(photoAnalysisProvider.notifier).run(photo));

    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewScreen(photo: photo, dayKey: dayKey),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppType.body),
                  const SizedBox(height: 2),
                  Text(detail, style: AppType.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
