// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:wod_timer/core/infrastructure/audio/audio_service.dart'
    as _i1013;
import 'package:wod_timer/core/infrastructure/audio/i_audio_service.dart'
    as _i443;
import 'package:wod_timer/core/infrastructure/haptic/haptic_service.dart'
    as _i96;
import 'package:wod_timer/core/infrastructure/haptic/i_haptic_service.dart'
    as _i871;
import 'package:wod_timer/features/timer/application/usecases/create_workout.dart'
    as _i972;
import 'package:wod_timer/features/timer/application/usecases/pause_timer.dart'
    as _i589;
import 'package:wod_timer/features/timer/application/usecases/resume_timer.dart'
    as _i732;
import 'package:wod_timer/features/timer/application/usecases/start_timer.dart'
    as _i496;
import 'package:wod_timer/features/timer/application/usecases/stop_timer.dart'
    as _i101;
import 'package:wod_timer/features/timer/application/usecases/tick_timer.dart'
    as _i322;
import 'package:wod_timer/features/timer/infrastructure/services/i_timer_engine.dart'
    as _i661;
import 'package:wod_timer/features/timer/infrastructure/services/timer_engine.dart'
    as _i535;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.factory<_i589.PauseTimer>(() => _i589.PauseTimer());
    gh.factory<_i101.StopTimer>(() => _i101.StopTimer());
    gh.factory<_i322.TickTimer>(() => _i322.TickTimer());
    gh.factory<_i732.ResumeTimer>(() => _i732.ResumeTimer());
    gh.factory<_i972.CreateWorkout>(() => _i972.CreateWorkout());
    gh.lazySingleton<_i661.ITimerEngine>(
      () => _i535.TimerEngine(tickInterval: gh<Duration>()),
    );
    gh.lazySingleton<_i871.IHapticService>(() => _i96.HapticService());
    gh.lazySingleton<_i443.IAudioService>(() => _i1013.AudioService());
    gh.factory<_i496.StartTimer>(
      () => _i496.StartTimer(gh<_i443.IAudioService>()),
    );
    return this;
  }
}
