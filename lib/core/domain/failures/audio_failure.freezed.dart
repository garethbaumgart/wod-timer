// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audio_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AudioFailure {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? fileName) loadError,
    required TResult Function(String? message) playbackError,
    required TResult Function(String fileName) fileNotFound,
    required TResult Function(String? format) unsupportedFormat,
    required TResult Function() permissionDenied,
    required TResult Function() deviceUnavailable,
    required TResult Function(String? message) unexpected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? fileName)? loadError,
    TResult? Function(String? message)? playbackError,
    TResult? Function(String fileName)? fileNotFound,
    TResult? Function(String? format)? unsupportedFormat,
    TResult? Function()? permissionDenied,
    TResult? Function()? deviceUnavailable,
    TResult? Function(String? message)? unexpected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? fileName)? loadError,
    TResult Function(String? message)? playbackError,
    TResult Function(String fileName)? fileNotFound,
    TResult Function(String? format)? unsupportedFormat,
    TResult Function()? permissionDenied,
    TResult Function()? deviceUnavailable,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadError value) loadError,
    required TResult Function(_PlaybackError value) playbackError,
    required TResult Function(_FileNotFound value) fileNotFound,
    required TResult Function(_UnsupportedFormat value) unsupportedFormat,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_DeviceUnavailable value) deviceUnavailable,
    required TResult Function(_Unexpected value) unexpected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadError value)? loadError,
    TResult? Function(_PlaybackError value)? playbackError,
    TResult? Function(_FileNotFound value)? fileNotFound,
    TResult? Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult? Function(_Unexpected value)? unexpected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadError value)? loadError,
    TResult Function(_PlaybackError value)? playbackError,
    TResult Function(_FileNotFound value)? fileNotFound,
    TResult Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AudioFailureCopyWith<$Res> {
  factory $AudioFailureCopyWith(
    AudioFailure value,
    $Res Function(AudioFailure) then,
  ) = _$AudioFailureCopyWithImpl<$Res, AudioFailure>;
}

/// @nodoc
class _$AudioFailureCopyWithImpl<$Res, $Val extends AudioFailure>
    implements $AudioFailureCopyWith<$Res> {
  _$AudioFailureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$LoadErrorImplCopyWith<$Res> {
  factory _$$LoadErrorImplCopyWith(
    _$LoadErrorImpl value,
    $Res Function(_$LoadErrorImpl) then,
  ) = __$$LoadErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? fileName});
}

/// @nodoc
class __$$LoadErrorImplCopyWithImpl<$Res>
    extends _$AudioFailureCopyWithImpl<$Res, _$LoadErrorImpl>
    implements _$$LoadErrorImplCopyWith<$Res> {
  __$$LoadErrorImplCopyWithImpl(
    _$LoadErrorImpl _value,
    $Res Function(_$LoadErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? fileName = freezed}) {
    return _then(
      _$LoadErrorImpl(
        fileName: freezed == fileName
            ? _value.fileName
            : fileName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$LoadErrorImpl implements _LoadError {
  const _$LoadErrorImpl({this.fileName});

  @override
  final String? fileName;

  @override
  String toString() {
    return 'AudioFailure.loadError(fileName: $fileName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadErrorImpl &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fileName);

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadErrorImplCopyWith<_$LoadErrorImpl> get copyWith =>
      __$$LoadErrorImplCopyWithImpl<_$LoadErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? fileName) loadError,
    required TResult Function(String? message) playbackError,
    required TResult Function(String fileName) fileNotFound,
    required TResult Function(String? format) unsupportedFormat,
    required TResult Function() permissionDenied,
    required TResult Function() deviceUnavailable,
    required TResult Function(String? message) unexpected,
  }) {
    return loadError(fileName);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? fileName)? loadError,
    TResult? Function(String? message)? playbackError,
    TResult? Function(String fileName)? fileNotFound,
    TResult? Function(String? format)? unsupportedFormat,
    TResult? Function()? permissionDenied,
    TResult? Function()? deviceUnavailable,
    TResult? Function(String? message)? unexpected,
  }) {
    return loadError?.call(fileName);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? fileName)? loadError,
    TResult Function(String? message)? playbackError,
    TResult Function(String fileName)? fileNotFound,
    TResult Function(String? format)? unsupportedFormat,
    TResult Function()? permissionDenied,
    TResult Function()? deviceUnavailable,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) {
    if (loadError != null) {
      return loadError(fileName);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadError value) loadError,
    required TResult Function(_PlaybackError value) playbackError,
    required TResult Function(_FileNotFound value) fileNotFound,
    required TResult Function(_UnsupportedFormat value) unsupportedFormat,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_DeviceUnavailable value) deviceUnavailable,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return loadError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadError value)? loadError,
    TResult? Function(_PlaybackError value)? playbackError,
    TResult? Function(_FileNotFound value)? fileNotFound,
    TResult? Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return loadError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadError value)? loadError,
    TResult Function(_PlaybackError value)? playbackError,
    TResult Function(_FileNotFound value)? fileNotFound,
    TResult Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (loadError != null) {
      return loadError(this);
    }
    return orElse();
  }
}

