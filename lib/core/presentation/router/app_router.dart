import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/core/presentation/router/placeholder_pages.dart';

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
          return PlaceholderPage(
            title: '${timerType.toUpperCase()} Setup',
            subtitle: 'Configure your workout parameters',
          );
        },
        routes: [
          GoRoute(
            path: 'active',
            name: 'timerActive',
            builder: (context, state) {
              final timerType = state.pathParameters['timerType'] ?? 'amrap';
              return PlaceholderPage(
                title: '${timerType.toUpperCase()} Timer',
                subtitle: 'Active workout timer',
              );
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
        builder: (context, state) => const PlaceholderPage(
          title: 'Settings',
          subtitle: 'App preferences and configuration',
        ),
      ),
    ],
    errorBuilder: (context, state) => const PlaceholderPage(
      title: 'Page Not Found',
      subtitle: 'The requested page could not be found.',
    ),
  );
}
