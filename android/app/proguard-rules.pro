# Flutter specific rules.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Default ProGuard rules for classes that are used from native code.
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Add any other specific rules for your plugins or libraries here.
# For example, if you use Firebase:
# -keepattributes Signature
# -keepattributes *Annotation*
# -keepnames class com.google.android.gms.** {*;}
# -keepnames class com.google.firebase.** {*;}

# For http/dio or other networking libraries, sometimes specific rules are needed
# if they use reflection. Usually, their documentation specifies this.

# For onesignal
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.NotificationExtenderService

# For geolocator (just in case, usually not needed for modern versions)
# -keep class com.baseflow.geolocator.** { *; }

# For file_picker, image_picker, etc., usually don't need specific rules unless
# they use reflection in a way that ProGuard interferes with.

# If you use @Keep annotation from androidx.annotation:
-keep class androidx.annotation.Keep
-keep @androidx.annotation.Keep class * {*;}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <fields>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <methods>;
}
