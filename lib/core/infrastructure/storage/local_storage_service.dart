import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wod_timer/core/domain/failures/storage_failure.dart';

/// Interface for local storage operations.
abstract class LocalStorageService {
  /// Read a JSON map from storage.
  Future<Either<StorageFailure, Map<String, dynamic>?>> readJson(String key);

  /// Write a JSON map to storage.
  Future<Either<StorageFailure, Unit>> writeJson(
    String key,
    Map<String, dynamic> data,
  );

  /// Read a list of JSON maps from storage.
  Future<Either<StorageFailure, List<Map<String, dynamic>>>> readJsonList(
    String key,
  );

  /// Write a list of JSON maps to storage.
  Future<Either<StorageFailure, Unit>> writeJsonList(
    String key,
    List<Map<String, dynamic>> data,
  );

  /// Delete data for a key.
  Future<Either<StorageFailure, Unit>> delete(String key);

  /// Check if data exists for a key.
  Future<Either<StorageFailure, bool>> exists(String key);

  /// Watch for changes to a key.
  Stream<Either<StorageFailure, List<Map<String, dynamic>>>> watchJsonList(
    String key,
  );
}

/// File-based implementation of [LocalStorageService].
///
/// Stores JSON data in the app's documents directory.
class FileLocalStorageService implements LocalStorageService {
  FileLocalStorageService({Directory? baseDirectory})
    : _baseDirectory = baseDirectory;

  Directory? _baseDirectory;
  final _watchControllers =
      <
        String,
        StreamController<Either<StorageFailure, List<Map<String, dynamic>>>>
      >{};

  Future<Directory> get _directory async {
    if (_baseDirectory != null) return _baseDirectory!;
    final appDir = await getApplicationDocumentsDirectory();
    _baseDirectory = Directory('${appDir.path}/wod_timer');
    final exists = await _baseDirectory!.exists();
    if (!exists) {
      await _baseDirectory!.create(recursive: true);
    }
    return _baseDirectory!;
  }

  Future<File> _getFile(String key) async {
    final dir = await _directory;
    return File('${dir.path}/$key.json');
  }

  @override
  Future<Either<StorageFailure, Map<String, dynamic>?>> readJson(
    String key,
  ) async {
    try {
      final file = await _getFile(key);
      final exists = await file.exists();
      if (!exists) {
        return right(null);
      }
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      return right(json);
    } on FormatException catch (e) {
      return left(StorageFailure.corrupted(message: e.message));
    } on FileSystemException catch (e) {
      return left(StorageFailure.readError(message: e.message));
    } on Exception catch (e) {
      return left(StorageFailure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<StorageFailure, Unit>> writeJson(
    String key,
    Map<String, dynamic> data,
  ) async {
    try {
      final file = await _getFile(key);
      final contents = jsonEncode(data);
      await file.writeAsString(contents);
      return right(unit);
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 28) {
        return left(const StorageFailure.storageFull());
      }
      return left(StorageFailure.writeError(message: e.message));
    } on Exception catch (e) {
      return left(StorageFailure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<StorageFailure, List<Map<String, dynamic>>>> readJsonList(
    String key,
  ) async {
    try {
      final file = await _getFile(key);
      final exists = await file.exists();
      if (!exists) {
        return right(<Map<String, dynamic>>[]);
      }
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as List<dynamic>;
      final list = json.cast<Map<String, dynamic>>();
      return right(list);
    } on FormatException catch (e) {
      return left(StorageFailure.corrupted(message: e.message));
    } on FileSystemException catch (e) {
      return left(StorageFailure.readError(message: e.message));
    } on Exception catch (e) {
      return left(StorageFailure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<StorageFailure, Unit>> writeJsonList(
    String key,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      final file = await _getFile(key);
      final contents = jsonEncode(data);
      await file.writeAsString(contents);

      // Notify watchers
      _notifyWatchers(key, data);

      return right(unit);
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 28) {
        return left(const StorageFailure.storageFull());
      }
      return left(StorageFailure.writeError(message: e.message));
    } on Exception catch (e) {
      return left(StorageFailure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<StorageFailure, Unit>> delete(String key) async {
    try {
      final file = await _getFile(key);
      final exists = await file.exists();
      if (exists) {
        await file.delete();
      }

      // Notify watchers with empty list
      _notifyWatchers(key, []);

      return right(unit);
    } on FileSystemException catch (e) {
      return left(StorageFailure.deleteError(message: e.message));
    } on Exception catch (e) {
      return left(StorageFailure.unexpected(message: e.toString()));
    }
  }

  @override
  Future<Either<StorageFailure, bool>> exists(String key) async {
    try {
      final file = await _getFile(key);
      final exists = await file.exists();
      return right(exists);
    } on Exception catch (e) {
      return left(StorageFailure.unexpected(message: e.toString()));
    }
  }

  @override
  Stream<Either<StorageFailure, List<Map<String, dynamic>>>> watchJsonList(
    String key,
  ) {
    if (!_watchControllers.containsKey(key)) {
      _watchControllers[key] =
          StreamController<
            Either<StorageFailure, List<Map<String, dynamic>>>
          >.broadcast(
            onListen: () async {
              // Emit current value when first listener subscribes
              final result = await readJsonList(key);
              _watchControllers[key]?.add(result);
            },
          );
    }
    return _watchControllers[key]!.stream;
  }

  void _notifyWatchers(String key, List<Map<String, dynamic>> data) {
    if (_watchControllers.containsKey(key)) {
      _watchControllers[key]!.add(right(data));
    }
  }

  /// Dispose of all watch controllers.
  Future<void> dispose() async {
    for (final controller in _watchControllers.values) {
      await controller.close();
    }
    _watchControllers.clear();
  }
}