abstract class _LoadError implements AudioFailure {
  const factory _LoadError({final String? fileName}) = _$LoadErrorImpl;

  String? get fileName;

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadErrorImplCopyWith<_$LoadErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PlaybackErrorImplCopyWith<$Res> {
  factory _$$PlaybackErrorImplCopyWith(
    _$PlaybackErrorImpl value,
    $Res Function(_$PlaybackErrorImpl) then,
  ) = __$$PlaybackErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$PlaybackErrorImplCopyWithImpl<$Res>
    extends _$AudioFailureCopyWithImpl<$Res, _$PlaybackErrorImpl>
    implements _$$PlaybackErrorImplCopyWith<$Res> {
  __$$PlaybackErrorImplCopyWithImpl(
    _$PlaybackErrorImpl _value,
    $Res Function(_$PlaybackErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = freezed}) {
    return _then(
      _$PlaybackErrorImpl(
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$PlaybackErrorImpl implements _PlaybackError {
  const _$PlaybackErrorImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'AudioFailure.playbackError(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaybackErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaybackErrorImplCopyWith<_$PlaybackErrorImpl> get copyWith =>
      __$$PlaybackErrorImplCopyWithImpl<_$PlaybackErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? fileName) loadError,
    required TResult Function(String? message) playbackError,
    required TResult Function(String fileName) fileNotFound,
    required TResult Function(String? format) unsupportedFormat,
    required TResult Function() permissionDenied,
    required TResult Function() deviceUnavailable,
    required TResult Function(String? message) unexpected,
  }) {
    return playbackError(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? fileName)? loadError,
    TResult? Function(String? message)? playbackError,
    TResult? Function(String fileName)? fileNotFound,
    TResult? Function(String? format)? unsupportedFormat,
    TResult? Function()? permissionDenied,
    TResult? Function()? deviceUnavailable,
    TResult? Function(String? message)? unexpected,
  }) {
    return playbackError?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? fileName)? loadError,
    TResult Function(String? message)? playbackError,
    TResult Function(String fileName)? fileNotFound,
    TResult Function(String? format)? unsupportedFormat,
    TResult Function()? permissionDenied,
    TResult Function()? deviceUnavailable,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) {
    if (playbackError != null) {
      return playbackError(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadError value) loadError,
    required TResult Function(_PlaybackError value) playbackError,
    required TResult Function(_FileNotFound value) fileNotFound,
    required TResult Function(_UnsupportedFormat value) unsupportedFormat,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_DeviceUnavailable value) deviceUnavailable,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return playbackError(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadError value)? loadError,
    TResult? Function(_PlaybackError value)? playbackError,
    TResult? Function(_FileNotFound value)? fileNotFound,
    TResult? Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return playbackError?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadError value)? loadError,
    TResult Function(_PlaybackError value)? playbackError,
    TResult Function(_FileNotFound value)? fileNotFound,
    TResult Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (playbackError != null) {
      return playbackError(this);
    }
    return orElse();
  }
}

abstract class _PlaybackError implements AudioFailure {
  const factory _PlaybackError({final String? message}) = _$PlaybackErrorImpl;

