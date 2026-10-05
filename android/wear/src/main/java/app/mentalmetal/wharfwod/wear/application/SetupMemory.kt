package app.mentalmetal.wharfwod.wear.application

import app.mentalmetal.wharfwod.wear.domain.RoundCount
import app.mentalmetal.wharfwod.wear.domain.TimelinePart
import app.mentalmetal.wharfwod.wear.domain.TimerDuration
import app.mentalmetal.wharfwod.wear.domain.TimerType
import app.mentalmetal.wharfwod.wear.domain.Workout

/**
 * Remembers the last workout set up in each mode (saved on every change, as
 * the watch does since 1.3.1), so setup opens on it and Home shows it. One
 * additive key per mode; a missing or corrupt value reads as the default.
 */
class SetupMemory(private val store: KeyValueStore) {
    companion object {
        const val MODE_ORDER_FORTIME = "fortime"
        val modeOrder = listOf("fortime", "emom", "amrap", "tabata")
        fun key(code: String) = "wear_setup_$code"

        fun encode(type: TimerType): String = when (type) {
            is TimerType.Amrap -> "amrap:${type.duration.seconds}"
            is TimerType.ForTime -> "fortime:${type.timeCap.seconds}:${if (type.countUp) 1 else 0}"
            is TimerType.Emom -> "emom:${type.intervalDuration.seconds}:${type.rounds.value}"
            is TimerType.Tabata -> "tabata:${type.workDuration.seconds}:${type.restDuration.seconds}:${type.rounds.value}"
        }

        fun decode(raw: String?): TimerType? {
            val parts = raw?.split(":") ?: return null
            return try {
                when (parts[0]) {
                    "amrap" -> TimerType.Amrap(TimerDuration.of(parts[1].toInt()))
                    "fortime" -> TimerType.ForTime(TimerDuration.of(parts[1].toInt()), parts.getOrNull(2) != "0")
                    "emom" -> TimerType.Emom(TimerDuration.of(parts[1].toInt()), RoundCount.of(parts[2].toInt()))
                    "tabata" -> TimerType.Tabata(
                        TimerDuration.of(parts[1].toInt()), TimerDuration.of(parts[2].toInt()), RoundCount.of(parts[3].toInt()),
                    )
                    else -> null
                }
            } catch (e: Exception) {
                null
            }
        }

        fun defaultType(code: String): TimerType = when (code) {
            "amrap" -> Workout.defaultAmrap().timerType
            "fortime" -> Workout.defaultForTime().timerType
            "emom" -> Workout.defaultEmom().timerType
            else -> Workout.defaultTabata().timerType
        }

        /** "10:00", "CAP 20:00 · UP", "10 × 1:00", "8 × 20s / 10s", as the watch's Home shows them. */
        fun summary(type: TimerType): String = when (type) {
            is TimerType.Amrap -> type.duration.clock
            is TimerType.ForTime -> "CAP ${type.timeCap.clock} · ${if (type.countUp) "UP" else "DOWN"}"
            is TimerType.Emom -> "${type.rounds.value} × ${type.intervalDuration.clock}"
            is TimerType.Tabata -> "${type.rounds.value} × ${type.workDuration.phase} / ${type.restDuration.phase}"
        }
    }

    fun last(code: String): TimerType {
        val saved = decode(store.getString(key(code)))
        return if (saved != null && saved.typeCode == code) saved else defaultType(code)
    }

    fun save(type: TimerType) = store.putString(key(type.typeCode), encode(type))

    fun summary(code: String): String = summary(last(code))

    fun shape(code: String): List<TimelinePart> = last(code).timelineParts
}
