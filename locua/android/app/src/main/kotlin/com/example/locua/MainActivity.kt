package com.example.locua

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterActivity

// CHANGED: added enableEdgeToEdge() — Play Console's pre-launch report
// flagged "Edge-to-edge may not display for all users" because this app
// targets SDK 35 (Android 15), where the system displays edge-to-edge by
// default, but this activity never explicitly opted in for consistent
// behavior on older OS versions too. This is purely an Android-side
// system-bar display setting — it does not change any Flutter/Dart code,
// and main_shell.dart's existing SafeArea wrap around the body already
// handles keeping content clear of the status bar/nav bar/notch, so no
// visual breakage is expected. Still worth a quick look on a real device
// after this build to confirm nothing sits behind the status bar or the
// gesture nav area.
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}