  String? get message;

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaybackErrorImplCopyWith<_$PlaybackErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$FileNotFoundImplCopyWith<$Res> {
  factory _$$FileNotFoundImplCopyWith(
    _$FileNotFoundImpl value,
    $Res Function(_$FileNotFoundImpl) then,
  ) = __$$FileNotFoundImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String fileName});
}

/// @nodoc
class __$$FileNotFoundImplCopyWithImpl<$Res>
    extends _$AudioFailureCopyWithImpl<$Res, _$FileNotFoundImpl>
    implements _$$FileNotFoundImplCopyWith<$Res> {
  __$$FileNotFoundImplCopyWithImpl(
    _$FileNotFoundImpl _value,
    $Res Function(_$FileNotFoundImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? fileName = null}) {
    return _then(
      _$FileNotFoundImpl(
        fileName: null == fileName
            ? _value.fileName
            : fileName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$FileNotFoundImpl implements _FileNotFound {
  const _$FileNotFoundImpl({required this.fileName});

  @override
  final String fileName;

  @override
  String toString() {
    return 'AudioFailure.fileNotFound(fileName: $fileName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileNotFoundImpl &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName));
  }

  @override
  int get hashCode => Object.hash(runtimeType, fileName);

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FileNotFoundImplCopyWith<_$FileNotFoundImpl> get copyWith =>
      __$$FileNotFoundImplCopyWithImpl<_$FileNotFoundImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? fileName) loadError,
    required TResult Function(String? message) playbackError,
    required TResult Function(String fileName) fileNotFound,
    required TResult Function(String? format) unsupportedFormat,
    required TResult Function() permissionDenied,
    required TResult Function() deviceUnavailable,
    required TResult Function(String? message) unexpected,
  }) {
    return fileNotFound(fileName);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? fileName)? loadError,
    TResult? Function(String? message)? playbackError,
    TResult? Function(String fileName)? fileNotFound,
    TResult? Function(String? format)? unsupportedFormat,
    TResult? Function()? permissionDenied,
    TResult? Function()? deviceUnavailable,
    TResult? Function(String? message)? unexpected,
  }) {
    return fileNotFound?.call(fileName);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? fileName)? loadError,
    TResult Function(String? message)? playbackError,
    TResult Function(String fileName)? fileNotFound,
    TResult Function(String? format)? unsupportedFormat,
    TResult Function()? permissionDenied,
    TResult Function()? deviceUnavailable,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) {
    if (fileNotFound != null) {
      return fileNotFound(fileName);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadError value) loadError,
    required TResult Function(_PlaybackError value) playbackError,
    required TResult Function(_FileNotFound value) fileNotFound,
    required TResult Function(_UnsupportedFormat value) unsupportedFormat,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_DeviceUnavailable value) deviceUnavailable,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return fileNotFound(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadError value)? loadError,
    TResult? Function(_PlaybackError value)? playbackError,
    TResult? Function(_FileNotFound value)? fileNotFound,
    TResult? Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return fileNotFound?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadError value)? loadError,
    TResult Function(_PlaybackError value)? playbackError,
    TResult Function(_FileNotFound value)? fileNotFound,
    TResult Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (fileNotFound != null) {
      return fileNotFound(this);
    }
    return orElse();
  }
}

abstract class _FileNotFound implements AudioFailure {
  const factory _FileNotFound({required final String fileName}) =
      _$FileNotFoundImpl;

  String get fileName;

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FileNotFoundImplCopyWith<_$FileNotFoundImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UnsupportedFormatImplCopyWith<$Res> {
  factory _$$UnsupportedFormatImplCopyWith(
    _$UnsupportedFormatImpl value,
    $Res Function(_$UnsupportedFormatImpl) then,
  ) = __$$UnsupportedFormatImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? format});
}

