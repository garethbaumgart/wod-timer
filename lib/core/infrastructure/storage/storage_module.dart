import 'package:injectable/injectable.dart';
import 'package:wod_timer/core/infrastructure/storage/local_storage_service.dart';

/// Injectable module for storage services.
@module
abstract class StorageModule {
  /// Provides the [LocalStorageService] implementation.
  @lazySingleton
  LocalStorageService get localStorageService => FileLocalStorageService();
}
