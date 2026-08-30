/// Which screen the shell is showing.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The shell's destinations.
///
/// Calendar is a member even though it has no nav tab: it is a destination
/// within the shell rather than a pushed route, so the nav bar stays put and
/// returning to Home is one tap rather than a system back gesture.
enum ShellScreen { home, calendar, goal }

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
