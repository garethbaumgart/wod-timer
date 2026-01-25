import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';

part 'recent_workouts_provider.g.dart';

/// Stores the last used timer configuration for quick restart.
class RecentWorkout {
  const RecentWorkout({
    required this.timerType,
    required this.name,
    required this.description,
    required this.lastUsed,
  });

  final String timerType;
  final String name;
  final String description;
  final DateTime lastUsed;

  /// Get the icon for this timer type.
  IconData get icon {
    switch (timerType) {
      case TimerTypes.amrap:
        return Icons.loop;
      case TimerTypes.forTime:
        return Icons.timer;
      case TimerTypes.emom:
        return Icons.av_timer;
      case TimerTypes.tabata:
        return Icons.fitness_center;
      default:
        return Icons.timer;
    }
  }
}

/// Provider for managing recent workouts.
@Riverpod(keepAlive: true)
class RecentWorkouts extends _$RecentWorkouts {
  static const _maxRecent = 3;
  static const _keyPrefix = 'recent_workout_';

  @override
  List<RecentWorkout> build() {
    _loadRecents();
    return [];
  }

  Future<void> _loadRecents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<RecentWorkout> recents = [];

      for (int i = 0; i < _maxRecent; i++) {
        final timerType = prefs.getString('${_keyPrefix}${i}_type');
        final name = prefs.getString('${_keyPrefix}${i}_name');
        final description = prefs.getString('${_keyPrefix}${i}_desc');
        final lastUsedMs = prefs.getInt('${_keyPrefix}${i}_lastUsed');

        if (timerType != null && name != null) {
          recents.add(RecentWorkout(
            timerType: timerType,
            name: name,
            description: description ?? '',
            lastUsed: lastUsedMs != null
                ? DateTime.fromMillisecondsSinceEpoch(lastUsedMs)
                : DateTime.now(),
          ));
        }
      }

      state = recents;
    } catch (e) {
      // Ignore errors loading preferences
    }
  }

  Future<void> addRecent({
    required String timerType,
    required String name,
    required String description,
  }) async {
    final newRecent = RecentWorkout(
      timerType: timerType,
      name: name,
      description: description,
      lastUsed: DateTime.now(),
    );

    // Remove existing entry with same configuration (type + name + description)
    final updated = state
        .where((r) =>
            !(r.timerType == timerType &&
                r.name == name &&
                r.description == description))
        .toList();

    // Add new entry at the front
    updated.insert(0, newRecent);

    // Keep only the most recent ones
    state = updated.take(_maxRecent).toList();

    // Save to preferences
    await _saveRecents();
  }

  Future<void> _saveRecents() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear old entries
      for (int i = 0; i < _maxRecent; i++) {
        await prefs.remove('${_keyPrefix}${i}_type');
        await prefs.remove('${_keyPrefix}${i}_name');
        await prefs.remove('${_keyPrefix}${i}_desc');
        await prefs.remove('${_keyPrefix}${i}_lastUsed');
      }

      // Save current entries
      for (int i = 0; i < state.length; i++) {
        final recent = state[i];
        await prefs.setString('${_keyPrefix}${i}_type', recent.timerType);
        await prefs.setString('${_keyPrefix}${i}_name', recent.name);
        await prefs.setString('${_keyPrefix}${i}_desc', recent.description);
        await prefs.setInt(
            '${_keyPrefix}${i}_lastUsed', recent.lastUsed.millisecondsSinceEpoch);
      }
    } catch (e) {
      // Ignore errors saving preferences
    }
  }
}