/// @nodoc
class __$$UnsupportedFormatImplCopyWithImpl<$Res>
    extends _$AudioFailureCopyWithImpl<$Res, _$UnsupportedFormatImpl>
    implements _$$UnsupportedFormatImplCopyWith<$Res> {
  __$$UnsupportedFormatImplCopyWithImpl(
    _$UnsupportedFormatImpl _value,
    $Res Function(_$UnsupportedFormatImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? format = freezed}) {
    return _then(
      _$UnsupportedFormatImpl(
        format: freezed == format
            ? _value.format
            : format // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$UnsupportedFormatImpl implements _UnsupportedFormat {
  const _$UnsupportedFormatImpl({this.format});

  @override
  final String? format;

  @override
  String toString() {
    return 'AudioFailure.unsupportedFormat(format: $format)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnsupportedFormatImpl &&
            (identical(other.format, format) || other.format == format));
  }

  @override
  int get hashCode => Object.hash(runtimeType, format);

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnsupportedFormatImplCopyWith<_$UnsupportedFormatImpl> get copyWith =>
      __$$UnsupportedFormatImplCopyWithImpl<_$UnsupportedFormatImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? fileName) loadError,
    required TResult Function(String? message) playbackError,
    required TResult Function(String fileName) fileNotFound,
    required TResult Function(String? format) unsupportedFormat,
    required TResult Function() permissionDenied,
    required TResult Function() deviceUnavailable,
    required TResult Function(String? message) unexpected,
  }) {
    return unsupportedFormat(format);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? fileName)? loadError,
    TResult? Function(String? message)? playbackError,
    TResult? Function(String fileName)? fileNotFound,
    TResult? Function(String? format)? unsupportedFormat,
    TResult? Function()? permissionDenied,
    TResult? Function()? deviceUnavailable,
    TResult? Function(String? message)? unexpected,
  }) {
    return unsupportedFormat?.call(format);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? fileName)? loadError,
    TResult Function(String? message)? playbackError,
    TResult Function(String fileName)? fileNotFound,
    TResult Function(String? format)? unsupportedFormat,
    TResult Function()? permissionDenied,
    TResult Function()? deviceUnavailable,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) {
    if (unsupportedFormat != null) {
      return unsupportedFormat(format);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadError value) loadError,
    required TResult Function(_PlaybackError value) playbackError,
    required TResult Function(_FileNotFound value) fileNotFound,
    required TResult Function(_UnsupportedFormat value) unsupportedFormat,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_DeviceUnavailable value) deviceUnavailable,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return unsupportedFormat(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadError value)? loadError,
    TResult? Function(_PlaybackError value)? playbackError,
    TResult? Function(_FileNotFound value)? fileNotFound,
    TResult? Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return unsupportedFormat?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadError value)? loadError,
    TResult Function(_PlaybackError value)? playbackError,
    TResult Function(_FileNotFound value)? fileNotFound,
    TResult Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (unsupportedFormat != null) {
      return unsupportedFormat(this);
    }
    return orElse();
  }
}

abstract class _UnsupportedFormat implements AudioFailure {
  const factory _UnsupportedFormat({final String? format}) =
      _$UnsupportedFormatImpl;

