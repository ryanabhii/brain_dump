# Keep Flutter / plugin entry points used through reflection.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# flutter_local_notifications: receivers and serialized notification model are
# resolved by name from AndroidManifest.xml.
-keep class com.dexterous.** { *; }

# Google Play Core split-install stubs (referenced by Flutter's deferred
# components support even when the app does not use split install).
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-dontwarn com.google.android.play.core.**

# GoogleSignIn / googleapis use Gson-style reflection on response models.
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.api.client.** { *; }
-keep class com.google.api.services.** { *; }

# shared_preferences: the Android implementation is resolved via reflection
# from the Flutter plugin registry. Without this, R8 strips the class and
# SharedPreferences.getInstance() silently hangs/fails in release builds.
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# path_provider: same reflection-based loading.
-keep class io.flutter.plugins.pathprovider.** { *; }

# flutter_timezone: loaded by name from the plugin registry.
-keep class dev.fluttercommunity.plus.timezone.** { *; }
-keep class fr.florent.fluttertimezone.** { *; }

# record (audio recording): native bridge loaded via reflection.
-keep class com.llfbandit.record.** { *; }

# jni / jni_flutter (dart:ffi helper used by whisper_ggml and record).
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }
-dontwarn com.github.dart_lang.**

# whisper_ggml: native .so loaded at runtime.
-keep class com.whisper.** { *; }
-dontwarn com.whisper.**

# audioplayers: native bridge.
-keep class xyz.luan.audioplayers.** { *; }

# ffmpeg_kit (used by whisper/record for audio conversion).
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-dontwarn com.antonkarpenko.**

