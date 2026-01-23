import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:wod_timer/injection.config.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Environment names for dependency injection
abstract class Env {
  static const dev = 'dev';
  static const prod = 'prod';
  static const test = 'test';
}

/// Configures all dependencies for the application.
///
/// Call this in main() before runApp().
/// Pass [environment] to configure environment-specific dependencies.
@InjectableInit(preferRelativeImports: false)
Future<void> configureDependencies({String environment = Env.prod}) async =>
    getIt.init(environment: environment);
