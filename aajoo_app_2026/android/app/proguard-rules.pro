# Keep Razorpay classes
-keep class com.razorpay.** { *; }

# Keep Google Pay related classes if used
-keep class com.google.android.apps.nbu.paisa.** { *; }

# Keep all annotations
-keepattributes *Annotation*

# Keep classes and members annotated with @Keep
-keep @proguard.annotation.Keep class * { *; }
-keepclassmembers @proguard.annotation.Keep class * { *; }
