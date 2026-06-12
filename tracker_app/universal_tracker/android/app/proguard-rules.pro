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