  String? get format;

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnsupportedFormatImplCopyWith<_$UnsupportedFormatImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PermissionDeniedImplCopyWith<$Res> {
  factory _$$PermissionDeniedImplCopyWith(
    _$PermissionDeniedImpl value,
    $Res Function(_$PermissionDeniedImpl) then,
  ) = __$$PermissionDeniedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PermissionDeniedImplCopyWithImpl<$Res>
    extends _$AudioFailureCopyWithImpl<$Res, _$PermissionDeniedImpl>
    implements _$$PermissionDeniedImplCopyWith<$Res> {
  __$$PermissionDeniedImplCopyWithImpl(
    _$PermissionDeniedImpl _value,
    $Res Function(_$PermissionDeniedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PermissionDeniedImpl implements _PermissionDenied {
  const _$PermissionDeniedImpl();

  @override
  String toString() {
    return 'AudioFailure.permissionDenied()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$PermissionDeniedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? fileName) loadError,
    required TResult Function(String? message) playbackError,
    required TResult Function(String fileName) fileNotFound,
    required TResult Function(String? format) unsupportedFormat,
    required TResult Function() permissionDenied,
    required TResult Function() deviceUnavailable,
    required TResult Function(String? message) unexpected,
  }) {
    return permissionDenied();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? fileName)? loadError,
    TResult? Function(String? message)? playbackError,
    TResult? Function(String fileName)? fileNotFound,
    TResult? Function(String? format)? unsupportedFormat,
    TResult? Function()? permissionDenied,
    TResult? Function()? deviceUnavailable,
    TResult? Function(String? message)? unexpected,
  }) {
    return permissionDenied?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? fileName)? loadError,
    TResult Function(String? message)? playbackError,
    TResult Function(String fileName)? fileNotFound,
    TResult Function(String? format)? unsupportedFormat,
    TResult Function()? permissionDenied,
    TResult Function()? deviceUnavailable,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) {
    if (permissionDenied != null) {
      return permissionDenied();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadError value) loadError,
    required TResult Function(_PlaybackError value) playbackError,
    required TResult Function(_FileNotFound value) fileNotFound,
    required TResult Function(_UnsupportedFormat value) unsupportedFormat,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_DeviceUnavailable value) deviceUnavailable,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return permissionDenied(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadError value)? loadError,
    TResult? Function(_PlaybackError value)? playbackError,
    TResult? Function(_FileNotFound value)? fileNotFound,
    TResult? Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return permissionDenied?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadError value)? loadError,
    TResult Function(_PlaybackError value)? playbackError,
    TResult Function(_FileNotFound value)? fileNotFound,
    TResult Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (permissionDenied != null) {
      return permissionDenied(this);
    }
    return orElse();
  }
}

abstract class _PermissionDenied implements AudioFailure {
  const factory _PermissionDenied() = _$PermissionDeniedImpl;
}

/// @nodoc
abstract class _$$DeviceUnavailableImplCopyWith<$Res> {
  factory _$$DeviceUnavailableImplCopyWith(
    _$DeviceUnavailableImpl value,
    $Res Function(_$DeviceUnavailableImpl) then,
  ) = __$$DeviceUnavailableImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$DeviceUnavailableImplCopyWithImpl<$Res>
    extends _$AudioFailureCopyWithImpl<$Res, _$DeviceUnavailableImpl>
    implements _$$DeviceUnavailableImplCopyWith<$Res> {
  __$$DeviceUnavailableImplCopyWithImpl(
    _$DeviceUnavailableImpl _value,
    $Res Function(_$DeviceUnavailableImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$DeviceUnavailableImpl implements _DeviceUnavailable {
  const _$DeviceUnavailableImpl();

  @override
  String toString() {
    return 'AudioFailure.deviceUnavailable()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$DeviceUnavailableImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? fileName) loadError,
    required TResult Function(String? message) playbackError,
    required TResult Function(String fileName) fileNotFound,
    required TResult Function(String? format) unsupportedFormat,
    required TResult Function() permissionDenied,
    required TResult Function() deviceUnavailable,
    required TResult Function(String? message) unexpected,
  }) {
    return deviceUnavailable();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? fileName)? loadError,
    TResult? Function(String? message)? playbackError,
    TResult? Function(String fileName)? fileNotFound,
    TResult? Function(String? format)? unsupportedFormat,
    TResult? Function()? permissionDenied,
    TResult? Function()? deviceUnavailable,
    TResult? Function(String? message)? unexpected,
  }) {
    return deviceUnavailable?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? fileName)? loadError,
    TResult Function(String? message)? playbackError,
    TResult Function(String fileName)? fileNotFound,
    TResult Function(String? format)? unsupportedFormat,
    TResult Function()? permissionDenied,
    TResult Function()? deviceUnavailable,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) {
    if (deviceUnavailable != null) {
      return deviceUnavailable();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadError value) loadError,
    required TResult Function(_PlaybackError value) playbackError,
    required TResult Function(_FileNotFound value) fileNotFound,
    required TResult Function(_UnsupportedFormat value) unsupportedFormat,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_DeviceUnavailable value) deviceUnavailable,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return deviceUnavailable(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadError value)? loadError,
    TResult? Function(_PlaybackError value)? playbackError,
    TResult? Function(_FileNotFound value)? fileNotFound,
    TResult? Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return deviceUnavailable?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadError value)? loadError,
    TResult Function(_PlaybackError value)? playbackError,
    TResult Function(_FileNotFound value)? fileNotFound,
    TResult Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (deviceUnavailable != null) {
      return deviceUnavailable(this);
    }
    return orElse();
  }
}

