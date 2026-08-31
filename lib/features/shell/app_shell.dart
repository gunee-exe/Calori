/// The floating navigation bar and the screens it holds.
///
/// Two tabs, not three. The prototype's nav is `Home | camera | Goal`, with the
/// camera raised out of the bar between them — logging is the app's primary
/// action, so it gets the centre and a shape nothing else has.
///
/// **Calendar is not a tab.** It is reached from the button beside the date
/// strip on Home, and it keeps the nav bar visible while showing neither tab as
/// active. That mirrors the prototype exactly, where `tab()` marks a tab active
/// only when `screen === id`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../calendar/calendar_screen.dart';
import '../goal/goal_screen.dart';
import '../photo/capture.dart';
import '../search/search_screen.dart';
import '../home/home_screen.dart';
import 'providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(shellScreenControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      // The bar floats over the content rather than displacing it, so each
      // screen carries its own bottom padding to clear it.
      body: Stack(
        children: [
          IndexedStack(
            // IndexedStack rather than swapping children: it keeps each
            // screen's scroll position and providers alive, so returning to
            // Home does not re-run the ring's entry animation.
            index: screen.index,
            children: const [
              HomeScreen(),
              CalendarScreen(),
              SearchScreen(),
              GoalScreen(),
            ],
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: FloatingNavBar(),
          ),
        ],
      ),
    );
  }
}

class FloatingNavBar extends ConsumerWidget {
  const FloatingNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screen = ref.watch(shellScreenControllerProvider);

    return Container(
      height: AppLayout.navBarHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppLayout.navBarHeight / 2),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: _NavTab(
                icon: Icons.home_outlined,
                label: 'Home',
                active: screen == ShellScreen.home,
                onTap: () => ref
                    .read(shellScreenControllerProvider.notifier)
                    .go(ShellScreen.home),
              ),
            ),
          ),
          // Fixed width so the two tabs stay symmetric regardless of which
          // one is expanded showing its label.
          const SizedBox(width: 80, child: Center(child: CameraButton())),
          Expanded(
            child: Center(
              child: _NavTab(
                icon: Icons.person_outline,
                label: 'Goal',
                active: screen == ShellScreen.goal,
                onTap: () => ref
                    .read(shellScreenControllerProvider.notifier)
                    .go(ShellScreen.goal),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tab that shows its label only while active.
///
/// The label appearing is the whole animation: the pill grows, the icon takes
/// on the primary colour, and the word fades in slightly behind the growth so
/// it does not appear to stretch.
class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = active ? AppColors.primary : AppColors.textTertiary;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.durationFor(context, AppMotion.navPill),
          curve: AppMotion.standard,
          height: AppLayout.minTapTarget,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: colour),
              Flexible(
                child: AnimatedSize(
                duration: AppMotion.durationFor(context, AppMotion.navPill),
                curve: AppMotion.standard,
                // The label is allowed to shrink. On a 320pt phone the two
                // tabs plus the fixed 80pt camera slot leave the active pill
                // about 7px short, and a nav bar that overflows is worse than
                // one whose word is a little tight.
                child: active
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          label,
                          style: AppType.navLabel.copyWith(color: colour),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                        ),
                      )
                    : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The raised camera button at the centre of the nav bar.
///
/// Lifted 12px out of the bar so it reads as the primary action rather than a
/// third tab. It opens the camera directly — one tap from anywhere to a photo,
/// which is the point of putting it here.
///
/// Long-press picks from the photo library instead. That is a stopgap: the
/// design's capture screen has a proper Gallery button beside the shutter, but
/// that needs a real viewfinder — the `camera` package — rather than handing
/// off to the system camera as this does. Until then a long-press keeps the
/// path reachable without inventing a control the design does not have.
class CameraButton extends ConsumerWidget {
  const CameraButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Transform.translate(
      offset: const Offset(0, -12),
      child: Semantics(
        button: true,
        label: 'Take a photo of your food',
        hint: 'Long press to choose an existing photo',
        child: GestureDetector(
          onTap: () => onCapturePressed(context, ref),
          onLongPress: () => onGalleryPressed(context, ref),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: AppLayout.navCameraSize,
            height: AppLayout.navCameraSize,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: AppShadows.primaryGlow,
            ),
            child: const Icon(
              Icons.photo_camera_outlined,
              color: AppColors.surface,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
