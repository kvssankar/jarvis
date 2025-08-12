# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Keep all MediaPipe classes
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**

# Keep Protocol Buffer classes
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# Keep AutoValue classes
-keep class com.google.auto.value.** { *; }
-dontwarn com.google.auto.value.**

# Keep javax.lang.model classes (annotation processing)
-keep class javax.lang.model.** { *; }
-dontwarn javax.lang.model.**

# Keep annotation processing related classes
-keep class javax.annotation.processing.** { *; }
-dontwarn javax.annotation.processing.**

# Keep Gemma-related classes
-keep class com.google.mediapipe.tasks.genai.** { *; }
-dontwarn com.google.mediapipe.tasks.genai.**

# Keep native method classes
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep classes with @Keep annotation
-keep @androidx.annotation.Keep class * { *; }
-keep @androidx.annotation.Keep interface * { *; }

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Preserve line number information for debugging stack traces
-keepattributes SourceFile,LineNumberTable

# Hide the original source file name
-renamesourcefileattribute SourceFile

# Keep all enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Additional rules for R8 compatibility
-dontwarn java.lang.invoke.StringConcatFactory


# Remove Google Play Core (blocklisted by F-Droid)
-dontwarn com.google.android.play.core.**
-assumenosideeffects class com.google.android.play.core.** { *; }