abstract class _DeviceUnavailable implements AudioFailure {
  const factory _DeviceUnavailable() = _$DeviceUnavailableImpl;
}

/// @nodoc
abstract class _$$UnexpectedImplCopyWith<$Res> {
  factory _$$UnexpectedImplCopyWith(
    _$UnexpectedImpl value,
    $Res Function(_$UnexpectedImpl) then,
  ) = __$$UnexpectedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$UnexpectedImplCopyWithImpl<$Res>
    extends _$AudioFailureCopyWithImpl<$Res, _$UnexpectedImpl>
    implements _$$UnexpectedImplCopyWith<$Res> {
  __$$UnexpectedImplCopyWithImpl(
    _$UnexpectedImpl _value,
    $Res Function(_$UnexpectedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = freezed}) {
    return _then(
      _$UnexpectedImpl(
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$UnexpectedImpl implements _Unexpected {
  const _$UnexpectedImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'AudioFailure.unexpected(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnexpectedImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnexpectedImplCopyWith<_$UnexpectedImpl> get copyWith =>
      __$$UnexpectedImplCopyWithImpl<_$UnexpectedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? fileName) loadError,
    required TResult Function(String? message) playbackError,
    required TResult Function(String fileName) fileNotFound,
    required TResult Function(String? format) unsupportedFormat,
    required TResult Function() permissionDenied,
    required TResult Function() deviceUnavailable,
    required TResult Function(String? message) unexpected,
  }) {
    return unexpected(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? fileName)? loadError,
    TResult? Function(String? message)? playbackError,
    TResult? Function(String fileName)? fileNotFound,
    TResult? Function(String? format)? unsupportedFormat,
    TResult? Function()? permissionDenied,
    TResult? Function()? deviceUnavailable,
    TResult? Function(String? message)? unexpected,
  }) {
    return unexpected?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? fileName)? loadError,
    TResult Function(String? message)? playbackError,
    TResult Function(String fileName)? fileNotFound,
    TResult Function(String? format)? unsupportedFormat,
    TResult Function()? permissionDenied,
    TResult Function()? deviceUnavailable,
    TResult Function(String? message)? unexpected,
    required TResult orElse(),
  }) {
    if (unexpected != null) {
      return unexpected(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadError value) loadError,
    required TResult Function(_PlaybackError value) playbackError,
    required TResult Function(_FileNotFound value) fileNotFound,
    required TResult Function(_UnsupportedFormat value) unsupportedFormat,
    required TResult Function(_PermissionDenied value) permissionDenied,
    required TResult Function(_DeviceUnavailable value) deviceUnavailable,
    required TResult Function(_Unexpected value) unexpected,
  }) {
    return unexpected(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadError value)? loadError,
    TResult? Function(_PlaybackError value)? playbackError,
    TResult? Function(_FileNotFound value)? fileNotFound,
    TResult? Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult? Function(_PermissionDenied value)? permissionDenied,
    TResult? Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult? Function(_Unexpected value)? unexpected,
  }) {
    return unexpected?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadError value)? loadError,
    TResult Function(_PlaybackError value)? playbackError,
    TResult Function(_FileNotFound value)? fileNotFound,
    TResult Function(_UnsupportedFormat value)? unsupportedFormat,
    TResult Function(_PermissionDenied value)? permissionDenied,
    TResult Function(_DeviceUnavailable value)? deviceUnavailable,
    TResult Function(_Unexpected value)? unexpected,
    required TResult orElse(),
  }) {
    if (unexpected != null) {
      return unexpected(this);
    }
    return orElse();
  }
}

abstract class _Unexpected implements AudioFailure {
  const factory _Unexpected({final String? message}) = _$UnexpectedImpl;

  String? get message;

  /// Create a copy of AudioFailure
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnexpectedImplCopyWith<_$UnexpectedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
