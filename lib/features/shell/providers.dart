/// Which screen the shell is showing.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The shell's destinations.
///
/// Calendar and search are members even though neither has a nav tab: both are
/// destinations within the shell rather than pushed routes, so the nav bar
/// stays put and returning to Home is one tap rather than a system back
/// gesture. The prototype does the same — its `showNav` covers home, search,
/// calendar and goal alike.
enum ShellScreen { home, calendar, search, goal }

/// Kept alive so switching tabs and coming back does not reset the shell.
///
/// A Notifier rather than StateProvider: Riverpod 3 dropped StateProvider, and
/// the rest of this codebase is generated notifiers anyway.
@Riverpod(keepAlive: true)
class ShellScreenController extends _$ShellScreenController {
  @override
  ShellScreen build() => ShellScreen.home;

  void go(ShellScreen screen) => state = screen;
}
