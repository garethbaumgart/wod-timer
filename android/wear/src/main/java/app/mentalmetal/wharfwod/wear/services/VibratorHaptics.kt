package app.mentalmetal.wharfwod.wear.services

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/** The watch's vibrator playing [HapticPatterns]; the one wrist channel the athlete feels. */
class VibratorHaptics(context: Context) : WristHaptics {
    private val vibrator: Vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    }

    override fun play(cue: HapticCue) {
        val wave = HapticPatterns.waveform(cue)
        val effect = if (vibrator.hasAmplitudeControl()) {
            VibrationEffect.createWaveform(wave.timings, wave.amplitudes, -1)
        } else {
            VibrationEffect.createWaveform(wave.timings, -1)
        }
        vibrator.vibrate(effect)
    }

    override fun cancelPending() = vibrator.cancel()
}
