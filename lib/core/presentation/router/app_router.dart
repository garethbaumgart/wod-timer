import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wod_timer/core/presentation/pages/settings_page.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/router/placeholder_pages.dart';
import 'package:wod_timer/features/timer/presentation/pages/pages.dart';

part 'app_router.g.dart';

/// Provider for the app router.
@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => PlaceholderHomePage(
          onTimerSelected: (timerType) {
            context.go(AppRoutes.timerSetupPath(timerType));
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.timerSetup,
        name: 'timerSetup',
        builder: (context, state) {
          final timerType = state.pathParameters['timerType'] ?? 'amrap';
          if (!TimerTypes.isValid(timerType)) {
            return const PlaceholderPage(
              title: 'Invalid Timer Type',
              subtitle: 'The selected timer type is not valid.',
            );
          }
          return _buildSetupPage(timerType);
        },
        routes: [
          GoRoute(
            path: 'active',
            name: 'timerActive',
            builder: (context, state) {
              final timerType = state.pathParameters['timerType'] ?? 'amrap';
              return TimerActivePage(timerType: timerType);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.presets,
        name: 'presets',
        builder: (context, state) => const PlaceholderPage(
          title: 'Saved Presets',
          subtitle: 'Your saved workout configurations',
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    errorBuilder: (context, state) => const PlaceholderPage(
      title: 'Page Not Found',
      subtitle: 'The requested page could not be found.',
    ),
  );
}

Widget _buildSetupPage(String timerType) {
  switch (timerType) {
    case TimerTypes.amrap:
      return const AmrapSetupPage();
    case TimerTypes.forTime:
      return const ForTimeSetupPage();
    case TimerTypes.emom:
      return const EmomSetupPage();
    case TimerTypes.tabata:
      return const TabataSetupPage();
    default:
      return const PlaceholderPage(
        title: 'Invalid Timer Type',
        subtitle: 'The selected timer type is not valid.',
      );
  }
}
