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
