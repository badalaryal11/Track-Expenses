# Keep runtime annotations/signatures used by Flutter plugins and AndroidX.
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*

# Keep Flutter engine/plugin glue classes.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Keep plugin implementations registered through Flutter registrant.
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }

# Keep app Android entry points.
-keep class com.badalaryal.myexpense.MainActivity { *; }
-keep class * extends io.flutter.embedding.android.FlutterActivity
-keep class * extends io.flutter.embedding.android.FlutterFragmentActivity

# Keep Android components declared in AndroidManifest (defensive).
-keep public class * extends android.app.Application
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

# Flutter engine references Play Core deferred-component classes that this app
# does not use. Suppress R8 missing-class errors for those optional APIs.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# ── Google Sign-In & Google API Client (needed for Google Drive backup) ──
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.api.client.** { *; }
-keep class com.google.api.services.drive.** { *; }
-keep class com.google.http.client.** { *; }
-dontwarn com.google.api.client.**
-dontwarn com.google.common.**
-dontwarn javax.annotation.**
-dontwarn sun.misc.Unsafe
