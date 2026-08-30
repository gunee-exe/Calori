/// The bottom navigation shell.
///
/// Three destinations, and the camera is not one of them: the photo path is
/// reached from the Home FAB, because logging is an action rather than a place.
library;

import 'package:flutter/material.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/tokens.dart';
import '../calendar/calendar_screen.dart';
import '../goal/goal_screen.dart';
import '../home/home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = [
    (icon: Icons.today_outlined, active: Icons.today, label: 'Today'),
    (
      icon: Icons.calendar_month_outlined,
      active: Icons.calendar_month,
      label: 'Calendar',
    ),
    (icon: Icons.flag_outlined, active: Icons.flag, label: 'Goal'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(
        // IndexedStack rather than swapping children: it keeps each tab's
        // scroll position and its providers alive, so returning to Today does
        // not re-run the ring's entry animation or reset the date strip.
        index: _index,
        children: const [HomeScreen(), CalendarScreen(), GoalScreen()],
      ),
      bottomNavigationBar: _NavBar(
        index: _index,
        onSelect: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.index,
    required this.onSelect,
    required this.destinations,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final List<({IconData icon, IconData active, String label})> destinations;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (final (i, destination) in destinations.indexed)
                Expanded(
                  child: _NavItem(
                    destination: destination,
                    selected: i == index,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ({IconData icon, IconData active, String label}) destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = selected ? AppColors.primary : AppColors.textTertiary;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppMotion.durationFor(context, AppMotion.fadeIn),
          curve: AppMotion.standard,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? destination.active : destination.icon,
                size: 22,
                color: colour,
              ),
              const SizedBox(height: 3),
              Text(
                destination.label,
                style: AppType.caption.copyWith(color: colour),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
