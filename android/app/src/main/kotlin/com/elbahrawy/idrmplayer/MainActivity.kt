package com.elbahrawy.idrmplayer

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // منع تسجيل صوت التطبيق في Screen Recording (Android 10+ فقط)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.setAllowedCapturePolicy(AudioAttributes.ALLOW_CAPTURE_BY_NONE)
        }
    }

    override fun onDestroy() {
        // رجّع الوضع الطبيعي (اختياري)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.setAllowedCapturePolicy(AudioAttributes.ALLOW_CAPTURE_BY_ALL)
        }
        super.onDestroy()
    }
}
