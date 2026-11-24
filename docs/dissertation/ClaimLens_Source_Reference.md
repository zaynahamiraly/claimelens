# ClaimLens — Numbered Source Reference

Generated from the local working tree. This is an implementation reference, not evidence of production deployment.

Parent Git revision: `40dde30776b365fde028e887de7c06656606d915`. Working-tree changes may be newer; SHA-256 hashes below identify the exact files.

Read ClaimLens_Project_Portfolio.md first. Source lines are exact UTF-8 text, prefixed with line numbers. Private environment files, service-account keys, SDK client configuration, runtime data, uploads and test credentials are excluded. Use this reference to explain code; never infer unimplemented features from function names.

## firebase/firestore.rules

10 lines. SHA-256: `a69a1d7bfa483d2e34371696e4b335491957f7eb304d005dddf74f578f3ea097`.

Symbols: Configuration/resource file.

```text
0001 | rules_version = '2';
0002 | service cloud.firestore {
0003 |   match /databases/{database}/documents {
0004 |     // During migration all access goes through the authenticated Python API.
0005 |     // Admin SDK operations bypass these rules; the API must enforce ownership.
0006 |     match /{document=**} {
0007 |       allow read, write: if false;
0008 |     }
0009 |   }
0010 | }
```

## mobile/claimlens_mobile/android/app/build.gradle.kts

61 lines. SHA-256: `494fc8fb13c1c97ba7ce8cb21aea73631e31ac9b479bac1571babe5769fedbd1`.

Symbols: Configuration/resource file.

```kotlin
0001 | import java.util.Properties
0002 |
0003 | plugins {
0004 |     id("com.android.application")
0005 |     id("com.google.gms.google-services")
0006 |     // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
0007 |     id("dev.flutter.flutter-gradle-plugin")
0008 | }
0009 |
0010 | val releaseKeys = Properties()
0011 | val releaseKeysFile = rootProject.file("key.properties")
0012 | if (releaseKeysFile.exists()) releaseKeysFile.inputStream().use { releaseKeys.load(it) }
0013 | if (gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) } && !releaseKeysFile.exists()) {
0014 |     throw GradleException("Configure private android/key.properties before creating a signed ClaimLens release. Debug signing is never used for release builds.")
0015 | }
0016 |
0017 | android {
0018 |     namespace = "ai.claimlens.claimlens_mobile"
0019 |     compileSdk = flutter.compileSdkVersion
0020 |     ndkVersion = flutter.ndkVersion
0021 |
0022 |     compileOptions {
0023 |         sourceCompatibility = JavaVersion.VERSION_17
0024 |         targetCompatibility = JavaVersion.VERSION_17
0025 |     }
0026 |
0027 |     defaultConfig {
0028 |         // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
0029 |         applicationId = "ai.claimlens.claimlens_mobile"
0030 |         // You can update the following values to match your application needs.
0031 |         // For more information, see: https://flutter.dev/to/review-gradle-config.
0032 |         minSdk = flutter.minSdkVersion
0033 |         targetSdk = flutter.targetSdkVersion
0034 |         versionCode = flutter.versionCode
0035 |         versionName = flutter.versionName
0036 |     }
0037 |
0038 |     signingConfigs {
0039 |         if (releaseKeysFile.exists()) create("production") {
0040 |             keyAlias = releaseKeys.getProperty("keyAlias")
0041 |             keyPassword = releaseKeys.getProperty("keyPassword")
0042 |             storeFile = file(releaseKeys.getProperty("storeFile"))
0043 |             storePassword = releaseKeys.getProperty("storePassword")
0044 |         }
0045 |     }
0046 |     buildTypes {
0047 |         release {
0048 |             signingConfig = if (releaseKeysFile.exists()) signingConfigs.getByName("production") else null
0049 |         }
0050 |     }
0051 | }
0052 |
0053 | kotlin {
0054 |     compilerOptions {
0055 |         jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
0056 |     }
0057 | }
0058 |
0059 | flutter {
0060 |     source = "../.."
0061 | }
```

## mobile/claimlens_mobile/android/app/src/main/AndroidManifest.xml

50 lines. SHA-256: `3692557b6fbc1413ea07f365dfe9b23f7084c197a734b5b17bfc7353b974d20d`.

Symbols: Configuration/resource file.

```xml
0001 | <manifest xmlns:android="http://schemas.android.com/apk/res/android">
0002 |     <uses-permission android:name="android.permission.INTERNET" />
0003 |     <uses-permission android:name="android.permission.USE_BIOMETRIC" />
0004 |     <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
0005 |     <application
0006 |         android:label="ClaimLens"
0007 |         android:name="${applicationName}"
0008 |         android:icon="@drawable/ic_claimlens">
0009 |         <meta-data android:name="com.google.firebase.messaging.default_notification_icon" android:resource="@drawable/ic_stat_claimlens" />
0010 |         <meta-data android:name="firebase_messaging_installation_id_enabled" android:value="true" />
0011 |         <activity
0012 |             android:name=".MainActivity"
0013 |             android:exported="true"
0014 |             android:launchMode="singleTop"
0015 |             android:taskAffinity=""
0016 |             android:theme="@style/LaunchTheme"
0017 |             android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
0018 |             android:hardwareAccelerated="true"
0019 |             android:windowSoftInputMode="adjustResize">
0020 |             <!-- Specifies an Android theme to apply to this Activity as soon as
0021 |                  the Android process has started. This theme is visible to the user
0022 |                  while the Flutter UI initializes. After that, this theme continues
0023 |                  to determine the Window background behind the Flutter UI. -->
0024 |             <meta-data
0025 |               android:name="io.flutter.embedding.android.NormalTheme"
0026 |               android:resource="@style/NormalTheme"
0027 |               />
0028 |             <intent-filter>
0029 |                 <action android:name="android.intent.action.MAIN"/>
0030 |                 <category android:name="android.intent.category.LAUNCHER"/>
0031 |             </intent-filter>
0032 |         </activity>
0033 |         <!-- Don't delete the meta-data below.
0034 |              This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
0035 |         <meta-data
0036 |             android:name="flutterEmbedding"
0037 |             android:value="2" />
0038 |     </application>
0039 |     <!-- Required to query activities that can process text, see:
0040 |          https://developer.android.com/training/package-visibility and
0041 |          https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.
0042 |
0043 |          In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
0044 |     <queries>
0045 |         <intent>
0046 |             <action android:name="android.intent.action.PROCESS_TEXT"/>
0047 |             <data android:mimeType="text/plain"/>
0048 |         </intent>
0049 |     </queries>
0050 | </manifest>
```

## mobile/claimlens_mobile/android/app/src/main/kotlin/ai/claimlens/claimlens_mobile/MainActivity.kt

5 lines. SHA-256: `1fef5c2dfb4caaaf74a28f171620415aaa5efcfb390e23406d1ba28de6558bb0`.

Symbols: Configuration/resource file.

```kotlin
0001 | package ai.claimlens.claimlens_mobile
0002 |
0003 | import io.flutter.embedding.android.FlutterFragmentActivity
0004 |
0005 | class MainActivity : FlutterFragmentActivity()
```

## mobile/claimlens_mobile/android/app/src/main/res/drawable-v21/launch_background.xml

12 lines. SHA-256: `dca312ec77de83e43ef70a825c299b51451247286c29167d62f19165750b8793`.

Symbols: Configuration/resource file.

```xml
0001 | <?xml version="1.0" encoding="utf-8"?>
0002 | <!-- Modify this file to customize your launch splash screen -->
0003 | <layer-list xmlns:android="http://schemas.android.com/apk/res/android">
0004 |     <item android:drawable="?android:colorBackground" />
0005 |
0006 |     <!-- You can insert your own image assets here -->
0007 |     <!-- <item>
0008 |         <bitmap
0009 |             android:gravity="center"
0010 |             android:src="@mipmap/launch_image" />
0011 |     </item> -->
0012 | </layer-list>
```

## mobile/claimlens_mobile/android/app/src/main/res/drawable/ic_claimlens.xml

6 lines. SHA-256: `587b9c6154d1c8b5c9b539b23578b3aa2bc0d77d567daa170cdb5b407e9d1a78`.

Symbols: Configuration/resource file.

```xml
0001 | <vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="96dp" android:height="96dp" android:viewportWidth="96" android:viewportHeight="96">
0002 |     <path android:fillColor="#006D77" android:pathData="M24,0H72Q96,0 96,24V72Q96,96 72,96H24Q0,96 0,72V24Q0,0 24,0Z" />
0003 |     <path android:fillColor="#FFFFFF" android:fillType="evenOdd" android:pathData="M42,18A24,24 0,1 1,42,66A24,24 0,1 1,42,18ZM42,25A17,17 0,1 0,42,59A17,17 0,1 0,42,25Z" />
0004 |     <path android:strokeColor="#FFFFFF" android:strokeWidth="8" android:strokeLineCap="round" android:pathData="M60,60L77,77" />
0005 |     <path android:fillColor="#8DE2D7" android:pathData="M38,31H46V38H53V46H46V53H38V46H31V38H38Z" />
0006 | </vector>
```

## mobile/claimlens_mobile/android/app/src/main/res/drawable/ic_stat_claimlens.xml

4 lines. SHA-256: `f44b40f97ad5d57f18dacf45a3b2e32b749f09d6aa2b3d9fc7c81cd61f7245da`.

Symbols: Configuration/resource file.

```xml
0001 | <vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24">
0002 |     <path android:fillColor="#FFFFFF" android:fillType="evenOdd" android:pathData="M10,2A8,8 0,1 1,10,18A8,8 0,1 1,10,2ZM10,5A5,5 0,1 0,10,15A5,5 0,1 0,10,5Z" />
0003 |     <path android:strokeColor="#FFFFFF" android:strokeWidth="3" android:strokeLineCap="round" android:pathData="M16,16L22,22" />
0004 | </vector>
```

## mobile/claimlens_mobile/android/app/src/main/res/drawable/launch_background.xml

12 lines. SHA-256: `2df60e2cfbee873ce2858088cf003e6b93498f2f568476da437610467ea1a9d7`.

Symbols: Configuration/resource file.

```xml
0001 | <?xml version="1.0" encoding="utf-8"?>
0002 | <!-- Modify this file to customize your launch splash screen -->
0003 | <layer-list xmlns:android="http://schemas.android.com/apk/res/android">
0004 |     <item android:drawable="@android:color/white" />
0005 |
0006 |     <!-- You can insert your own image assets here -->
0007 |     <!-- <item>
0008 |         <bitmap
0009 |             android:gravity="center"
0010 |             android:src="@mipmap/launch_image" />
0011 |     </item> -->
0012 | </layer-list>
```

## mobile/claimlens_mobile/android/app/src/main/res/values-night/styles.xml

18 lines. SHA-256: `2a6cc941d93cb969508ef1991c7c801ad38fd5b8149def96ec75ae07aafe244b`.

Symbols: Configuration/resource file.

```xml
0001 | <?xml version="1.0" encoding="utf-8"?>
0002 | <resources>
0003 |     <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is on -->
0004 |     <style name="LaunchTheme" parent="Theme.AppCompat.DayNight.NoActionBar">
0005 |         <!-- Show a splash screen on the activity. Automatically removed when
0006 |              the Flutter engine draws its first frame -->
0007 |         <item name="android:windowBackground">@drawable/launch_background</item>
0008 |     </style>
0009 |     <!-- Theme applied to the Android Window as soon as the process has started.
0010 |          This theme determines the color of the Android Window while your
0011 |          Flutter UI initializes, as well as behind your Flutter UI while its
0012 |          running.
0013 |
0014 |          This Theme is only used starting with V2 of Flutter's Android embedding. -->
0015 |     <style name="NormalTheme" parent="Theme.AppCompat.DayNight.NoActionBar">
0016 |         <item name="android:windowBackground">?android:colorBackground</item>
0017 |     </style>
0018 | </resources>
```

## mobile/claimlens_mobile/android/app/src/main/res/values/styles.xml

18 lines. SHA-256: `4789a1530af879f0d83495bde5b3e012bb05f597d86b509555126e623d0688e6`.

Symbols: Configuration/resource file.

```xml
0001 | <?xml version="1.0" encoding="utf-8"?>
0002 | <resources>
0003 |     <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is off -->
0004 |     <style name="LaunchTheme" parent="Theme.AppCompat.DayNight.NoActionBar">
0005 |         <!-- Show a splash screen on the activity. Automatically removed when
0006 |              the Flutter engine draws its first frame -->
0007 |         <item name="android:windowBackground">@drawable/launch_background</item>
0008 |     </style>
0009 |     <!-- Theme applied to the Android Window as soon as the process has started.
0010 |          This theme determines the color of the Android Window while your
0011 |          Flutter UI initializes, as well as behind your Flutter UI while its
0012 |          running.
0013 |
0014 |          This Theme is only used starting with V2 of Flutter's Android embedding. -->
0015 |     <style name="NormalTheme" parent="Theme.AppCompat.DayNight.NoActionBar">
0016 |         <item name="android:windowBackground">?android:colorBackground</item>
0017 |     </style>
0018 | </resources>
```

## mobile/claimlens_mobile/android/settings.gradle.kts

27 lines. SHA-256: `0d188ac3cb95977eef65bb3a3a9d248e05c03b4f6750028e318c446324001043`.

Symbols: Configuration/resource file.

```kotlin
0001 | pluginManagement {
0002 |     val flutterSdkPath =
0003 |         run {
0004 |             val properties = java.util.Properties()
0005 |             file("local.properties").inputStream().use { properties.load(it) }
0006 |             val flutterSdkPath = properties.getProperty("flutter.sdk")
0007 |             require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
0008 |             flutterSdkPath
0009 |         }
0010 |
0011 |     includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
0012 |
0013 |     repositories {
0014 |         google()
0015 |         mavenCentral()
0016 |         gradlePluginPortal()
0017 |     }
0018 | }
0019 |
0020 | plugins {
0021 |     id("dev.flutter.flutter-plugin-loader") version "1.0.0"
0022 |     id("com.android.application") version "9.0.1" apply false
0023 |     id("org.jetbrains.kotlin.android") version "2.3.20" apply false
0024 |     id("com.google.gms.google-services") version "4.4.4" apply false
0025 | }
0026 |
0027 | include(":app")
```

## mobile/claimlens_mobile/lib/app_theme.dart

43 lines. SHA-256: `fff1aed858ee9509742e6fefd29f84f31a458c73db4f62420b9ec368319bf9b6`.

Symbols: Configuration/resource file.

```dart
0001 | import 'package:flutter/material.dart';
0002 |
0003 | ThemeData claimLensTheme(Brightness brightness) {
0004 |   final dark = brightness == Brightness.dark;
0005 |   final scheme = ColorScheme.fromSeed(
0006 |       seedColor: const Color(0xff087f8c), brightness: brightness);
0007 |   return ThemeData(
0008 |     useMaterial3: true,
0009 |     colorScheme: scheme,
0010 |     scaffoldBackgroundColor:
0011 |         dark ? const Color(0xff101d25) : const Color(0xfff3f7f9),
0012 |     appBarTheme: AppBarTheme(
0013 |         centerTitle: false,
0014 |         backgroundColor:
0015 |             dark ? const Color(0xff101d25) : const Color(0xfff3f7f9),
0016 |         surfaceTintColor: Colors.transparent),
0017 |     cardTheme: CardThemeData(
0018 |         elevation: 0,
0019 |         margin: EdgeInsets.zero,
0020 |         color: dark ? const Color(0xff192c35) : Colors.white,
0021 |         shape: RoundedRectangleBorder(
0022 |             borderRadius: BorderRadius.circular(20),
0023 |             side: BorderSide(
0024 |                 color: scheme.outlineVariant.withValues(alpha: .45)))),
0025 |     inputDecorationTheme: InputDecorationTheme(
0026 |         filled: true,
0027 |         fillColor: dark ? const Color(0xff192c35) : Colors.white,
0028 |         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
0029 |         contentPadding:
0030 |             const EdgeInsets.symmetric(horizontal: 16, vertical: 18)),
0031 |     filledButtonTheme: FilledButtonThemeData(
0032 |         style: FilledButton.styleFrom(
0033 |             minimumSize: const Size(0, 52),
0034 |             shape: RoundedRectangleBorder(
0035 |                 borderRadius: BorderRadius.circular(14)))),
0036 |     outlinedButtonTheme: OutlinedButtonThemeData(
0037 |         style: OutlinedButton.styleFrom(
0038 |             minimumSize: const Size(0, 50),
0039 |             shape: RoundedRectangleBorder(
0040 |                 borderRadius: BorderRadius.circular(14)))),
0041 |     navigationBarTheme: const NavigationBarThemeData(height: 76),
0042 |   );
0043 | }
```

## mobile/claimlens_mobile/lib/config/api_config.dart

8 lines. SHA-256: `608107b4f6c81f85f720fa879f29192cb99f174302fb98d5df3a31d86d6408f5`.

Symbols: `ApiConfig`: L1

```dart
0001 | class ApiConfig {
0002 |   const ApiConfig._();
0003 |
0004 |   static const baseUrl = String.fromEnvironment(
0005 |     'API_BASE_URL',
0006 |     defaultValue: 'http://10.0.2.2:8000/api/v1',
0007 |   );
0008 | }
```

## mobile/claimlens_mobile/lib/main.dart

70 lines. SHA-256: `1247186ecb4cabe5ee8e708c59379b3e2375f98b62e4e2029ed9184eac1eb37a`.

Symbols: `ClaimLensApp`: L27; `AuthGate`: L56

```dart
0001 | import 'package:flutter/material.dart';
0002 | import 'package:firebase_core/firebase_core.dart';
0003 | import 'package:firebase_messaging/firebase_messaging.dart';
0004 | import 'package:provider/provider.dart';
0005 |
0006 | import 'providers/auth_provider.dart';
0007 | import 'providers/claims_provider.dart';
0008 | import 'screens/app_shell.dart';
0009 | import 'screens/login_screen.dart';
0010 | import 'screens/splash_screen.dart';
0011 | import 'services/api_client.dart';
0012 | import 'app_theme.dart';
0013 | import 'screens/required_password_screen.dart';
0014 | import 'widgets/session_guard.dart';
0015 | import 'services/push_service.dart';
0016 |
0017 | Future<void> main() async {
0018 |   WidgetsFlutterBinding.ensureInitialized();
0019 |   try {
0020 |     await Firebase.initializeApp();
0021 |     FirebaseMessaging.onBackgroundMessage(claimLensBackgroundMessage);
0022 |   } catch (_) {/* Sign-in and in-app updates remain available. */}
0023 |   final client = ApiClient();
0024 |   runApp(ClaimLensApp(client: client));
0025 | }
0026 |
0027 | class ClaimLensApp extends StatelessWidget {
0028 |   const ClaimLensApp({super.key, required this.client});
0029 |   final ApiClient client;
0030 |
0031 |   @override
0032 |   Widget build(BuildContext context) => MultiProvider(
0033 |         providers: [
0034 |           ChangeNotifierProvider(
0035 |               create: (_) => AuthProvider(client)..initialise()),
0036 |           ChangeNotifierProvider(create: (_) => ClaimsProvider(client)),
0037 |         ],
0038 |         child: Consumer<AuthProvider>(
0039 |             builder: (context, auth, _) => MaterialApp(
0040 |                   key: ValueKey(auth.user?.id ?? 'guest'),
0041 |                   builder: (context, child) => SessionGuard(child: child!),
0042 |                   title: 'ClaimLens',
0043 |                   debugShowCheckedModeBanner: false,
0044 |                   theme: claimLensTheme(Brightness.light),
0045 |                   darkTheme: claimLensTheme(Brightness.dark),
0046 |                   themeMode: switch (auth.user?.theme) {
0047 |                     'light' => ThemeMode.light,
0048 |                     'dark' => ThemeMode.dark,
0049 |                     _ => ThemeMode.system
0050 |                   },
0051 |                   home: const AuthGate(),
0052 |                 )),
0053 |       );
0054 | }
0055 |
0056 | class AuthGate extends StatelessWidget {
0057 |   const AuthGate({super.key});
0058 |
0059 |   @override
0060 |   Widget build(BuildContext context) {
0061 |     final auth = context.watch<AuthProvider>();
0062 |     if (auth.initialising) {
0063 |       return const SplashScreen();
0064 |     }
0065 |     if (auth.user?.mustChangePassword == true) {
0066 |       return const RequiredPasswordScreen();
0067 |     }
0068 |     return auth.authenticated ? const AppShell() : const LoginScreen();
0069 |   }
0070 | }
```

## mobile/claimlens_mobile/lib/models/claim.dart

264 lines. SHA-256: `b9f82e251f300acb7f80063bc80a46865296cc40c931fe0a1fe408ede3741e21`.

Symbols: `ClaimSummary`: L4; `ExtractedField`: L43; `ClaimDocument`: L70; `ClaimDetails`: L137; `DashboardData`: L193; `DocumentConfirmation`: L233; `FieldCorrection`: L254

```dart
0001 | double? _number(dynamic value) =>
0002 |     value == null ? null : double.tryParse(value.toString());
0003 |
0004 | class ClaimSummary {
0005 |   const ClaimSummary({
0006 |     required this.id,
0007 |     required this.reference,
0008 |     required this.patientName,
0009 |     required this.providerName,
0010 |     required this.currency,
0011 |     required this.status,
0012 |     required this.warningCount,
0013 |     required this.createdAt,
0014 |     this.claimedAmount,
0015 |     this.assignedTo,
0016 |   });
0017 |
0018 |   final String id;
0019 |   final String reference;
0020 |   final String patientName;
0021 |   final String providerName;
0022 |   final double? claimedAmount;
0023 |   final String currency;
0024 |   final String status;
0025 |   final int warningCount;
0026 |   final DateTime createdAt;
0027 |   final String? assignedTo;
0028 |
0029 |   factory ClaimSummary.fromJson(Map<String, dynamic> json) => ClaimSummary(
0030 |         id: json['id'] as String,
0031 |         reference: json['reference'] as String,
0032 |         patientName: json['patient_name'] as String? ?? '',
0033 |         providerName: json['provider_name'] as String? ?? '',
0034 |         claimedAmount: _number(json['claimed_amount']),
0035 |         currency: json['currency'] as String? ?? 'MUR',
0036 |         status: json['status'] as String,
0037 |         warningCount: json['warning_count'] as int? ?? 0,
0038 |         createdAt: DateTime.parse(json['created_at'] as String),
0039 |         assignedTo: json['assigned_to'] as String?,
0040 |       );
0041 | }
0042 |
0043 | class ExtractedField {
0044 |   const ExtractedField({
0045 |     required this.id,
0046 |     required this.fieldName,
0047 |     required this.normalizedValue,
0048 |     required this.confidence,
0049 |     required this.extractionMethod,
0050 |     this.documentId,
0051 |   });
0052 |
0053 |   final String id;
0054 |   final String fieldName;
0055 |   final String normalizedValue;
0056 |   final double confidence;
0057 |   final String extractionMethod;
0058 |   final String? documentId;
0059 |
0060 |   factory ExtractedField.fromJson(Map<String, dynamic> json) => ExtractedField(
0061 |         id: json['id'] as String,
0062 |         fieldName: json['field_name'] as String,
0063 |         normalizedValue: json['normalized_value'] as String,
0064 |         confidence: _number(json['confidence']) ?? 0,
0065 |         extractionMethod: json['extraction_method'] as String,
0066 |         documentId: json['document_id'] as String?,
0067 |       );
0068 | }
0069 |
0070 | class ClaimDocument {
0071 |   const ClaimDocument({
0072 |     required this.id,
0073 |     required this.originalName,
0074 |     required this.documentType,
0075 |     required this.mimeType,
0076 |     required this.extractionStatus,
0077 |     required this.includeInTotal,
0078 |     required this.fields,
0079 |     this.extractedAmount,
0080 |     this.extractedCurrency,
0081 |     this.confirmedAmount,
0082 |     this.confirmedCurrency,
0083 |     this.clientProposedAmount,
0084 |     this.clientProposedCurrency,
0085 |     this.clientReportedIncorrectAmount = false,
0086 |     this.amountConfidence,
0087 |     this.duplicateOf,
0088 |     this.extractionNotes,
0089 |     this.signedUrl,
0090 |   });
0091 |
0092 |   final String id;
0093 |   final String originalName;
0094 |   final String documentType;
0095 |   final String mimeType;
0096 |   final String extractionStatus;
0097 |   final double? extractedAmount;
0098 |   final String? extractedCurrency;
0099 |   final double? confirmedAmount;
0100 |   final String? confirmedCurrency;
0101 |   final double? clientProposedAmount;
0102 |   final String? clientProposedCurrency;
0103 |   final bool clientReportedIncorrectAmount;
0104 |   final double? amountConfidence;
0105 |   final bool includeInTotal;
0106 |   final String? duplicateOf;
0107 |   final String? extractionNotes;
0108 |   final String? signedUrl;
0109 |   final List<ExtractedField> fields;
0110 |
0111 |   factory ClaimDocument.fromJson(Map<String, dynamic> json) => ClaimDocument(
0112 |         id: json['id'] as String,
0113 |         originalName: json['original_name'] as String,
0114 |         documentType: json['document_type'] as String,
0115 |         mimeType: json['mime_type'] as String,
0116 |         extractionStatus: json['extraction_status'] as String? ?? 'PENDING',
0117 |         extractedAmount: _number(json['extracted_amount']),
0118 |         extractedCurrency: json['extracted_currency'] as String?,
0119 |         confirmedAmount: _number(json['confirmed_amount']),
0120 |         confirmedCurrency: json['confirmed_currency'] as String?,
0121 |         clientProposedAmount: _number(json['client_proposed_amount']),
0122 |         clientProposedCurrency: json['client_proposed_currency'] as String?,
0123 |         clientReportedIncorrectAmount:
0124 |             json['client_reported_incorrect_amount'] == true,
0125 |         amountConfidence: _number(json['amount_confidence']),
0126 |         includeInTotal: json['include_in_total'] as bool? ?? false,
0127 |         duplicateOf: json['duplicate_of'] as String?,
0128 |         extractionNotes: json['extraction_notes'] as String?,
0129 |         signedUrl: json['signed_url'] as String?,
0130 |         fields: (json['fields'] as List<dynamic>? ?? const [])
0131 |             .map(
0132 |                 (item) => ExtractedField.fromJson(item as Map<String, dynamic>))
0133 |             .toList(),
0134 |       );
0135 | }
0136 |
0137 | class ClaimDetails extends ClaimSummary {
0138 |   const ClaimDetails({
0139 |     required super.id,
0140 |     required super.reference,
0141 |     required super.patientName,
0142 |     required super.providerName,
0143 |     required super.currency,
0144 |     required super.status,
0145 |     required super.warningCount,
0146 |     required super.createdAt,
0147 |     required this.documents,
0148 |     required this.auditEvents,
0149 |     this.availableActions = const [],
0150 |     this.informationRequests = const [],
0151 |     this.workflow = const {},
0152 |     this.information = const {},
0153 |     super.claimedAmount,
0154 |     super.assignedTo,
0155 |   });
0156 |
0157 |   final List<ClaimDocument> documents;
0158 |   final List<Map<String, dynamic>> auditEvents;
0159 |   final List<String> availableActions;
0160 |   final List<Map<String, dynamic>> informationRequests;
0161 |   final Map<String, dynamic> workflow;
0162 |   final Map<String, dynamic> information;
0163 |
0164 |   factory ClaimDetails.fromJson(Map<String, dynamic> json) {
0165 |     final base = ClaimSummary.fromJson(json);
0166 |     return ClaimDetails(
0167 |       id: base.id,
0168 |       reference: base.reference,
0169 |       patientName: base.patientName,
0170 |       providerName: base.providerName,
0171 |       claimedAmount: base.claimedAmount,
0172 |       currency: base.currency,
0173 |       status: base.status,
0174 |       warningCount: base.warningCount,
0175 |       createdAt: base.createdAt,
0176 |       assignedTo: base.assignedTo,
0177 |       availableActions: List<String>.from(json['available_actions'] ?? []),
0178 |       informationRequests: (json['information_requests'] as List? ?? [])
0179 |           .map((r) => Map<String, dynamic>.from(r as Map))
0180 |           .toList(),
0181 |       workflow: Map<String, dynamic>.from(json['workflow'] as Map? ?? {}),
0182 |       information: Map<String, dynamic>.from(json['information'] as Map? ?? {}),
0183 |       documents: (json['documents'] as List<dynamic>? ?? const [])
0184 |           .map((item) => ClaimDocument.fromJson(item as Map<String, dynamic>))
0185 |           .toList(),
0186 |       auditEvents: (json['audit_events'] as List<dynamic>? ?? const [])
0187 |           .map((item) => Map<String, dynamic>.from(item as Map))
0188 |           .toList(),
0189 |     );
0190 |   }
0191 | }
0192 |
0193 | class DashboardData {
0194 |   const DashboardData({
0195 |     required this.total,
0196 |     required this.processing,
0197 |     required this.reviewRequired,
0198 |     required this.verified,
0199 |     required this.failed,
0200 |     required this.recent,
0201 |     this.byStatus = const {},
0202 |     this.actionRequired = const [],
0203 |     this.unassigned = 0,
0204 |   });
0205 |   final int total;
0206 |   final int processing;
0207 |   final int reviewRequired;
0208 |   final int verified;
0209 |   final int failed;
0210 |   final List<ClaimSummary> recent;
0211 |   final Map<String, int> byStatus;
0212 |   final List<ClaimSummary> actionRequired;
0213 |   final int unassigned;
0214 |
0215 |   factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
0216 |         actionRequired: (json['action_required_claims'] as List? ?? [])
0217 |             .map((row) =>
0218 |                 ClaimSummary.fromJson(Map<String, dynamic>.from(row as Map)))
0219 |             .toList(),
0220 |         unassigned: json['unassigned'] as int? ?? 0,
0221 |         byStatus: Map<String, int>.from(json['by_status'] as Map? ?? {}),
0222 |         total: json['total_claims'] as int,
0223 |         processing: json['processing'] as int,
0224 |         reviewRequired: json['review_required'] as int,
0225 |         verified: json['verified'] as int,
0226 |         failed: json['processing_failed'] as int,
0227 |         recent: (json['recent_claims'] as List<dynamic>)
0228 |             .map((item) => ClaimSummary.fromJson(item as Map<String, dynamic>))
0229 |             .toList(),
0230 |       );
0231 | }
0232 |
0233 | class DocumentConfirmation {
0234 |   DocumentConfirmation({
0235 |     required this.document,
0236 |     required this.include,
0237 |     required this.amount,
0238 |     required this.currency,
0239 |   });
0240 |   final ClaimDocument document;
0241 |   bool include;
0242 |   double? amount;
0243 |   String currency;
0244 |   bool amountReported = false;
0245 |
0246 |   Map<String, dynamic> toJson() => {
0247 |         'id': document.id,
0248 |         'include': include,
0249 |         'amount': amount,
0250 |         'currency': currency,
0251 |       };
0252 | }
0253 |
0254 | class FieldCorrection {
0255 |   const FieldCorrection({
0256 |     required this.id,
0257 |     required this.label,
0258 |     required this.value,
0259 |   });
0260 |   final String id;
0261 |   final String label;
0262 |   final String value;
0263 |   Map<String, dynamic> toJson() => {'id': id, 'value': value};
0264 | }
```

## mobile/claimlens_mobile/lib/models/selected_document.dart

12 lines. SHA-256: `a60a21435d96b3d1e1e435ef009aedc8e5bf9a5c4d41448389dbdd7ce9e6ad6c`.

Symbols: `SelectedDocument`: L3

```dart
0001 | import 'dart:typed_data';
0002 |
0003 | class SelectedDocument {
0004 |   const SelectedDocument({
0005 |     required this.name,
0006 |     required this.mimeType,
0007 |     required this.bytes,
0008 |   });
0009 |   final String name;
0010 |   final String mimeType;
0011 |   final Uint8List bytes;
0012 | }
```

## mobile/claimlens_mobile/lib/models/user_profile.dart

48 lines. SHA-256: `3b73047c17014ed0cfd76dccecf41058b7434ea2bf7dc54c63fe459b95fa1a80`.

Symbols: `UserProfile`: L1

```dart
0001 | class UserProfile {
0002 |   const UserProfile({
0003 |     required this.id,
0004 |     required this.displayName,
0005 |     required this.role,
0006 |     required this.status,
0007 |     this.email,
0008 |     this.phone = '',
0009 |     this.theme = 'system',
0010 |     this.notificationsEnabled = true,
0011 |     this.emailVerified = false,
0012 |     this.mustChangePassword = false,
0013 |     this.permissions = const [],
0014 |     this.verificationRequired = false,
0015 |   });
0016 |
0017 |   final String id;
0018 |   final String displayName;
0019 |   final String role;
0020 |   final String status;
0021 |   final String? email;
0022 |   final String phone, theme;
0023 |   final bool notificationsEnabled;
0024 |   final bool emailVerified, mustChangePassword;
0025 |   final List<String> permissions;
0026 |   final bool verificationRequired;
0027 |
0028 |   bool get isClient => role == 'client';
0029 |   bool get isAdmin => role == 'administrator';
0030 |   bool get isManager => isAdmin || role == 'supervisor';
0031 |   bool get isFinance =>
0032 |       role == 'finance' || permissions.contains('payments.record');
0033 |
0034 |   factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
0035 |         id: json['id'] as String,
0036 |         displayName: json['display_name'] as String,
0037 |         role: json['role'] as String,
0038 |         status: json['status'] as String,
0039 |         email: json['email'] as String?,
0040 |         phone: json['phone'] as String? ?? '',
0041 |         theme: json['theme'] as String? ?? 'system',
0042 |         notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
0043 |         emailVerified: json['email_verified'] as bool? ?? false,
0044 |         mustChangePassword: json['must_change_password'] as bool? ?? false,
0045 |         permissions: List<String>.from(json['permissions'] as List? ?? []),
0046 |         verificationRequired: json['verification_required'] as bool? ?? false,
0047 |       );
0048 | }
```

## mobile/claimlens_mobile/lib/providers/auth_provider.dart

159 lines. SHA-256: `ea8a0a276b6ea9ed550e8892839ed43b6caff68fe18b58aac103a226e1147758`.

Symbols: `AuthProvider`: L10

```dart
0001 | import 'package:flutter/foundation.dart';
0002 | import 'package:dio/dio.dart';
0003 |
0004 | import '../models/user_profile.dart';
0005 | import '../services/api_client.dart';
0006 | import '../services/auth_service.dart';
0007 | import '../services/push_service.dart';
0008 | import 'package:local_auth/local_auth.dart';
0009 |
0010 | class AuthProvider extends ChangeNotifier {
0011 |   AuthProvider(this.client) : service = AuthService(client) {
0012 |     client.onSessionExpired = () {
0013 |       user = null;
0014 |       notifyListeners();
0015 |     };
0016 |   }
0017 |   final ApiClient client;
0018 |   final AuthService service;
0019 |
0020 |   UserProfile? user;
0021 |   bool initialising = true;
0022 |   bool busy = false;
0023 |   String? error;
0024 |
0025 |   bool get authenticated => user != null;
0026 |   bool locked = false;
0027 |   DateTime lastActivity = DateTime.now();
0028 |   void touch() {
0029 |     if (!locked) lastActivity = DateTime.now();
0030 |   }
0031 |
0032 |   void lock() {
0033 |     if (user != null && !locked) {
0034 |       locked = true;
0035 |       notifyListeners();
0036 |     }
0037 |   }
0038 |
0039 |   Future<void> unlock(String password) async {
0040 |     await client.dio
0041 |         .post<dynamic>('/profile/unlock', data: {'password': password});
0042 |     locked = false;
0043 |     lastActivity = DateTime.now();
0044 |     notifyListeners();
0045 |   }
0046 |
0047 |   Future<bool> unlockWithDevice() async {
0048 |     final local = LocalAuthentication();
0049 |     if (!await local.isDeviceSupported()) {
0050 |       throw Exception(
0051 |           'Device authentication is unavailable. Use your password instead.');
0052 |     }
0053 |     if (!await local.authenticate(
0054 |         localizedReason: 'Unlock your ClaimLens workspace',
0055 |         persistAcrossBackgrounding: true)) {
0056 |       return false;
0057 |     }
0058 |     // Device authentication unlocks the local view. Server authorization and
0059 |     // active-account checks still run on every API request.
0060 |     await reloadProfile();
0061 |     locked = false;
0062 |     lastActivity = DateTime.now();
0063 |     notifyListeners();
0064 |     return true;
0065 |   }
0066 |
0067 |   Future<void> reloadProfile({bool refreshToken = false}) async {
0068 |     if (refreshToken && !await client.refreshSession()) {
0069 |       throw Exception('Sign in again to refresh your session.');
0070 |     }
0071 |     user = await service.profile();
0072 |     notifyListeners();
0073 |   }
0074 |
0075 |   Future<void> updateProfile(Map<String, dynamic> values) async {
0076 |     final response =
0077 |         await client.dio.put<Map<String, dynamic>>('/profile', data: values);
0078 |     user = UserProfile.fromJson(response.data!);
0079 |     notifyListeners();
0080 |   }
0081 |
0082 |   Future<void> changePassword(String current, String password) async {
0083 |     final response = await client.dio.post<Map<String, dynamic>>(
0084 |         '/profile/password',
0085 |         data: {'current_password': current, 'new_password': password});
0086 |     final data = response.data!;
0087 |     await client.saveSession(
0088 |         data['access_token'] as String, data['refresh_token'] as String);
0089 |     user = await service.profile();
0090 |     notifyListeners();
0091 |   }
0092 |
0093 |   void clearError() {
0094 |     error = null;
0095 |     notifyListeners();
0096 |   }
0097 |
0098 |   Future<void> initialise() async {
0099 |     initialising = true;
0100 |     error = null;
0101 |     notifyListeners();
0102 |     await client.initialise();
0103 |     if (client.hasSession) {
0104 |       try {
0105 |         user = await service.profile();
0106 |         locked = user?.isClient == false;
0107 |       } catch (exception) {
0108 |         final status =
0109 |             exception is DioException ? exception.response?.statusCode : null;
0110 |         if ([400, 401, 403, 404].contains(status)) {
0111 |           await client.clearSession();
0112 |         }
0113 |         error = readableApiError(exception);
0114 |       }
0115 |     }
0116 |     initialising = false;
0117 |     notifyListeners();
0118 |   }
0119 |
0120 |   Future<bool> login(String email, String password) async {
0121 |     busy = true;
0122 |     error = null;
0123 |     notifyListeners();
0124 |     try {
0125 |       user = await service.login(email, password);
0126 |       locked = false;
0127 |       lastActivity = DateTime.now();
0128 |       return true;
0129 |     } catch (exception) {
0130 |       error = readableApiError(exception);
0131 |       return false;
0132 |     } finally {
0133 |       busy = false;
0134 |       notifyListeners();
0135 |     }
0136 |   }
0137 |
0138 |   Future<void> logout() async {
0139 |     busy = true;
0140 |     notifyListeners();
0141 |     try {
0142 |       await PushService.unregister(client);
0143 |       await service.logout();
0144 |     } catch (_) {/* Local sign-out must work without a connection. */} finally {
0145 |       user = null;
0146 |       locked = false;
0147 |       busy = false;
0148 |       notifyListeners();
0149 |     }
0150 |   }
0151 |
0152 |   Future<void> changeServer(String value) async {
0153 |     await client.configureServer(value);
0154 |     user = null;
0155 |     locked = false;
0156 |     error = null;
0157 |     notifyListeners();
0158 |   }
0159 | }
```

## mobile/claimlens_mobile/lib/providers/claims_provider.dart

43 lines. SHA-256: `ea3355ea87d93260327393f8e34b20c47b2adf4ec100009799caa463227a8660`.

Symbols: `ClaimsProvider`: L7

```dart
0001 | import 'package:flutter/foundation.dart';
0002 |
0003 | import '../models/claim.dart';
0004 | import '../services/api_client.dart';
0005 | import '../services/claim_service.dart';
0006 |
0007 | class ClaimsProvider extends ChangeNotifier {
0008 |   ClaimsProvider(ApiClient client) : service = ClaimService(client);
0009 |   final ClaimService service;
0010 |
0011 |   DashboardData? dashboard;
0012 |   List<ClaimSummary> claims = const [];
0013 |   bool busy = false;
0014 |   String? error;
0015 |
0016 |   Future<void> loadDashboard() async {
0017 |     busy = true;
0018 |     error = null;
0019 |     notifyListeners();
0020 |     try {
0021 |       dashboard = await service.dashboard();
0022 |     } catch (exception) {
0023 |       error = readableApiError(exception);
0024 |     } finally {
0025 |       busy = false;
0026 |       notifyListeners();
0027 |     }
0028 |   }
0029 |
0030 |   Future<void> loadClaims({String? search, String? status}) async {
0031 |     busy = true;
0032 |     error = null;
0033 |     notifyListeners();
0034 |     try {
0035 |       claims = await service.list(search: search, status: status);
0036 |     } catch (exception) {
0037 |       error = readableApiError(exception);
0038 |     } finally {
0039 |       busy = false;
0040 |       notifyListeners();
0041 |     }
0042 |   }
0043 | }
```

## mobile/claimlens_mobile/lib/screens/app_shell.dart

163 lines. SHA-256: `0e7890eb815e81421c39ddaa2e5793b7c437ab68c2ee2574e8d00dce52f9dad7`.

Symbols: `AppShell`: L15; `_AppShellState`: L21

```dart
0001 | import 'dart:async';
0002 | import 'package:flutter/material.dart';
0003 | import '../widgets/claimlens_logo.dart';
0004 | import 'package:provider/provider.dart';
0005 | import '../providers/auth_provider.dart';
0006 | import '../services/workspace_service.dart';
0007 | import 'dashboard_screen.dart';
0008 | import 'history_screen.dart';
0009 | import 'new_claim_screen.dart';
0010 | import 'profile_screen.dart';
0011 | import 'workspace_screens.dart';
0012 | import '../services/push_service.dart';
0013 | import 'claim_details_screen.dart';
0014 |
0015 | class AppShell extends StatefulWidget {
0016 |   const AppShell({super.key});
0017 |   @override
0018 |   State<AppShell> createState() => _AppShellState();
0019 | }
0020 |
0021 | class _AppShellState extends State<AppShell> {
0022 |   int index = 0, unread = 0;
0023 |   Timer? timer;
0024 |   PushService? push;
0025 |   final Map<int, Widget> pages = {};
0026 |   @override
0027 |   void initState() {
0028 |     super.initState();
0029 |     refreshBadge();
0030 |     push = PushService(context.read<AuthProvider>().client);
0031 |     push!.initialise(onOpen: (reference) {
0032 |       if (mounted) {
0033 |         Navigator.push(
0034 |             context,
0035 |             MaterialPageRoute(
0036 |                 builder: (_) => ClaimDetailsScreen(reference: reference)));
0037 |       }
0038 |     });
0039 |     timer = Timer.periodic(const Duration(seconds: 30), (_) => refreshBadge());
0040 |   }
0041 |
0042 |   Future<void> refreshBadge() async {
0043 |     try {
0044 |       final result =
0045 |           await workspaceApi(context).get<List<dynamic>>('/notifications');
0046 |       if (mounted) {
0047 |         setState(
0048 |             () => unread = result.data!.where((r) => r['read'] != true).length);
0049 |       }
0050 |     } catch (_) {/* The notifications page provides errors and retry. */}
0051 |   }
0052 |
0053 |   @override
0054 |   void dispose() {
0055 |     timer?.cancel();
0056 |     push?.dispose();
0057 |     super.dispose();
0058 |   }
0059 |
0060 |   @override
0061 |   Widget build(BuildContext context) {
0062 |     final user = context.watch<AuthProvider>().user!;
0063 |     final client = user.isClient;
0064 |     pages.putIfAbsent(
0065 |         index,
0066 |         () => switch (index) {
0067 |               0 => const DashboardScreen(),
0068 |               1 => const HistoryScreen(),
0069 |               2 => client
0070 |                   ? const NotificationsScreen()
0071 |                   : HistoryScreen(
0072 |                       reviewOnly: !user.isFinance,
0073 |                       initialStatus: user.isFinance ? 'PAYMENT_PENDING' : null),
0074 |               _ => client ? const ProfileScreen() : const WorkspaceMenuScreen()
0075 |             });
0076 |     return Scaffold(
0077 |       appBar: index == 0
0078 |           ? AppBar(
0079 |               title: Row(children: [
0080 |                 const ClaimLensLogo(size: 28),
0081 |                 const SizedBox(width: 10),
0082 |                 const Flexible(
0083 |                     child: Text('ClaimLens',
0084 |                         overflow: TextOverflow.ellipsis,
0085 |                         style: TextStyle(fontWeight: FontWeight.w900)))
0086 |               ]),
0087 |               actions: [
0088 |                   if (MediaQuery.sizeOf(context).width >= 390 &&
0089 |                       MediaQuery.textScalerOf(context).scale(14) < 20)
0090 |                     Tooltip(
0091 |                         message: friendlyLabel(user.role),
0092 |                         child: Chip(
0093 |                             label: Text(
0094 |                                 client ? 'Client' : friendlyLabel(user.role),
0095 |                                 style:
0096 |                                     Theme.of(context).textTheme.labelSmall))),
0097 |                   IconButton(
0098 |                       tooltip: 'Notifications',
0099 |                       icon: Badge(
0100 |                           isLabelVisible:
0101 |                               unread > 0 && user.notificationsEnabled,
0102 |                           label: Text('$unread'),
0103 |                           child: const Icon(Icons.notifications_outlined)),
0104 |                       onPressed: () async {
0105 |                         await Navigator.push(
0106 |                             context,
0107 |                             MaterialPageRoute(
0108 |                                 builder: (_) => const NotificationsScreen()));
0109 |                         await refreshBadge();
0110 |                       })
0111 |                 ])
0112 |           : null,
0113 |       body: IndexedStack(
0114 |           index: index,
0115 |           children:
0116 |               List.generate(4, (i) => pages[i] ?? const SizedBox.shrink())),
0117 |       floatingActionButton: client && index < 2
0118 |           ? FloatingActionButton.extended(
0119 |               onPressed: () async {
0120 |                 await Navigator.push(context,
0121 |                     MaterialPageRoute(builder: (_) => const NewClaimScreen()));
0122 |                 if (mounted) {
0123 |                   setState(() {
0124 |                     pages.remove(0);
0125 |                     pages.remove(1);
0126 |                   });
0127 |                 }
0128 |               },
0129 |               icon: const Icon(Icons.add),
0130 |               label: const Text('New claim'))
0131 |           : null,
0132 |       bottomNavigationBar: NavigationBar(
0133 |           selectedIndex: index,
0134 |           onDestinationSelected: (v) => setState(() {
0135 |                 index = v;
0136 |                 pages.remove(v);
0137 |               }),
0138 |           destinations: [
0139 |             const NavigationDestination(
0140 |                 icon: Icon(Icons.space_dashboard_outlined),
0141 |                 selectedIcon: Icon(Icons.space_dashboard),
0142 |                 label: 'Overview'),
0143 |             const NavigationDestination(
0144 |                 icon: Icon(Icons.folder_outlined),
0145 |                 selectedIcon: Icon(Icons.folder),
0146 |                 label: 'Claims'),
0147 |             NavigationDestination(
0148 |                 icon: Icon(client
0149 |                     ? Icons.notifications_outlined
0150 |                     : Icons.fact_check_outlined),
0151 |                 label: client
0152 |                     ? 'Updates'
0153 |                     : user.isFinance
0154 |                         ? 'Payments'
0155 |                         : 'Review'),
0156 |             NavigationDestination(
0157 |                 icon: Icon(
0158 |                     client ? Icons.person_outline : Icons.grid_view_outlined),
0159 |                 label: client ? 'Account' : 'Workspace')
0160 |           ]),
0161 |     );
0162 |   }
0163 | }
```

## mobile/claimlens_mobile/lib/screens/claim_details_screen.dart

749 lines. SHA-256: `742ed89f8288c126505c3bec4194cca95320ab8f4dade2a42f5c9ce7aac4478b`.

Symbols: `ClaimDetailsScreen`: L19; `_ClaimDetailsScreenState`: L31; `_ProgressTimeline`: L603; `_Value`: L660; `_DocumentCard`: L691

```dart
0001 | import 'dart:async';
0002 | import 'package:flutter/material.dart';
0003 | import 'package:intl/intl.dart';
0004 | import 'package:provider/provider.dart';
0005 |
0006 | import '../models/claim.dart';
0007 | import '../providers/auth_provider.dart';
0008 | import '../providers/claims_provider.dart';
0009 | import '../services/api_client.dart';
0010 | import '../widgets/status_chip.dart';
0011 | import 'extracted_info_screen.dart';
0012 | import 'processing_screen.dart';
0013 | import '../services/workspace_service.dart';
0014 | import '../widgets/workspace_form.dart';
0015 | import 'staff_review_screen.dart';
0016 | import 'information_response_screen.dart';
0017 | import 'document_preview_screen.dart';
0018 |
0019 | class ClaimDetailsScreen extends StatefulWidget {
0020 |   const ClaimDetailsScreen({
0021 |     super.key,
0022 |     required this.reference,
0023 |     this.submitted = false,
0024 |   });
0025 |   final String reference;
0026 |   final bool submitted;
0027 |   @override
0028 |   State<ClaimDetailsScreen> createState() => _ClaimDetailsScreenState();
0029 | }
0030 |
0031 | class _ClaimDetailsScreenState extends State<ClaimDetailsScreen> {
0032 |   ClaimDetails? claim;
0033 |   String? error;
0034 |   bool loading = true;
0035 |   Timer? refreshTimer;
0036 |
0037 |   Future<void> editInformation() async {
0038 |     final current = claim!;
0039 |     final saved =
0040 |         await workspaceForm(context, title: 'Claim information', fields: [
0041 |       FormEntry('member_number', 'Member number',
0042 |           value: current.information['member_number']?.toString() ?? '',
0043 |           required: false),
0044 |       FormEntry('policy_number', 'Policy number',
0045 |           value: current.information['policy_number']?.toString() ?? '',
0046 |           required: false),
0047 |       FormEntry('treatment_date', 'Treatment date (YYYY-MM-DD)',
0048 |           value: current.information['treatment_date']?.toString() ?? '',
0049 |           required: false),
0050 |       FormEntry('description', 'Claim description',
0051 |           value: current.information['description']?.toString() ?? '',
0052 |           required: false,
0053 |           lines: 4)
0054 |     ], submit: (v) async {
0055 |       await workspaceApi(context)
0056 |           .put<dynamic>('/claims/${current.reference}/information', data: {
0057 |         ...v,
0058 |         'treatment_date': v['treatment_date'] == '' ? null : v['treatment_date']
0059 |       });
0060 |     });
0061 |     if (saved == true && mounted) await _load();
0062 |   }
0063 |
0064 |   Future<void> appeal() async {
0065 |     final saved = await workspaceForm(context,
0066 |         title: 'Request a reconsideration',
0067 |         explanation:
0068 |             'Explain why this decision should be reviewed. The review team may ask for additional evidence.',
0069 |         fields: const [
0070 |           FormEntry('reason', 'Reason for appeal (at least 10 characters)',
0071 |               lines: 6)
0072 |         ],
0073 |         button: 'Submit appeal', submit: (v) async {
0074 |       await workspaceApi(context)
0075 |           .post<dynamic>('/claims/${claim!.reference}/appeal', data: v);
0076 |     });
0077 |     if (saved == true && mounted) await _load();
0078 |   }
0079 |
0080 |   Future<void> deleteDraft() async {
0081 |     final yes = await showDialog<bool>(
0082 |         context: context,
0083 |         builder: (c) => AlertDialog(
0084 |                 title: const Text('Delete this draft?'),
0085 |                 content: const Text(
0086 |                     'The draft and its uploaded documents will be removed.'),
0087 |                 actions: [
0088 |                   TextButton(
0089 |                       onPressed: () => Navigator.pop(c, false),
0090 |                       child: const Text('Cancel')),
0091 |                   FilledButton(
0092 |                       onPressed: () => Navigator.pop(c, true),
0093 |                       child: const Text('Delete draft'))
0094 |                 ]));
0095 |     if (yes == true && mounted) {
0096 |       try {
0097 |         await workspaceApi(context)
0098 |             .delete<dynamic>('/claims/${claim!.reference}');
0099 |         if (mounted) Navigator.pop(context);
0100 |       } catch (e) {
0101 |         if (mounted) {
0102 |           ScaffoldMessenger.of(context)
0103 |               .showSnackBar(SnackBar(content: Text(readableApiError(e))));
0104 |         }
0105 |       }
0106 |     }
0107 |   }
0108 |
0109 |   @override
0110 |   void dispose() {
0111 |     refreshTimer?.cancel();
0112 |     super.dispose();
0113 |   }
0114 |
0115 |   Future<void> _action(String action) async {
0116 |     final current = claim!;
0117 |     if (action == 'correct') {
0118 |       final saved = await Navigator.push<bool>(context,
0119 |           MaterialPageRoute(builder: (_) => StaffReviewScreen(claim: current)));
0120 |       if (saved == true && mounted) await _load();
0121 |       return;
0122 |     }
0123 |     try {
0124 |       final api = workspaceApi(context);
0125 |       final entries = <FormEntry>[];
0126 |       if (action == 'assign') {
0127 |         final response = await api.get<List<dynamic>>('/workspace/officers');
0128 |         final options = {
0129 |           for (final row in response.data!)
0130 |             row['id'] as String: row['display_name'] as String
0131 |         };
0132 |         if (options.isEmpty) {
0133 |           throw Exception(
0134 |               'Create an active claims officer account in User access first.');
0135 |         }
0136 |         entries.add(FormEntry('assignee', 'Claims officer',
0137 |             value: current.assignedTo ?? '', options: options));
0138 |       }
0139 |       if (action == 'approve') {
0140 |         entries.add(FormEntry(
0141 |             'approved_amount', 'Approved amount (${current.currency})',
0142 |             value: current.claimedAmount?.toStringAsFixed(2) ?? '',
0143 |             numeric: true));
0144 |       }
0145 |       if (action == 'approve' || action == 'reject') {
0146 |         entries.add(const FormEntry(
0147 |             'notes', 'Decision notes (at least 5 characters)',
0148 |             lines: 4));
0149 |       }
0150 |       if (action == 'request-information') {
0151 |         entries.addAll(const [
0152 |           FormEntry('reason', 'Reason for the request'),
0153 |           FormEntry('questions', 'Questions for the client', lines: 4),
0154 |           FormEntry('required_documents', 'Required documents',
0155 |               required: false, lines: 3),
0156 |           FormEntry('response_deadline', 'Response deadline (YYYY-MM-DD)',
0157 |               required: false),
0158 |           FormEntry('internal_note', 'Internal note (staff only)',
0159 |               required: false, lines: 3)
0160 |         ]);
0161 |       }
0162 |       if (action == 'paid') {
0163 |         entries.addAll([
0164 |           const FormEntry('payment_reference', 'Payment reference'),
0165 |           FormEntry('payment_method', 'Payment method',
0166 |               value: 'bank_transfer',
0167 |               options:
0168 |                   labelOptions(['bank_transfer', 'cheque', 'cash', 'other']))
0169 |         ]);
0170 |       }
0171 |       if (!mounted) return;
0172 |       final saved = await workspaceForm(context,
0173 |           title: friendlyLabel(action),
0174 |           fields: entries,
0175 |           explanation: switch (action) {
0176 |             'verify' =>
0177 |               'Confirm that you checked the source documents, patient, provider and payable amounts. This sends the claim for a supervisor decision.',
0178 |             'claim' =>
0179 |               'Assign this claim to yourself and begin reviewing its evidence.',
0180 |             'payment-pending' =>
0181 |               'Mark this approved claim as awaiting payment.',
0182 |             'paid' =>
0183 |               'Confirm that payment has been completed. This records settlement; it does not transfer money.',
0184 |             _ => null
0185 |           },
0186 |           button: action == 'assign'
0187 |               ? 'Save assignment'
0188 |               : friendlyLabel(action), submit: (values) async {
0189 |         final payload = <String, dynamic>{...values};
0190 |         if (payload['response_deadline'] == '') {
0191 |           payload['response_deadline'] = null;
0192 |         }
0193 |         await api.post<dynamic>('/claims/${current.reference}/actions/$action',
0194 |             data: payload);
0195 |       });
0196 |       if (saved == true && mounted) await _load();
0197 |     } catch (exception) {
0198 |       if (mounted) {
0199 |         ScaffoldMessenger.of(context)
0200 |             .showSnackBar(SnackBar(content: Text(readableApiError(exception))));
0201 |       }
0202 |     }
0203 |   }
0204 |
0205 |   @override
0206 |   void initState() {
0207 |     super.initState();
0208 |     _load();
0209 |   }
0210 |
0211 |   Future<void> _load() async {
0212 |     setState(() {
0213 |       loading = true;
0214 |       error = null;
0215 |     });
0216 |     try {
0217 |       claim = await context.read<ClaimsProvider>().service.details(
0218 |             widget.reference,
0219 |           );
0220 |       refreshTimer?.cancel();
0221 |       if (mounted && claim!.status == 'PROCESSING') {
0222 |         refreshTimer = Timer(const Duration(seconds: 4), _load);
0223 |       }
0224 |     } catch (exception) {
0225 |       error = readableApiError(exception);
0226 |     } finally {
0227 |       if (mounted) setState(() => loading = false);
0228 |     }
0229 |   }
0230 |
0231 |   @override
0232 |   Widget build(BuildContext context) {
0233 |     final isClient = context.watch<AuthProvider>().user?.isClient ?? false;
0234 |     return Scaffold(
0235 |       appBar: AppBar(
0236 |         title: Text(widget.reference),
0237 |         actions: [
0238 |           IconButton(
0239 |             onPressed: loading ? null : _load,
0240 |             icon: const Icon(Icons.refresh),
0241 |           ),
0242 |         ],
0243 |       ),
0244 |       body: loading
0245 |           ? const Center(child: CircularProgressIndicator())
0246 |           : claim == null
0247 |               ? Center(
0248 |                   child: Padding(
0249 |                     padding: const EdgeInsets.all(24),
0250 |                     child: Text(error ?? 'Claim not found.'),
0251 |                   ),
0252 |                 )
0253 |               : RefreshIndicator(
0254 |                   onRefresh: _load,
0255 |                   child: ListView(
0256 |                     padding: const EdgeInsets.all(16),
0257 |                     children: [
0258 |                       if (widget.submitted)
0259 |                         Card(
0260 |                           color: Colors.green.shade50,
0261 |                           child: const ListTile(
0262 |                             leading:
0263 |                                 Icon(Icons.check_circle, color: Colors.green),
0264 |                             title: Text('Claim submitted'),
0265 |                             subtitle: Text(
0266 |                               'You can follow its status from this page.',
0267 |                             ),
0268 |                           ),
0269 |                         ),
0270 |                       Wrap(
0271 |                         spacing: 12,
0272 |                         runSpacing: 8,
0273 |                         children: [
0274 |                           Text(
0275 |                             claim!.reference,
0276 |                             style: Theme.of(context)
0277 |                                 .textTheme
0278 |                                 .headlineSmall
0279 |                                 ?.copyWith(fontWeight: FontWeight.w900),
0280 |                           ),
0281 |                           StatusChip(status: claim!.status),
0282 |                         ],
0283 |                       ),
0284 |                       const SizedBox(height: 16),
0285 |                       Card(
0286 |                         child: Padding(
0287 |                           padding: const EdgeInsets.all(16),
0288 |                           child: Column(
0289 |                             children: [
0290 |                               _Value(
0291 |                                 label: 'Patient',
0292 |                                 value: claim!.patientName.isEmpty
0293 |                                     ? 'Awaiting confirmation'
0294 |                                     : claim!.patientName,
0295 |                               ),
0296 |                               _Value(
0297 |                                 label: 'Provider',
0298 |                                 value: claim!.providerName.isEmpty
0299 |                                     ? 'Awaiting confirmation'
0300 |                                     : claim!.providerName,
0301 |                               ),
0302 |                               _Value(
0303 |                                 label: 'Amount',
0304 |                                 value: claim!.claimedAmount == null
0305 |                                     ? 'Awaiting confirmation'
0306 |                                     : '${claim!.currency} ${claim!.claimedAmount!.toStringAsFixed(2)}',
0307 |                               ),
0308 |                               _Value(
0309 |                                 label: 'Client',
0310 |                                 value: claim!.workflow['client_name']
0311 |                                         ?.toString() ??
0312 |                                     'Not available',
0313 |                               ),
0314 |                               _Value(
0315 |                                 label: 'Officer',
0316 |                                 value: claim!.workflow['assigned_officer_name']
0317 |                                         ?.toString() ??
0318 |                                     'Awaiting assignment',
0319 |                               ),
0320 |                               if (claim!.workflow['approved_amount'] != null)
0321 |                                 _Value(
0322 |                                     label: 'Approved',
0323 |                                     value:
0324 |                                         '${claim!.currency} ${claim!.workflow['approved_amount']}'),
0325 |                               if (claim!.workflow['decision_notes'] != null)
0326 |                                 _Value(
0327 |                                     label: 'Decision',
0328 |                                     value: claim!.workflow['decision_notes']
0329 |                                         .toString()),
0330 |                               if (claim!.workflow['paid_at'] != null)
0331 |                                 _Value(
0332 |                                     label: 'Paid',
0333 |                                     value: claim!.workflow['paid_at']
0334 |                                         .toString()
0335 |                                         .substring(0, 10)),
0336 |                               _Value(
0337 |                                 label: 'Created',
0338 |                                 value: DateFormat(
0339 |                                   'dd MMM yyyy, HH:mm',
0340 |                                 ).format(claim!.createdAt.toLocal()),
0341 |                                 last: true,
0342 |                               ),
0343 |                             ],
0344 |                           ),
0345 |                         ),
0346 |                       ),
0347 |                       const SizedBox(height: 16),
0348 |                       _ProgressTimeline(status: claim!.status),
0349 |                       const SizedBox(height: 16),
0350 |                       if (claim!.information.isNotEmpty)
0351 |                         Card(
0352 |                             child: Padding(
0353 |                                 padding: const EdgeInsets.all(16),
0354 |                                 child: Column(
0355 |                                     crossAxisAlignment:
0356 |                                         CrossAxisAlignment.stretch,
0357 |                                     children: [
0358 |                                       Text('Claim information',
0359 |                                           style: Theme.of(context)
0360 |                                               .textTheme
0361 |                                               .titleMedium),
0362 |                                       const SizedBox(height: 10),
0363 |                                       for (final entry
0364 |                                           in claim!.information.entries)
0365 |                                         if (entry.value != null &&
0366 |                                             entry.value.toString().isNotEmpty)
0367 |                                           Padding(
0368 |                                               padding:
0369 |                                                   const EdgeInsets.symmetric(
0370 |                                                       vertical: 6),
0371 |                                               child: Text(
0372 |                                                   '${friendlyLabel(entry.key)}: ${entry.value}'))
0373 |                                     ]))),
0374 |                       const SizedBox(height: 12),
0375 |                       Wrap(spacing: 8, runSpacing: 8, children: [
0376 |                         if (isClient &&
0377 |                             ['UPLOADED', 'PROCESSING_FAILED']
0378 |                                 .contains(claim!.status) &&
0379 |                             claim!.workflow['needs_reconfirmation'] !=
0380 |                                 true) ...[
0381 |                           OutlinedButton.icon(
0382 |                               onPressed: editInformation,
0383 |                               icon: const Icon(Icons.edit_note),
0384 |                               label: const Text('Edit claim information')),
0385 |                           TextButton.icon(
0386 |                               onPressed: deleteDraft,
0387 |                               icon: const Icon(Icons.delete_outline),
0388 |                               label: const Text('Delete draft'))
0389 |                         ],
0390 |                         if (!['UPLOADED', 'PROCESSING', 'PROCESSING_FAILED']
0391 |                             .contains(claim!.status))
0392 |                           OutlinedButton.icon(
0393 |                               onPressed: () => Navigator.push(
0394 |                                   context,
0395 |                                   MaterialPageRoute(
0396 |                                       builder: (_) => DocumentPreviewScreen(
0397 |                                           reference: claim!.reference,
0398 |                                           documentId: 'receipt',
0399 |                                           name: 'Submission receipt'))),
0400 |                               icon: const Icon(Icons.receipt_long_outlined),
0401 |                               label: const Text('Submission receipt')),
0402 |                         if (isClient && claim!.status == 'REJECTED')
0403 |                           OutlinedButton.icon(
0404 |                               onPressed: appeal,
0405 |                               icon: const Icon(Icons.rate_review_outlined),
0406 |                               label: const Text('Request reconsideration')),
0407 |                       ]),
0408 |                       if (!isClient && claim!.availableActions.isNotEmpty) ...[
0409 |                         const SizedBox(height: 24),
0410 |                         Text('Review actions',
0411 |                             style: Theme.of(context).textTheme.titleLarge),
0412 |                         const SizedBox(height: 12),
0413 |                         Wrap(
0414 |                             spacing: 10,
0415 |                             runSpacing: 10,
0416 |                             children: claim!.availableActions
0417 |                                 .where((a) => a != 'respond')
0418 |                                 .map((action) => FilledButton.tonalIcon(
0419 |                                     onPressed: () => _action(action),
0420 |                                     icon: Icon(switch (action) {
0421 |                                       'correct' => Icons.edit_outlined,
0422 |                                       'verify' => Icons.fact_check_outlined,
0423 |                                       'assign' ||
0424 |                                       'claim' =>
0425 |                                         Icons.person_add_alt,
0426 |                                       'approve' => Icons.check_circle_outline,
0427 |                                       'reject' => Icons.cancel_outlined,
0428 |                                       'request-information' =>
0429 |                                         Icons.help_outline,
0430 |                                       _ => Icons.payments_outlined
0431 |                                     }),
0432 |                                     label: Text(action == 'correct'
0433 |                                         ? 'Review & correct'
0434 |                                         : action == 'claim'
0435 |                                             ? 'Assign to me'
0436 |                                             : friendlyLabel(action))))
0437 |                                 .toList()),
0438 |                       ],
0439 |                       for (final info in claim!.informationRequests)
0440 |                         Padding(
0441 |                             padding: const EdgeInsets.only(top: 16),
0442 |                             child: Card(
0443 |                                 child: Padding(
0444 |                                     padding: const EdgeInsets.all(16),
0445 |                                     child: Column(
0446 |                                         crossAxisAlignment:
0447 |                                             CrossAxisAlignment.stretch,
0448 |                                         children: [
0449 |                                           Row(children: [
0450 |                                             const Icon(
0451 |                                                 Icons.question_answer_outlined),
0452 |                                             const SizedBox(width: 10),
0453 |                                             Expanded(
0454 |                                                 child: Text(
0455 |                                                     info['status'] == 'OPEN'
0456 |                                                         ? 'Information needed'
0457 |                                                         : 'Information received',
0458 |                                                     style: Theme.of(context)
0459 |                                                         .textTheme
0460 |                                                         .titleMedium))
0461 |                                           ]),
0462 |                                           const SizedBox(height: 12),
0463 |                                           Text(
0464 |                                               info['reason']?.toString() ?? ''),
0465 |                                           const SizedBox(height: 8),
0466 |                                           Text(info['questions']?.toString() ??
0467 |                                               ''),
0468 |                                           if ((info['required_documents'] ??
0469 |                                                   '') !=
0470 |                                               '')
0471 |                                             Padding(
0472 |                                                 padding: const EdgeInsets.only(
0473 |                                                     top: 8),
0474 |                                                 child: Text(
0475 |                                                     'Requested documents: ${info['required_documents']}')),
0476 |                                           if (info['response_deadline'] != null)
0477 |                                             Text(
0478 |                                                 'Respond by ${info['response_deadline']}'),
0479 |                                           if (!isClient &&
0480 |                                               (info['internal_note'] ?? '') !=
0481 |                                                   '')
0482 |                                             Padding(
0483 |                                                 padding: const EdgeInsets.only(
0484 |                                                     top: 12),
0485 |                                                 child: Text(
0486 |                                                     'Staff note: ${info['internal_note']}')),
0487 |                                           if (info['response_text'] != null)
0488 |                                             Padding(
0489 |                                                 padding: const EdgeInsets.only(
0490 |                                                     top: 12),
0491 |                                                 child: Text(
0492 |                                                     'Client response: ${info['response_text']}')),
0493 |                                           if (isClient &&
0494 |                                               info['status'] == 'OPEN' &&
0495 |                                               claim!.availableActions
0496 |                                                   .contains('respond'))
0497 |                                             Padding(
0498 |                                                 padding: const EdgeInsets.only(
0499 |                                                     top: 12),
0500 |                                                 child: FilledButton.icon(
0501 |                                                     onPressed: () async {
0502 |                                                       final saved = await Navigator.push<
0503 |                                                               bool>(
0504 |                                                           context,
0505 |                                                           MaterialPageRoute(
0506 |                                                               builder: (_) =>
0507 |                                                                   InformationResponseScreen(
0508 |                                                                       reference:
0509 |                                                                           claim!
0510 |                                                                               .reference,
0511 |                                                                       request:
0512 |                                                                           info)));
0513 |                                                       if (saved == true &&
0514 |                                                           mounted) {
0515 |                                                         await _load();
0516 |                                                       }
0517 |                                                     },
0518 |                                                     icon:
0519 |                                                         const Icon(Icons.reply),
0520 |                                                     label: const Text(
0521 |                                                         'Provide information'))),
0522 |                                         ])))),
0523 |                       if (isClient && claim!.status == 'UPLOADED') ...[
0524 |                         const SizedBox(height: 12),
0525 |                         FilledButton.icon(
0526 |                           onPressed: () => Navigator.push(
0527 |                             context,
0528 |                             MaterialPageRoute(
0529 |                               builder: (_) => ExtractedInfoScreen(
0530 |                                   reference: claim!.reference),
0531 |                             ),
0532 |                           ),
0533 |                           icon: const Icon(Icons.fact_check_outlined),
0534 |                           label: const Text('Confirm extracted information'),
0535 |                         ),
0536 |                       ],
0537 |                       if (isClient &&
0538 |                           (claim!.status == 'PROCESSING_FAILED' ||
0539 |                               (claim!.status == 'UPLOADED' &&
0540 |                                   claim!.documents.any(
0541 |                                     (document) =>
0542 |                                         document.extractionStatus == 'FAILED',
0543 |                                   )))) ...[
0544 |                         const SizedBox(height: 12),
0545 |                         FilledButton.icon(
0546 |                           onPressed: () => Navigator.pushReplacement(
0547 |                             context,
0548 |                             MaterialPageRoute(
0549 |                               builder: (_) =>
0550 |                                   ProcessingScreen(reference: claim!.reference),
0551 |                             ),
0552 |                           ),
0553 |                           icon: const Icon(Icons.refresh),
0554 |                           label: const Text('Retry processing'),
0555 |                         ),
0556 |                       ],
0557 |                       const SizedBox(height: 24),
0558 |                       Text(
0559 |                         'Documents (${claim!.documents.length})',
0560 |                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
0561 |                               fontWeight: FontWeight.w800,
0562 |                             ),
0563 |                       ),
0564 |                       const SizedBox(height: 10),
0565 |                       ...claim!.documents.map(
0566 |                         (document) => _DocumentCard(
0567 |                             document: document, reference: claim!.reference),
0568 |                       ),
0569 |                       const SizedBox(height: 24),
0570 |                       Text(
0571 |                         'Audit history',
0572 |                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
0573 |                               fontWeight: FontWeight.w800,
0574 |                             ),
0575 |                       ),
0576 |                       const SizedBox(height: 10),
0577 |                       if (claim!.auditEvents.isEmpty)
0578 |                         const Text('No audit events are available.'),
0579 |                       ...claim!.auditEvents.map(
0580 |                         (event) => ListTile(
0581 |                           contentPadding: EdgeInsets.zero,
0582 |                           leading: const Icon(Icons.circle, size: 10),
0583 |                           title: Text(
0584 |                             (event['event_type'] as String)
0585 |                                 .replaceAll('_', ' '),
0586 |                           ),
0587 |                           subtitle: Text(
0588 |                             DateFormat('dd MMM yyyy, HH:mm').format(
0589 |                               DateTime.parse(
0590 |                                 event['created_at'] as String,
0591 |                               ).toLocal(),
0592 |                             ),
0593 |                           ),
0594 |                         ),
0595 |                       ),
0596 |                     ],
0597 |                   ),
0598 |                 ),
0599 |     );
0600 |   }
0601 | }
0602 |
0603 | class _ProgressTimeline extends StatelessWidget {
0604 |   const _ProgressTimeline({required this.status});
0605 |   final String status;
0606 |   @override
0607 |   Widget build(BuildContext context) {
0608 |     final stage = switch (status) {
0609 |       'UPLOADED' || 'PROCESSING' || 'PROCESSING_FAILED' => 0,
0610 |       'REVIEW_REQUIRED' ||
0611 |       'INFORMATION_REQUIRED' ||
0612 |       'INFORMATION_RECEIVED' =>
0613 |         1,
0614 |       'VERIFIED' => 2,
0615 |       'APPROVED' || 'PAYMENT_PENDING' || 'REJECTED' => 3,
0616 |       'PAID' => 4,
0617 |       _ => 0
0618 |     };
0619 |     return Card(
0620 |         child: Padding(
0621 |             padding: const EdgeInsets.all(16),
0622 |             child: Column(
0623 |                 crossAxisAlignment: CrossAxisAlignment.stretch,
0624 |                 children: [
0625 |                   Text('Claim progress',
0626 |                       style: Theme.of(context).textTheme.titleMedium),
0627 |                   const SizedBox(height: 14),
0628 |                   for (final (index, label) in [
0629 |                     'Documents uploaded',
0630 |                     'Evidence review',
0631 |                     'Verified',
0632 |                     status == 'REJECTED' ? 'Rejected' : 'Decision',
0633 |                     'Payment completed'
0634 |                   ].indexed)
0635 |                     Padding(
0636 |                         padding: const EdgeInsets.symmetric(vertical: 5),
0637 |                         child: Row(children: [
0638 |                           Icon(
0639 |                               index < stage || status == 'PAID'
0640 |                                   ? Icons.check_circle
0641 |                                   : index == stage
0642 |                                       ? Icons.radio_button_checked
0643 |                                       : Icons.radio_button_unchecked,
0644 |                               size: 20,
0645 |                               color: index <= stage
0646 |                                   ? Theme.of(context).colorScheme.primary
0647 |                                   : Theme.of(context).colorScheme.outline),
0648 |                           const SizedBox(width: 12),
0649 |                           Expanded(
0650 |                               child: Text(label,
0651 |                                   style: TextStyle(
0652 |                                       fontWeight: index == stage
0653 |                                           ? FontWeight.bold
0654 |                                           : FontWeight.normal)))
0655 |                         ]))
0656 |                 ])));
0657 |   }
0658 | }
0659 |
0660 | class _Value extends StatelessWidget {
0661 |   const _Value({required this.label, required this.value, this.last = false});
0662 |   final String label;
0663 |   final String value;
0664 |   final bool last;
0665 |   @override
0666 |   Widget build(BuildContext context) => Container(
0667 |         padding: const EdgeInsets.symmetric(vertical: 10),
0668 |         decoration: BoxDecoration(
0669 |           border: last
0670 |               ? null
0671 |               : Border(bottom: BorderSide(color: Colors.grey.shade200)),
0672 |         ),
0673 |         child: Row(
0674 |           crossAxisAlignment: CrossAxisAlignment.start,
0675 |           children: [
0676 |             SizedBox(
0677 |               width: 90,
0678 |               child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
0679 |             ),
0680 |             Expanded(
0681 |               child: Text(
0682 |                 value,
0683 |                 style: const TextStyle(fontWeight: FontWeight.w700),
0684 |               ),
0685 |             ),
0686 |           ],
0687 |         ),
0688 |       );
0689 | }
0690 |
0691 | class _DocumentCard extends StatelessWidget {
0692 |   const _DocumentCard({required this.document, required this.reference});
0693 |   final ClaimDocument document;
0694 |   final String reference;
0695 |   @override
0696 |   Widget build(BuildContext context) => Card(
0697 |         margin: const EdgeInsets.only(bottom: 10),
0698 |         child: ExpansionTile(
0699 |           leading: const Icon(Icons.description_outlined),
0700 |           title: Text(
0701 |             document.originalName,
0702 |             maxLines: 2,
0703 |             overflow: TextOverflow.ellipsis,
0704 |           ),
0705 |           subtitle: Text(
0706 |             '${document.documentType.replaceAll('_', ' ')} Â· ${document.extractionStatus.replaceAll('_', ' ')}',
0707 |           ),
0708 |           childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
0709 |           children: [
0710 |             if (document.signedUrl != null)
0711 |               Align(
0712 |                 alignment: Alignment.centerLeft,
0713 |                 child: TextButton.icon(
0714 |                   onPressed: () => Navigator.push(
0715 |                       context,
0716 |                       MaterialPageRoute(
0717 |                           builder: (_) => DocumentPreviewScreen(
0718 |                               reference: reference,
0719 |                               documentId: document.id,
0720 |                               name: document.originalName))),
0721 |                   icon: const Icon(Icons.open_in_new),
0722 |                   label: const Text('View source document'),
0723 |                 ),
0724 |               ),
0725 |             if (document.extractionNotes != null)
0726 |               Align(
0727 |                 alignment: Alignment.centerLeft,
0728 |                 child: Text(
0729 |                   document.extractionNotes!,
0730 |                   style: TextStyle(color: Theme.of(context).colorScheme.error),
0731 |                 ),
0732 |               ),
0733 |             if (document.fields.isEmpty)
0734 |               const Align(
0735 |                 alignment: Alignment.centerLeft,
0736 |                 child: Text('No fields were extracted from this document.'),
0737 |               ),
0738 |             ...document.fields.map(
0739 |               (field) => ListTile(
0740 |                 contentPadding: EdgeInsets.zero,
0741 |                 title: Text(field.fieldName.replaceAll('_', ' ')),
0742 |                 subtitle: Text(field.normalizedValue),
0743 |                 trailing: Text('${(field.confidence * 100).round()}%'),
0744 |               ),
0745 |             ),
0746 |           ],
0747 |         ),
0748 |       );
0749 | }
```

## mobile/claimlens_mobile/lib/screens/claim_review_screen.dart

194 lines. SHA-256: `d8069357e6ef39380e2321c9e5c06acbc779bacdc86fa2be64033dbe9bc8e950`.

Symbols: `ClaimReviewScreen`: L9; `_ClaimReviewScreenState`: L27

```dart
0001 | import 'package:flutter/material.dart';
0002 | import 'package:provider/provider.dart';
0003 |
0004 | import '../models/claim.dart';
0005 | import '../providers/claims_provider.dart';
0006 | import '../services/api_client.dart';
0007 | import 'claim_details_screen.dart';
0008 |
0009 | class ClaimReviewScreen extends StatefulWidget {
0010 |   const ClaimReviewScreen({
0011 |     super.key,
0012 |     required this.reference,
0013 |     required this.patientName,
0014 |     required this.providerName,
0015 |     required this.documents,
0016 |     required this.fields,
0017 |   });
0018 |   final String reference;
0019 |   final String patientName;
0020 |   final String providerName;
0021 |   final List<DocumentConfirmation> documents;
0022 |   final List<FieldCorrection> fields;
0023 |   @override
0024 |   State<ClaimReviewScreen> createState() => _ClaimReviewScreenState();
0025 | }
0026 |
0027 | class _ClaimReviewScreenState extends State<ClaimReviewScreen> {
0028 |   bool busy = false;
0029 |   String? error;
0030 |
0031 |   double get total => widget.documents
0032 |       .where((item) => item.include)
0033 |       .fold(0, (sum, item) => sum + (item.amount ?? 0));
0034 |   String get currency =>
0035 |       widget.documents.firstWhere((item) => item.include).currency;
0036 |
0037 |   Future<void> _submit() async {
0038 |     setState(() {
0039 |       busy = true;
0040 |       error = null;
0041 |     });
0042 |     try {
0043 |       await context.read<ClaimsProvider>().service.confirm(
0044 |             widget.reference,
0045 |             widget.patientName,
0046 |             widget.providerName,
0047 |             widget.documents,
0048 |             widget.fields,
0049 |           );
0050 |       if (!mounted) return;
0051 |       context.read<ClaimsProvider>().loadDashboard();
0052 |       Navigator.pushAndRemoveUntil(
0053 |         context,
0054 |         MaterialPageRoute(
0055 |           builder: (_) =>
0056 |               ClaimDetailsScreen(reference: widget.reference, submitted: true),
0057 |         ),
0058 |         (route) => route.isFirst,
0059 |       );
0060 |     } catch (exception) {
0061 |       if (mounted) setState(() => error = readableApiError(exception));
0062 |     } finally {
0063 |       if (mounted) setState(() => busy = false);
0064 |     }
0065 |   }
0066 |
0067 |   @override
0068 |   Widget build(BuildContext context) => Scaffold(
0069 |         appBar: AppBar(title: const Text('Review and submit')),
0070 |         body: ListView(
0071 |           padding: EdgeInsets.fromLTRB(
0072 |               16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
0073 |           children: [
0074 |             Text(
0075 |               widget.reference,
0076 |               style: Theme.of(
0077 |                 context,
0078 |               ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
0079 |             ),
0080 |             const SizedBox(height: 16),
0081 |             Card(
0082 |               child: Padding(
0083 |                 padding: const EdgeInsets.all(16),
0084 |                 child: Column(
0085 |                   children: [
0086 |                     ListTile(
0087 |                       contentPadding: EdgeInsets.zero,
0088 |                       title: const Text('Patient'),
0089 |                       subtitle: Text(widget.patientName),
0090 |                     ),
0091 |                     ListTile(
0092 |                       contentPadding: EdgeInsets.zero,
0093 |                       title: const Text('Provider'),
0094 |                       subtitle: Text(widget.providerName),
0095 |                     ),
0096 |                   ],
0097 |                 ),
0098 |               ),
0099 |             ),
0100 |             const SizedBox(height: 16),
0101 |             ...widget.documents.map(
0102 |               (item) => ListTile(
0103 |                 leading: Icon(
0104 |                   item.include
0105 |                       ? Icons.check_circle
0106 |                       : Icons.remove_circle_outline,
0107 |                   color: item.include ? Colors.green : Colors.grey,
0108 |                 ),
0109 |                 title: Text(item.document.originalName),
0110 |                 subtitle: Text(
0111 |                   item.include
0112 |                       ? '${item.currency} ${item.amount!.toStringAsFixed(2)}'
0113 |                       : 'Not included in total',
0114 |                 ),
0115 |               ),
0116 |             ),
0117 |             if (widget.fields.isNotEmpty) ...[
0118 |               const Divider(height: 24),
0119 |               Text(
0120 |                 'Other extracted information',
0121 |                 style: Theme.of(
0122 |                   context,
0123 |                 ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
0124 |               ),
0125 |               ...widget.fields.map(
0126 |                 (field) => ListTile(
0127 |                   contentPadding: EdgeInsets.zero,
0128 |                   title: Text(field.label),
0129 |                   subtitle: Text(field.value),
0130 |                 ),
0131 |               ),
0132 |             ],
0133 |             const Divider(height: 32),
0134 |             Wrap(
0135 |               alignment: WrapAlignment.spaceBetween,
0136 |               spacing: 16,
0137 |               runSpacing: 8,
0138 |               children: [
0139 |                 Text('Claim total',
0140 |                     style: Theme.of(context).textTheme.titleLarge),
0141 |                 Text(
0142 |                   '$currency ${total.toStringAsFixed(2)}',
0143 |                   style: Theme.of(
0144 |                     context,
0145 |                   )
0146 |                       .textTheme
0147 |                       .headlineSmall
0148 |                       ?.copyWith(fontWeight: FontWeight.w900),
0149 |                 ),
0150 |               ],
0151 |             ),
0152 |             const SizedBox(height: 12),
0153 |             const Text(
0154 |               'By submitting, you send the OCR results and any corrections as a proposal. A claims officer will compare them with your source documents and verify the correct amount before a decision.',
0155 |             ),
0156 |             if (error != null)
0157 |               Padding(
0158 |                 padding: const EdgeInsets.only(top: 12),
0159 |                 child: Text(
0160 |                   error!,
0161 |                   style: TextStyle(color: Theme.of(context).colorScheme.error),
0162 |                 ),
0163 |               ),
0164 |             const SizedBox(height: 20),
0165 |             OutlinedButton.icon(
0166 |               onPressed: busy ? null : () => Navigator.pop(context),
0167 |               icon: const Icon(Icons.edit_outlined),
0168 |               label: const Text('Go back and edit'),
0169 |             ),
0170 |             const SizedBox(height: 8),
0171 |             TextButton(
0172 |               onPressed: busy
0173 |                   ? null
0174 |                   : () => Navigator.popUntil(context, (route) => route.isFirst),
0175 |               child: const Text('Cancel for now and keep as draft'),
0176 |             ),
0177 |             const SizedBox(height: 8),
0178 |             FilledButton.icon(
0179 |               onPressed: busy ? null : _submit,
0180 |               icon: busy
0181 |                   ? const SizedBox.square(
0182 |                       dimension: 18,
0183 |                       child: CircularProgressIndicator(strokeWidth: 2),
0184 |                     )
0185 |                   : const Icon(Icons.send),
0186 |               label: const Padding(
0187 |                 padding: EdgeInsets.symmetric(vertical: 14),
0188 |                 child: Text('Confirm and submit claim'),
0189 |               ),
0190 |             ),
0191 |           ],
0192 |         ),
0193 |       );
0194 | }
```

## mobile/claimlens_mobile/lib/screens/dashboard_screen.dart

286 lines. SHA-256: `5e455840a7a5fb7cf8b85f20ca5d0a5271fdc06b62b9fb81137fd08dbe260500`.

Symbols: `DashboardScreen`: L12; `_DashboardScreenState`: L18

```dart
0001 | import 'package:flutter/material.dart';
0002 | import 'package:provider/provider.dart';
0003 | import '../providers/auth_provider.dart';
0004 | import '../providers/claims_provider.dart';
0005 | import '../services/workspace_service.dart';
0006 | import '../widgets/claim_card.dart';
0007 | import 'history_screen.dart';
0008 | import 'help_screen.dart';
0009 | import 'new_claim_screen.dart';
0010 | import 'workspace_screens.dart';
0011 |
0012 | class DashboardScreen extends StatefulWidget {
0013 |   const DashboardScreen({super.key});
0014 |   @override
0015 |   State<DashboardScreen> createState() => _DashboardScreenState();
0016 | }
0017 |
0018 | class _DashboardScreenState extends State<DashboardScreen> {
0019 |   @override
0020 |   void initState() {
0021 |     super.initState();
0022 |     WidgetsBinding.instance.addPostFrameCallback(
0023 |         (_) => context.read<ClaimsProvider>().loadDashboard());
0024 |   }
0025 |
0026 |   void open(Widget screen) =>
0027 |       Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
0028 |   @override
0029 |   Widget build(BuildContext context) {
0030 |     final provider = context.watch<ClaimsProvider>();
0031 |     final user = context.watch<AuthProvider>().user!;
0032 |     final data = provider.dashboard;
0033 |     final needed = user.isClient
0034 |         ? (data?.byStatus['INFORMATION_REQUIRED'] ?? 0) +
0035 |             (data?.byStatus['UPLOADED'] ?? 0) +
0036 |             (data?.failed ?? 0)
0037 |         : user.isFinance
0038 |             ? (data?.byStatus['PAYMENT_PENDING'] ?? 0)
0039 |             : user.isAdmin
0040 |                 ? data?.unassigned ?? 0
0041 |                 : (data?.reviewRequired ?? 0) +
0042 |                     (data?.byStatus['INFORMATION_RECEIVED'] ?? 0);
0043 |     final metrics = <(String, int, IconData, String?)>[
0044 |       ('All claims', data?.total ?? 0, Icons.folder_copy_outlined, null),
0045 |       (
0046 |         user.isClient
0047 |             ? 'Action needed'
0048 |             : user.isAdmin
0049 |                 ? 'Unassigned'
0050 |                 : user.isFinance
0051 |                     ? 'Awaiting payment'
0052 |                     : 'Needs review',
0053 |         needed,
0054 |         Icons.pending_actions_outlined,
0055 |         user.isClient
0056 |             ? 'INFORMATION_REQUIRED'
0057 |             : user.isFinance
0058 |                 ? 'PAYMENT_PENDING'
0059 |                 : 'REVIEW_REQUIRED'
0060 |       ),
0061 |       ('Processing', data?.processing ?? 0, Icons.sync_outlined, 'PROCESSING'),
0062 |       (
0063 |         user.isClient || user.isFinance ? 'Paid claims' : 'Awaiting decision',
0064 |         user.isClient || user.isFinance
0065 |             ? data?.byStatus['PAID'] ?? 0
0066 |             : data?.verified ?? 0,
0067 |         Icons.task_alt,
0068 |         user.isClient || user.isFinance ? 'PAID' : 'VERIFIED'
0069 |       ),
0070 |     ];
0071 |     return Scaffold(
0072 |         body: RefreshIndicator(
0073 |             onRefresh: provider.loadDashboard,
0074 |             child: ListView(
0075 |                 physics: const AlwaysScrollableScrollPhysics(),
0076 |                 padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
0077 |                 children: [
0078 |                   Row(children: [
0079 |                     Expanded(
0080 |                         child: Column(
0081 |                             crossAxisAlignment: CrossAxisAlignment.start,
0082 |                             children: [
0083 |                           Text('Hello, ${user.displayName.split(' ').first}',
0084 |                               style: Theme.of(context)
0085 |                                   .textTheme
0086 |                                   .headlineSmall
0087 |                                   ?.copyWith(fontWeight: FontWeight.w800)),
0088 |                           const SizedBox(height: 4),
0089 |                           Text(user.isClient
0090 |                               ? 'Let’s take care of your claims.'
0091 |                               : '${friendlyLabel(user.role)} workspace')
0092 |                         ])),
0093 |                     IconButton(
0094 |                         tooltip: 'Refresh overview',
0095 |                         onPressed:
0096 |                             provider.busy ? null : provider.loadDashboard,
0097 |                         icon: const Icon(Icons.refresh))
0098 |                   ]),
0099 |                   const SizedBox(height: 22),
0100 |                   Container(
0101 |                       decoration: BoxDecoration(
0102 |                           gradient: const LinearGradient(
0103 |                               colors: [Color(0xff006773), Color(0xff129293)],
0104 |                               begin: Alignment.topLeft,
0105 |                               end: Alignment.bottomRight),
0106 |                           borderRadius: BorderRadius.circular(24)),
0107 |                       padding: const EdgeInsets.all(24),
0108 |                       child: Column(
0109 |                           crossAxisAlignment: CrossAxisAlignment.start,
0110 |                           children: [
0111 |                             const Icon(Icons.health_and_safety_outlined,
0112 |                                 size: 38, color: Colors.white),
0113 |                             const SizedBox(height: 14),
0114 |                             Text(
0115 |                                 user.isClient
0116 |                                     ? 'A clearer path to your claim'
0117 |                                     : user.isAdmin
0118 |                                         ? 'A well-managed workspace'
0119 |                                         : user.isFinance
0120 |                                             ? 'Track every settlement'
0121 |                                             : 'Give every claim a clear next step',
0122 |                                 style: Theme.of(context)
0123 |                                     .textTheme
0124 |                                     .headlineSmall
0125 |                                     ?.copyWith(
0126 |                                         color: Colors.white,
0127 |                                         fontWeight: FontWeight.w800)),
0128 |                             const SizedBox(height: 10),
0129 |                             Text(
0130 |                                 user.isClient
0131 |                                     ? 'Upload your evidence, check the details and follow every stage.'
0132 |                                     : user.isAdmin
0133 |                                         ? 'Manage people, permissions and claim operations in one place.'
0134 |                                         : user.isFinance
0135 |                                             ? 'Confirm approved amounts and record payment references.'
0136 |                                             : 'Review evidence, ask for information and record a considered decision.',
0137 |                                 style: const TextStyle(
0138 |                                     color: Colors.white, height: 1.5)),
0139 |                             const SizedBox(height: 20),
0140 |                             FilledButton.icon(
0141 |                                 style: FilledButton.styleFrom(
0142 |                                     backgroundColor: Colors.white,
0143 |                                     foregroundColor: const Color(0xff006773)),
0144 |                                 onPressed: () => open(user.isClient
0145 |                                     ? const NewClaimScreen()
0146 |                                     : user.isAdmin
0147 |                                         ? const UsersScreen()
0148 |                                         : HistoryScreen(
0149 |                                             reviewOnly: !user.isFinance,
0150 |                                             initialStatus: user.isFinance
0151 |                                                 ? 'PAYMENT_PENDING'
0152 |                                                 : null)),
0153 |                                 icon: Icon(user.isClient
0154 |                                     ? Icons.add
0155 |                                     : user.isAdmin
0156 |                                         ? Icons.manage_accounts_outlined
0157 |                                         : Icons.arrow_forward),
0158 |                                 label: Text(user.isClient
0159 |                                     ? 'Start a new claim'
0160 |                                     : user.isAdmin
0161 |                                         ? 'Manage user access'
0162 |                                         : user.isFinance
0163 |                                             ? 'Open payments'
0164 |                                             : 'Open review queue'))
0165 |                           ])),
0166 |                   const SizedBox(height: 22),
0167 |                   if (provider.error != null)
0168 |                     Card(
0169 |                         color: Theme.of(context).colorScheme.errorContainer,
0170 |                         child: Padding(
0171 |                             padding: const EdgeInsets.all(16),
0172 |                             child: Column(children: [
0173 |                               Text(provider.error!),
0174 |                               TextButton(
0175 |                                   onPressed: provider.loadDashboard,
0176 |                                   child: const Text('Try again'))
0177 |                             ]))),
0178 |                   if (provider.busy && data == null)
0179 |                     const LinearProgressIndicator(),
0180 |                   if (data != null) ...[
0181 |                     LayoutBuilder(builder: (context, box) {
0182 |                       final single = box.maxWidth < 300 ||
0183 |                           MediaQuery.textScalerOf(context).scale(16) > 24;
0184 |                       final width =
0185 |                           single ? box.maxWidth : (box.maxWidth - 12) / 2;
0186 |                       return Wrap(
0187 |                           spacing: 12,
0188 |                           runSpacing: 12,
0189 |                           children: metrics
0190 |                               .map((m) => SizedBox(
0191 |                                   width: width,
0192 |                                   child: Card(
0193 |                                       clipBehavior: Clip.antiAlias,
0194 |                                       child: InkWell(
0195 |                                           onTap: () => open(HistoryScreen(
0196 |                                               initialStatus: m.$4)),
0197 |                                           child: Padding(
0198 |                                               padding: const EdgeInsets.all(18),
0199 |                                               child: Column(
0200 |                                                   crossAxisAlignment:
0201 |                                                       CrossAxisAlignment.start,
0202 |                                                   children: [
0203 |                                                     Icon(m.$3,
0204 |                                                         color: Theme.of(context)
0205 |                                                             .colorScheme
0206 |                                                             .primary),
0207 |                                                     const SizedBox(height: 14),
0208 |                                                     Text('${m.$2}',
0209 |                                                         style: Theme.of(context)
0210 |                                                             .textTheme
0211 |                                                             .headlineMedium
0212 |                                                             ?.copyWith(
0213 |                                                                 fontWeight:
0214 |                                                                     FontWeight
0215 |                                                                         .w800)),
0216 |                                                     const SizedBox(height: 4),
0217 |                                                     Text(m.$1)
0218 |                                                   ]))))))
0219 |                               .toList());
0220 |                     }),
0221 |                     const SizedBox(height: 20),
0222 |                     Wrap(spacing: 8, runSpacing: 8, children: [
0223 |                       if (user.isClient)
0224 |                         ActionChip(
0225 |                             avatar: const Icon(Icons.drafts_outlined),
0226 |                             label: const Text('Saved drafts'),
0227 |                             onPressed: () => open(const HistoryScreen(
0228 |                                 initialStatus: 'UPLOADED'))),
0229 |                       ActionChip(
0230 |                           avatar: const Icon(Icons.help_outline),
0231 |                           label: const Text('Help & document checklist'),
0232 |                           onPressed: () => open(const HelpScreen())),
0233 |                       if (!user.isClient)
0234 |                         ActionChip(
0235 |                             avatar: const Icon(Icons.bar_chart),
0236 |                             label: const Text('Analytics'),
0237 |                             onPressed: () => open(const AnalyticsScreen()))
0238 |                     ]),
0239 |                     const SizedBox(height: 24),
0240 |                     Text('Action needed',
0241 |                         style: Theme.of(context)
0242 |                             .textTheme
0243 |                             .titleLarge
0244 |                             ?.copyWith(fontWeight: FontWeight.w800)),
0245 |                     const SizedBox(height: 12),
0246 |                     if (data.actionRequired.isEmpty)
0247 |                       const Card(
0248 |                           child: Padding(
0249 |                               padding: EdgeInsets.all(20),
0250 |                               child: Row(children: [
0251 |                                 Icon(Icons.check_circle_outline,
0252 |                                     color: Color(0xff087f8c)),
0253 |                                 SizedBox(width: 12),
0254 |                                 Expanded(
0255 |                                     child: Text(
0256 |                                         'You’re up to date. We’ll show anything that needs your attention here.'))
0257 |                               ]))),
0258 |                     ...data.actionRequired.map((claim) => Padding(
0259 |                         padding: const EdgeInsets.only(bottom: 12),
0260 |                         child: ClaimCard(claim: claim))),
0261 |                     const SizedBox(height: 24),
0262 |                     Row(children: [
0263 |                       Expanded(
0264 |                           child: Text('Recent claims',
0265 |                               style: Theme.of(context)
0266 |                                   .textTheme
0267 |                                   .titleLarge
0268 |                                   ?.copyWith(fontWeight: FontWeight.w800))),
0269 |                       TextButton(
0270 |                           onPressed: () => open(const HistoryScreen()),
0271 |                           child: const Text('View all'))
0272 |                     ]),
0273 |                     const SizedBox(height: 12),
0274 |                     if (data.recent.isEmpty)
0275 |                       const Card(
0276 |                           child: Padding(
0277 |                               padding: EdgeInsets.all(24),
0278 |                               child: Text(
0279 |                                   'No claims yet. Your submissions and their progress will appear here.'))),
0280 |                     ...data.recent.map((claim) => Padding(
0281 |                         padding: const EdgeInsets.only(bottom: 12),
0282 |                         child: ClaimCard(claim: claim))),
0283 |                   ],
0284 |                 ])));
0285 |   }
0286 | }
```

## mobile/claimlens_mobile/lib/screens/document_preview_screen.dart

118 lines. SHA-256: `80e1ac96c36dec7d8fb88b4586e2ef0cd320a805c48f6418078071cfa558d095`.

Symbols: `DocumentPreviewScreen`: L8; `_DocumentPreviewScreenState`: L19

```dart
0001 | import 'dart:convert';
0002 | import 'dart:typed_data';
0003 | import 'package:dio/dio.dart';
0004 | import 'package:flutter/material.dart';
0005 | import '../services/api_client.dart';
0006 | import '../services/workspace_service.dart';
0007 |
0008 | class DocumentPreviewScreen extends StatefulWidget {
0009 |   const DocumentPreviewScreen(
0010 |       {super.key,
0011 |       required this.reference,
0012 |       required this.documentId,
0013 |       required this.name});
0014 |   final String reference, documentId, name;
0015 |   @override
0016 |   State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
0017 | }
0018 |
0019 | class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
0020 |   Uint8List? bytes;
0021 |   String? text, error;
0022 |   bool busy = true;
0023 |   int page = 1, pages = 1;
0024 |   @override
0025 |   void initState() {
0026 |     super.initState();
0027 |     load();
0028 |   }
0029 |
0030 |   Future<void> load() async {
0031 |     setState(() {
0032 |       busy = true;
0033 |       error = null;
0034 |     });
0035 |     try {
0036 |       final result = await workspaceApi(context).get<List<int>>(
0037 |           widget.documentId == 'receipt'
0038 |               ? '/claims/${widget.reference}/receipt/preview'
0039 |               : '/claims/${widget.reference}/documents/${widget.documentId}/preview',
0040 |           queryParameters: {'page': page},
0041 |           options: Options(responseType: ResponseType.bytes));
0042 |       if (!mounted) return;
0043 |       setState(() {
0044 |         pages =
0045 |             int.tryParse(result.headers.value('X-Document-Pages') ?? '1') ?? 1;
0046 |         final data = Uint8List.fromList(result.data!);
0047 |         if ((result.headers.value('Content-Type') ?? '').startsWith('text/')) {
0048 |           text = utf8.decode(data);
0049 |           bytes = null;
0050 |         } else {
0051 |           bytes = data;
0052 |           text = null;
0053 |         }
0054 |       });
0055 |     } catch (e) {
0056 |       if (mounted) setState(() => error = readableApiError(e));
0057 |     } finally {
0058 |       if (mounted) setState(() => busy = false);
0059 |     }
0060 |   }
0061 |
0062 |   @override
0063 |   Widget build(BuildContext context) => Scaffold(
0064 |       appBar: AppBar(title: Text(widget.name)),
0065 |       body: Column(children: [
0066 |         if (busy) const LinearProgressIndicator(),
0067 |         Expanded(
0068 |             child: error != null
0069 |                 ? Center(
0070 |                     child: Padding(
0071 |                         padding: const EdgeInsets.all(24),
0072 |                         child: Column(
0073 |                             mainAxisSize: MainAxisSize.min,
0074 |                             children: [
0075 |                               Text(error!),
0076 |                               TextButton(
0077 |                                   onPressed: load,
0078 |                                   child: const Text('Try again'))
0079 |                             ])))
0080 |                 : text != null
0081 |                     ? SingleChildScrollView(
0082 |                         padding: const EdgeInsets.all(24),
0083 |                         child: SelectableText(text!))
0084 |                     : bytes != null
0085 |                         ? InteractiveViewer(
0086 |                             minScale: .5,
0087 |                             maxScale: 6,
0088 |                             child: Center(
0089 |                                 child:
0090 |                                     Image.memory(bytes!, fit: BoxFit.contain)))
0091 |                         : const SizedBox.shrink()),
0092 |         if (pages > 1)
0093 |           SafeArea(
0094 |               top: false,
0095 |               child:
0096 |                   Row(mainAxisAlignment: MainAxisAlignment.center, children: [
0097 |                 IconButton(
0098 |                     tooltip: 'Previous page',
0099 |                     onPressed: busy || page <= 1
0100 |                         ? null
0101 |                         : () {
0102 |                             page--;
0103 |                             load();
0104 |                           },
0105 |                     icon: const Icon(Icons.chevron_left)),
0106 |                 Text('Page $page of $pages'),
0107 |                 IconButton(
0108 |                     tooltip: 'Next page',
0109 |                     onPressed: busy || page >= pages
0110 |                         ? null
0111 |                         : () {
0112 |                             page++;
0113 |                             load();
0114 |                           },
0115 |                     icon: const Icon(Icons.chevron_right))
0116 |               ]))
0117 |       ]));
0118 | }
```

## mobile/claimlens_mobile/lib/screens/extracted_info_screen.dart

493 lines. SHA-256: `302b08d5da3f8737932eb4fd13d625d26393e3b8d75e25273d39f0989ef3e20d`.

Symbols: `ExtractedInfoScreen`: L11; `_ExtractedInfoScreenState`: L18; `_ConfidenceField`: L299; `_DocumentEditor`: L323

```dart
0001 | import 'package:flutter/material.dart';
0002 | import 'package:provider/provider.dart';
0003 |
0004 | import '../models/claim.dart';
0005 | import '../providers/claims_provider.dart';
0006 | import '../services/api_client.dart';
0007 | import 'claim_review_screen.dart';
0008 | import '../services/workspace_service.dart';
0009 | import 'document_preview_screen.dart';
0010 |
0011 | class ExtractedInfoScreen extends StatefulWidget {
0012 |   const ExtractedInfoScreen({super.key, required this.reference});
0013 |   final String reference;
0014 |   @override
0015 |   State<ExtractedInfoScreen> createState() => _ExtractedInfoScreenState();
0016 | }
0017 |
0018 | class _ExtractedInfoScreenState extends State<ExtractedInfoScreen> {
0019 |   final patient = TextEditingController();
0020 |   final provider = TextEditingController();
0021 |   final formKey = GlobalKey<FormState>();
0022 |   final confirmations = <DocumentConfirmation>[];
0023 |   final amountControllers = <String, TextEditingController>{};
0024 |   final fieldControllers = <String, TextEditingController>{};
0025 |   ClaimDetails? claim;
0026 |   bool loading = true;
0027 |   String? error;
0028 |   double? patientConfidence;
0029 |   double? providerConfidence;
0030 |   List<String> allowedCurrencies = [
0031 |     'MUR',
0032 |     'USD',
0033 |     'EUR',
0034 |     'GBP',
0035 |     'UGX',
0036 |     'KES',
0037 |     'TZS'
0038 |   ];
0039 |
0040 |   @override
0041 |   void initState() {
0042 |     super.initState();
0043 |     _load();
0044 |   }
0045 |
0046 |   ExtractedField? _bestField(ClaimDetails value, String name) {
0047 |     final matches = value.documents
0048 |         .expand((document) => document.fields)
0049 |         .where((field) => field.fieldName == name)
0050 |         .toList()
0051 |       ..sort((left, right) => right.confidence.compareTo(left.confidence));
0052 |     return matches.isEmpty ? null : matches.first;
0053 |   }
0054 |
0055 |   Future<void> _load() async {
0056 |     if (!mounted) return;
0057 |     setState(() {
0058 |       loading = true;
0059 |       error = null;
0060 |     });
0061 |     try {
0062 |       final api = workspaceApi(context);
0063 |       final service = context.read<ClaimsProvider>().service;
0064 |       final settings = await api.get<Map<String, dynamic>>('/settings');
0065 |       allowedCurrencies =
0066 |           List<String>.from(settings.data!['allowed_currencies'] as List);
0067 |       final value = await service.details(
0068 |         widget.reference,
0069 |       );
0070 |       if (!mounted) return;
0071 |       final patientField = _bestField(value, 'patient_name');
0072 |       final providerField = _bestField(value, 'provider_name');
0073 |       patient.text = patientField?.normalizedValue ?? value.patientName;
0074 |       provider.text = providerField?.normalizedValue ?? value.providerName;
0075 |       patientConfidence = patientField?.confidence;
0076 |       providerConfidence = providerField?.confidence;
0077 |       confirmations.clear();
0078 |       for (final document in value.documents) {
0079 |         final amount = document.confirmedAmount ?? document.extractedAmount;
0080 |         final currency = document.confirmedCurrency ??
0081 |             document.extractedCurrency ??
0082 |             value.currency;
0083 |         confirmations.add(
0084 |           DocumentConfirmation(
0085 |             document: document,
0086 |             include: allowedCurrencies.contains(currency) &&
0087 |                 document.duplicateOf == null &&
0088 |                 (document.includeInTotal || amount != null),
0089 |             amount: amount,
0090 |             currency: allowedCurrencies.contains(currency)
0091 |                 ? currency
0092 |                 : allowedCurrencies.first,
0093 |           ),
0094 |         );
0095 |         amountControllers[document.id]?.dispose();
0096 |         amountControllers[document.id] = TextEditingController(
0097 |           text: amount?.toStringAsFixed(2) ?? '',
0098 |         );
0099 |         for (final field in document.fields.where(
0100 |           (item) => !{
0101 |             'patient_name',
0102 |             'provider_name',
0103 |             'claimed_amount',
0104 |             'invoice_total',
0105 |           }.contains(item.fieldName),
0106 |         )) {
0107 |           fieldControllers[field.id]?.dispose();
0108 |           fieldControllers[field.id] = TextEditingController(
0109 |             text: field.normalizedValue,
0110 |           );
0111 |         }
0112 |       }
0113 |       setState(() => claim = value);
0114 |     } catch (exception) {
0115 |       if (mounted) setState(() => error = readableApiError(exception));
0116 |     } finally {
0117 |       if (mounted) setState(() => loading = false);
0118 |     }
0119 |   }
0120 |
0121 |   @override
0122 |   void dispose() {
0123 |     patient.dispose();
0124 |     provider.dispose();
0125 |     for (final controller in amountControllers.values) {
0126 |       controller.dispose();
0127 |     }
0128 |     for (final controller in fieldControllers.values) {
0129 |       controller.dispose();
0130 |     }
0131 |     super.dispose();
0132 |   }
0133 |
0134 |   String? _required(String? value) =>
0135 |       value == null || value.trim().length < 2 ? 'Confirm this value.' : null;
0136 |
0137 |   void _review() {
0138 |     if (!formKey.currentState!.validate()) return;
0139 |     for (final confirmation in confirmations) {
0140 |       confirmation.amount = double.tryParse(
0141 |         amountControllers[confirmation.document.id]!.text.trim(),
0142 |       );
0143 |       if (confirmation.include &&
0144 |           (confirmation.amount == null || confirmation.amount! <= 0)) {
0145 |         setState(() => error = 'Every included document needs a valid amount.');
0146 |         return;
0147 |       }
0148 |     }
0149 |     if (!confirmations.any((item) => item.include)) {
0150 |       setState(() => error = 'Include at least one payable document.');
0151 |       return;
0152 |     }
0153 |     final currencies = confirmations
0154 |         .where((item) => item.include)
0155 |         .map((item) => item.currency)
0156 |         .toSet();
0157 |     if (currencies.length != 1) {
0158 |       setState(() => error = 'Included documents must use the same currency.');
0159 |       return;
0160 |     }
0161 |     final fieldLabels = {
0162 |       for (final field in claim!.documents.expand(
0163 |         (document) => document.fields,
0164 |       ))
0165 |         field.id: field.fieldName.replaceAll('_', ' '),
0166 |     };
0167 |     final corrections = fieldControllers.entries
0168 |         .map(
0169 |           (entry) => FieldCorrection(
0170 |             id: entry.key,
0171 |             label: fieldLabels[entry.key] ?? 'extracted field',
0172 |             value: entry.value.text.trim(),
0173 |           ),
0174 |         )
0175 |         .where((field) => field.value.isNotEmpty)
0176 |         .toList();
0177 |     Navigator.push(
0178 |       context,
0179 |       MaterialPageRoute(
0180 |         builder: (_) => ClaimReviewScreen(
0181 |           reference: widget.reference,
0182 |           patientName: patient.text.trim(),
0183 |           providerName: provider.text.trim(),
0184 |           documents: confirmations,
0185 |           fields: corrections,
0186 |         ),
0187 |       ),
0188 |     );
0189 |   }
0190 |
0191 |   @override
0192 |   Widget build(BuildContext context) => Scaffold(
0193 |         appBar: AppBar(title: const Text('Confirm extracted information')),
0194 |         body: loading
0195 |             ? const Center(child: CircularProgressIndicator())
0196 |             : claim == null
0197 |                 ? Center(
0198 |                     child: Padding(
0199 |                       padding: const EdgeInsets.all(24),
0200 |                       child: Column(mainAxisSize: MainAxisSize.min, children: [
0201 |                         Text(error ?? 'The claim could not be loaded.'),
0202 |                         const SizedBox(height: 16),
0203 |                         FilledButton.icon(
0204 |                             onPressed: _load,
0205 |                             icon: const Icon(Icons.refresh),
0206 |                             label: const Text('Retry loading claim')),
0207 |                       ]),
0208 |                     ),
0209 |                   )
0210 |                 : Form(
0211 |                     key: formKey,
0212 |                     child: ListView(
0213 |                       padding: EdgeInsets.fromLTRB(16, 16, 16,
0214 |                           16 + MediaQuery.paddingOf(context).bottom),
0215 |                       children: [
0216 |                         Card(
0217 |                           color:
0218 |                               Theme.of(context).colorScheme.tertiaryContainer,
0219 |                           child: const Padding(
0220 |                             padding: EdgeInsets.all(16),
0221 |                             child: Row(
0222 |                               crossAxisAlignment: CrossAxisAlignment.start,
0223 |                               children: [
0224 |                                 Icon(Icons.fact_check_outlined),
0225 |                                 SizedBox(width: 12),
0226 |                                 Expanded(
0227 |                                   child: Text(
0228 |                                     'OCR values are proposals, not final decisions. Compare them with the source documents and correct anything that is wrong.',
0229 |                                   ),
0230 |                                 ),
0231 |                               ],
0232 |                             ),
0233 |                           ),
0234 |                         ),
0235 |                         const SizedBox(height: 16),
0236 |                         _ConfidenceField(
0237 |                           controller: patient,
0238 |                           label: 'Patient name',
0239 |                           confidence: patientConfidence,
0240 |                           validator: _required,
0241 |                         ),
0242 |                         const SizedBox(height: 12),
0243 |                         _ConfidenceField(
0244 |                           controller: provider,
0245 |                           label: 'Provider name',
0246 |                           confidence: providerConfidence,
0247 |                           validator: _required,
0248 |                         ),
0249 |                         const SizedBox(height: 24),
0250 |                         Text(
0251 |                           'Document amounts',
0252 |                           style: Theme.of(
0253 |                             context,
0254 |                           )
0255 |                               .textTheme
0256 |                               .titleLarge
0257 |                               ?.copyWith(fontWeight: FontWeight.w800),
0258 |                         ),
0259 |                         const SizedBox(height: 4),
0260 |                         const Text(
0261 |                           'Include payable evidence only. Medical certificates and duplicate copies should normally be excluded.',
0262 |                         ),
0263 |                         const SizedBox(height: 12),
0264 |                         ...confirmations.map(
0265 |                           (item) => _DocumentEditor(
0266 |                             reference: widget.reference,
0267 |                             allowedCurrencies: allowedCurrencies,
0268 |                             item: item,
0269 |                             controller: amountControllers[item.document.id]!,
0270 |                             fieldControllers: fieldControllers,
0271 |                             onChanged: () => setState(() {}),
0272 |                           ),
0273 |                         ),
0274 |                         if (error != null)
0275 |                           Padding(
0276 |                             padding: const EdgeInsets.only(top: 8),
0277 |                             child: Text(
0278 |                               error!,
0279 |                               style: TextStyle(
0280 |                                 color: Theme.of(context).colorScheme.error,
0281 |                               ),
0282 |                             ),
0283 |                           ),
0284 |                         const SizedBox(height: 16),
0285 |                         FilledButton.icon(
0286 |                           onPressed: _review,
0287 |                           icon: const Icon(Icons.arrow_forward),
0288 |                           label: const Padding(
0289 |                             padding: EdgeInsets.symmetric(vertical: 14),
0290 |                             child: Text('Review claim total'),
0291 |                           ),
0292 |                         ),
0293 |                       ],
0294 |                     ),
0295 |                   ),
0296 |       );
0297 | }
0298 |
0299 | class _ConfidenceField extends StatelessWidget {
0300 |   const _ConfidenceField({
0301 |     required this.controller,
0302 |     required this.label,
0303 |     required this.confidence,
0304 |     required this.validator,
0305 |   });
0306 |   final TextEditingController controller;
0307 |   final String label;
0308 |   final double? confidence;
0309 |   final FormFieldValidator<String> validator;
0310 |   @override
0311 |   Widget build(BuildContext context) => TextFormField(
0312 |         controller: controller,
0313 |         validator: validator,
0314 |         decoration: InputDecoration(
0315 |           labelText: label,
0316 |           helperText: confidence == null
0317 |               ? 'Not found by OCR - enter manually'
0318 |               : 'OCR confidence ${(confidence! * 100).round()}%',
0319 |         ),
0320 |       );
0321 | }
0322 |
0323 | class _DocumentEditor extends StatelessWidget {
0324 |   const _DocumentEditor({
0325 |     required this.item,
0326 |     required this.controller,
0327 |     required this.fieldControllers,
0328 |     required this.onChanged,
0329 |     required this.reference,
0330 |     required this.allowedCurrencies,
0331 |   });
0332 |   final DocumentConfirmation item;
0333 |   final String reference;
0334 |   final List<String> allowedCurrencies;
0335 |   final TextEditingController controller;
0336 |   final Map<String, TextEditingController> fieldControllers;
0337 |   final VoidCallback onChanged;
0338 |   @override
0339 |   Widget build(BuildContext context) {
0340 |     final document = item.document;
0341 |     return Card(
0342 |       margin: const EdgeInsets.only(bottom: 12),
0343 |       child: Padding(
0344 |         padding: const EdgeInsets.all(14),
0345 |         child: Column(
0346 |           crossAxisAlignment: CrossAxisAlignment.start,
0347 |           children: [
0348 |             Row(
0349 |               children: [
0350 |                 Expanded(
0351 |                   child: Text(
0352 |                     document.originalName,
0353 |                     maxLines: 2,
0354 |                     overflow: TextOverflow.ellipsis,
0355 |                     style: const TextStyle(fontWeight: FontWeight.w700),
0356 |                   ),
0357 |                 ),
0358 |                 Switch(
0359 |                   value: item.include,
0360 |                   onChanged: document.duplicateOf == null
0361 |                       ? (value) {
0362 |                           item.include = value;
0363 |                           onChanged();
0364 |                         }
0365 |                       : null,
0366 |                 ),
0367 |               ],
0368 |             ),
0369 |             Text(document.documentType.replaceAll('_', ' ')),
0370 |             TextButton.icon(
0371 |                 onPressed: () => Navigator.push(
0372 |                     context,
0373 |                     MaterialPageRoute(
0374 |                         builder: (_) => DocumentPreviewScreen(
0375 |                             reference: reference,
0376 |                             documentId: document.id,
0377 |                             name: document.originalName))),
0378 |                 icon: const Icon(Icons.document_scanner_outlined),
0379 |                 label: const Text('Compare source document')),
0380 |             if (document.duplicateOf != null)
0381 |               const Text(
0382 |                 'Duplicate detected - excluded from total.',
0383 |                 style: TextStyle(color: Colors.orange),
0384 |               ),
0385 |             if (document.extractionNotes != null)
0386 |               Text(
0387 |                 document.extractionNotes!,
0388 |                 style: TextStyle(color: Theme.of(context).colorScheme.error),
0389 |               ),
0390 |             const SizedBox(height: 10),
0391 |             if (document.extractedAmount != null) ...[
0392 |               Text(
0393 |                   'OCR amount: ${document.extractedCurrency ?? item.currency} ${document.extractedAmount!.toStringAsFixed(2)}'),
0394 |               TextButton.icon(
0395 |                   onPressed: item.include
0396 |                       ? () {
0397 |                           item.amountReported = true;
0398 |                           onChanged();
0399 |                         }
0400 |                       : null,
0401 |                   icon: const Icon(Icons.flag_outlined),
0402 |                   label: Text(item.amountReported
0403 |                       ? 'Correction will be checked by a claims officer'
0404 |                       : 'Report incorrect amount')),
0405 |             ],
0406 |             Column(
0407 |               children: [
0408 |                 SizedBox(
0409 |                   width: double.infinity,
0410 |                   child: TextFormField(
0411 |                     controller: controller,
0412 |                     enabled: item.include,
0413 |                     readOnly: document.extractedAmount != null &&
0414 |                         !item.amountReported,
0415 |                     keyboardType: const TextInputType.numberWithOptions(
0416 |                       decimal: true,
0417 |                     ),
0418 |                     decoration: InputDecoration(
0419 |                       labelText: 'Proposed amount',
0420 |                       helperText: document.amountConfidence == null
0421 |                           ? 'Enter a proposal for the claims officer to check'
0422 |                           : 'Confidence ${(document.amountConfidence! * 100).round()}%',
0423 |                     ),
0424 |                   ),
0425 |                 ),
0426 |                 const SizedBox(height: 14),
0427 |                 SizedBox(
0428 |                   width: double.infinity,
0429 |                   child: DropdownButtonFormField<String>(
0430 |                     initialValue: item.currency,
0431 |                     decoration: const InputDecoration(labelText: 'Currency'),
0432 |                     items: allowedCurrencies
0433 |                         .map(
0434 |                           (currency) => DropdownMenuItem(
0435 |                             value: currency,
0436 |                             child: Text(currency),
0437 |                           ),
0438 |                         )
0439 |                         .toList(),
0440 |                     onChanged: item.include
0441 |                         ? (value) {
0442 |                             if (value != null) {
0443 |                               item.currency = value;
0444 |                               onChanged();
0445 |                             }
0446 |                           }
0447 |                         : null,
0448 |                   ),
0449 |                 ),
0450 |               ],
0451 |             ),
0452 |             if (document.fields
0453 |                 .where(
0454 |                   (field) => !{
0455 |                     'patient_name',
0456 |                     'provider_name',
0457 |                     'claimed_amount',
0458 |                     'invoice_total',
0459 |                   }.contains(field.fieldName),
0460 |                 )
0461 |                 .isNotEmpty) ...[
0462 |               const Divider(height: 24),
0463 |               ...document.fields
0464 |                   .where(
0465 |                     (field) => !{
0466 |                       'patient_name',
0467 |                       'provider_name',
0468 |                       'claimed_amount',
0469 |                       'invoice_total',
0470 |                     }.contains(field.fieldName),
0471 |                   )
0472 |                   .map(
0473 |                     (field) => Padding(
0474 |                       padding: const EdgeInsets.only(bottom: 10),
0475 |                       child: TextFormField(
0476 |                         controller: fieldControllers[field.id],
0477 |                         decoration: InputDecoration(
0478 |                           labelText: field.fieldName.replaceAll('_', ' '),
0479 |                           helperText: field.extractionMethod ==
0480 |                                   'human_corrected'
0481 |                               ? 'Human corrected'
0482 |                               : 'OCR confidence ${(field.confidence * 100).round()}%',
0483 |                         ),
0484 |                       ),
0485 |                     ),
0486 |                   ),
0487 |             ],
0488 |           ],
0489 |         ),
0490 |       ),
0491 |     );
0492 |   }
0493 | }
```

## mobile/claimlens_mobile/lib/screens/help_screen.dart

120 lines. SHA-256: `f27d113421db6b7af224dc095106542b31a299e7190d0ffcb74e934733bbfe7a`.

Symbols: `HelpScreen`: L8

```dart
0001 | import 'package:flutter/material.dart';
0002 | import 'package:provider/provider.dart';
0003 | import '../providers/auth_provider.dart';
0004 | import '../services/workspace_service.dart';
0005 | import '../widgets/workspace_form.dart';
0006 | import 'workspace_screens.dart';
0007 |
0008 | class HelpScreen extends StatelessWidget {
0009 |   const HelpScreen({super.key});
0010 |   @override
0011 |   Widget build(BuildContext context) => WorkspaceData(
0012 |       title: 'Help & requirements',
0013 |       path: '/settings',
0014 |       render: (context, raw, reload) {
0015 |         final data = Map<String, dynamic>.from(raw as Map);
0016 |         return [
0017 |           Text('Before you submit',
0018 |               style: Theme.of(context).textTheme.headlineSmall),
0019 |           const SizedBox(height: 12),
0020 |           const Text(
0021 |               'Add clear, complete documents. Check the patient, provider and payable amounts against the source before submitting. OCR can make mistakes.'),
0022 |           const SizedBox(height: 20),
0023 |           ...List<String>.from(data['required_documents'] as List).map(
0024 |               (label) => Card(
0025 |                   child: ListTile(
0026 |                       leading: const Icon(Icons.checklist),
0027 |                       title: Text(label)))),
0028 |           const SizedBox(height: 16),
0029 |           const Text(
0030 |               'Supported files: PDF, Word (.docx), JPEG and PNG. Up to 10 documents, each under 10 MB. Avoid duplicate receipts and password-protected PDFs.'),
0031 |           const SizedBox(height: 20),
0032 |           if (data['require_member_number'] == true)
0033 |             const Text('Your member number is required.'),
0034 |           if (data['require_policy_number'] == true)
0035 |             const Text('Your policy number is required.'),
0036 |           Text(
0037 |               'Accepted currencies: ${(data['allowed_currencies'] as List).join(', ')}'),
0038 |           const SizedBox(height: 24),
0039 |           Text('Your information',
0040 |               style: Theme.of(context).textTheme.titleLarge),
0041 |           const SizedBox(height: 10),
0042 |           Text(data['privacy_notice'] as String),
0043 |           if ((data['support_email'] ?? '') != '')
0044 |             Padding(
0045 |                 padding: const EdgeInsets.symmetric(vertical: 20),
0046 |                 child: SelectableText('Support: ${data['support_email']}')),
0047 |           if (context.read<AuthProvider>().user!.isAdmin)
0048 |             Padding(
0049 |                 padding: const EdgeInsets.only(top: 20),
0050 |                 child: FilledButton.icon(
0051 |                     icon: const Icon(Icons.settings_outlined),
0052 |                     label: const Text('Configure requirements'),
0053 |                     onPressed: () async {
0054 |                       final saved = await workspaceForm(context,
0055 |                           title: 'Claim requirements',
0056 |                           explanation:
0057 |                               'These are submission requirements. Coverage and approval decisions still require an authorized reviewer.',
0058 |                           fields: [
0059 |                             FormEntry('required_documents',
0060 |                                 'Document checklist (one per line)',
0061 |                                 value: (data['required_documents'] as List)
0062 |                                     .join('\n'),
0063 |                                 lines: 5),
0064 |                             FormEntry('allowed_currencies',
0065 |                                 'Accepted currencies (comma separated)',
0066 |                                 value: (data['allowed_currencies'] as List)
0067 |                                     .join(', ')),
0068 |                             FormEntry('require_member_number', 'Member number',
0069 |                                 value: '${data['require_member_number']}',
0070 |                                 options: const {
0071 |                                   'true': 'Required',
0072 |                                   'false': 'Optional'
0073 |                                 }),
0074 |                             FormEntry('require_policy_number', 'Policy number',
0075 |                                 value: '${data['require_policy_number']}',
0076 |                                 options: const {
0077 |                                   'true': 'Required',
0078 |                                   'false': 'Optional'
0079 |                                 }),
0080 |                             FormEntry(
0081 |                                 'maximum_appeals', 'Maximum appeals per claim',
0082 |                                 value: '${data['maximum_appeals']}',
0083 |                                 options: const {
0084 |                                   '0': 'No appeals',
0085 |                                   '1': 'One appeal',
0086 |                                   '2': 'Two appeals',
0087 |                                   '3': 'Three appeals'
0088 |                                 }),
0089 |                             FormEntry('support_email', 'Support email',
0090 |                                 value: data['support_email'] as String,
0091 |                                 required: false),
0092 |                             FormEntry('privacy_notice', 'Privacy notice',
0093 |                                 value: data['privacy_notice'] as String,
0094 |                                 lines: 6)
0095 |                           ], submit: (values) async {
0096 |                         await workspaceApi(context)
0097 |                             .put<dynamic>('/settings', data: {
0098 |                           ...values,
0099 |                           'required_documents': values['required_documents']!
0100 |                               .split('\n')
0101 |                               .map((v) => v.trim())
0102 |                               .where((v) => v.isNotEmpty)
0103 |                               .toList(),
0104 |                           'allowed_currencies': values['allowed_currencies']!
0105 |                               .split(',')
0106 |                               .map((v) => v.trim())
0107 |                               .toList(),
0108 |                           'require_member_number':
0109 |                               values['require_member_number'] == 'true',
0110 |                           'require_policy_number':
0111 |                               values['require_policy_number'] == 'true',
0112 |                           'maximum_appeals':
0113 |                               int.parse(values['maximum_appeals']!)
0114 |                         });
0115 |                       });
0116 |                       if (saved == true) await reload();
0117 |                     })),
0118 |         ];
0119 |       });
0120 | }
```

## mobile/claimlens_mobile/lib/screens/history_screen.dart

175 lines. SHA-256: `2c475787458c5505822adf6ef8a663b06eadbaf4d37c60f21f0e47bc236f0962`.

Symbols: `HistoryScreen`: L10; `_HistoryScreenState`: L18

```dart
0001 | import 'dart:async';
0002 | import 'package:flutter/material.dart';
0003 | import 'package:provider/provider.dart';
0004 | import '../models/claim.dart';
0005 | import '../providers/auth_provider.dart';
0006 | import '../services/api_client.dart';
0007 | import '../services/workspace_service.dart';
0008 | import '../widgets/claim_card.dart';
0009 |
0010 | class HistoryScreen extends StatefulWidget {
0011 |   const HistoryScreen({super.key, this.reviewOnly = false, this.initialStatus});
0012 |   final bool reviewOnly;
0013 |   final String? initialStatus;
0014 |   @override
0015 |   State<HistoryScreen> createState() => _HistoryScreenState();
0016 | }
0017 |
0018 | class _HistoryScreenState extends State<HistoryScreen> {
0019 |   final search = TextEditingController();
0020 |   late String? status = widget.initialStatus;
0021 |   String scope = 'all';
0022 |   Timer? debounce;
0023 |   List<ClaimSummary> claims = [];
0024 |   bool busy = true;
0025 |   String? error;
0026 |   int generation = 0;
0027 |   @override
0028 |   void initState() {
0029 |     super.initState();
0030 |     _load();
0031 |   }
0032 |
0033 |   Future<void> _load() async {
0034 |     final current = ++generation;
0035 |     setState(() {
0036 |       busy = true;
0037 |       error = null;
0038 |     });
0039 |     try {
0040 |       final result = await workspaceApi(context)
0041 |           .get<List<dynamic>>('/claims', queryParameters: {
0042 |         'search': search.text,
0043 |         if (status != null) 'status': status,
0044 |         'scope': scope,
0045 |         'view': widget.reviewOnly ? 'review' : 'all',
0046 |         'limit': 200
0047 |       });
0048 |       if (mounted && current == generation) {
0049 |         setState(() => claims = result.data!
0050 |             .map((r) =>
0051 |                 ClaimSummary.fromJson(Map<String, dynamic>.from(r as Map)))
0052 |             .toList());
0053 |       }
0054 |     } catch (exception) {
0055 |       if (mounted && current == generation) {
0056 |         setState(() => error = readableApiError(exception));
0057 |       }
0058 |     } finally {
0059 |       if (mounted && current == generation) setState(() => busy = false);
0060 |     }
0061 |   }
0062 |
0063 |   @override
0064 |   void dispose() {
0065 |     debounce?.cancel();
0066 |     search.dispose();
0067 |     super.dispose();
0068 |   }
0069 |
0070 |   @override
0071 |   Widget build(BuildContext context) {
0072 |     final client = context.watch<AuthProvider>().user!.isClient;
0073 |     return Scaffold(
0074 |         appBar: AppBar(
0075 |             title: Text(widget.reviewOnly
0076 |                 ? 'Review queue'
0077 |                 : client
0078 |                     ? 'My claims'
0079 |                     : 'Claims queue'),
0080 |             actions: [
0081 |               IconButton(
0082 |                   tooltip: 'Refresh claims',
0083 |                   onPressed: busy ? null : _load,
0084 |                   icon: const Icon(Icons.refresh))
0085 |             ]),
0086 |         body: Column(children: [
0087 |           Padding(
0088 |               padding: const EdgeInsets.all(16),
0089 |               child: Column(children: [
0090 |                 TextField(
0091 |                     controller: search,
0092 |                     decoration: const InputDecoration(
0093 |                         labelText: 'Search claims',
0094 |                         hintText: 'Reference, patient or provider',
0095 |                         prefixIcon: Icon(Icons.search)),
0096 |                     onChanged: (_) {
0097 |                       debounce?.cancel();
0098 |                       debounce =
0099 |                           Timer(const Duration(milliseconds: 350), _load);
0100 |                     }),
0101 |                 const SizedBox(height: 12),
0102 |                 DropdownButtonFormField<String>(
0103 |                     initialValue: status ?? '',
0104 |                     isExpanded: true,
0105 |                     decoration:
0106 |                         const InputDecoration(labelText: 'Claim status'),
0107 |                     items: [
0108 |                       const DropdownMenuItem(
0109 |                           value: '', child: Text('All statuses')),
0110 |                       ...claimStatuses.map((v) => DropdownMenuItem(
0111 |                           value: v, child: Text(friendlyLabel(v))))
0112 |                     ],
0113 |                     onChanged: (v) {
0114 |                       setState(() => status = v == '' ? null : v);
0115 |                       _load();
0116 |                     }),
0117 |                 if (!client) ...[
0118 |                   const SizedBox(height: 12),
0119 |                   DropdownButtonFormField<String>(
0120 |                       initialValue: scope,
0121 |                       isExpanded: true,
0122 |                       decoration:
0123 |                           const InputDecoration(labelText: 'Assignment'),
0124 |                       items: const [
0125 |                         DropdownMenuItem(
0126 |                             value: 'all', child: Text('All accessible claims')),
0127 |                         DropdownMenuItem(
0128 |                             value: 'mine', child: Text('Assigned to me')),
0129 |                         DropdownMenuItem(
0130 |                             value: 'unassigned',
0131 |                             child: Text('Awaiting assignment'))
0132 |                       ],
0133 |                       onChanged: (v) {
0134 |                         setState(() => scope = v!);
0135 |                         _load();
0136 |                       })
0137 |                 ],
0138 |               ])),
0139 |           if (busy) const LinearProgressIndicator(),
0140 |           Expanded(
0141 |               child: RefreshIndicator(
0142 |                   onRefresh: _load,
0143 |                   child: ListView(
0144 |                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
0145 |                       physics: const AlwaysScrollableScrollPhysics(),
0146 |                       children: [
0147 |                         if (error != null)
0148 |                           Card(
0149 |                               child: Padding(
0150 |                                   padding: const EdgeInsets.all(20),
0151 |                                   child: Column(children: [
0152 |                                     Text(error!),
0153 |                                     TextButton(
0154 |                                         onPressed: _load,
0155 |                                         child: const Text('Try again'))
0156 |                                   ]))),
0157 |                         if (!busy && error == null && claims.isEmpty)
0158 |                           const Card(
0159 |                               child: Padding(
0160 |                                   padding: EdgeInsets.all(24),
0161 |                                   child: Column(children: [
0162 |                                     Icon(Icons.folder_open, size: 48),
0163 |                                     SizedBox(height: 12),
0164 |                                     Text('No claims match your filters.')
0165 |                                   ]))),
0166 |                         ...claims.map((claim) => Padding(
0167 |                             padding: const EdgeInsets.only(bottom: 12),
0168 |                             child: ClaimCard(claim: claim))),
0169 |                         if (claims.length == 200)
0170 |                           const Text(
0171 |                               'Showing the latest 200 matches. Use search and filters to narrow the list.'),
0172 |                       ]))),
0173 |         ]));
0174 |   }
0175 | }
```

## mobile/claimlens_mobile/lib/screens/information_response_screen.dart

138 lines. SHA-256: `b2b7664b2bf8a483b799d82e5dd00918c6ed248acf69ed52fe352057ce2253d4`.

Symbols: `InformationResponseScreen`: L7; `_InformationResponseScreenState`: L17

```dart
0001 | import 'package:dio/dio.dart';
0002 | import 'package:file_picker/file_picker.dart';
0003 | import 'package:flutter/material.dart';
0004 | import '../services/api_client.dart';
0005 | import '../services/workspace_service.dart';
0006 |
0007 | class InformationResponseScreen extends StatefulWidget {
0008 |   const InformationResponseScreen(
0009 |       {super.key, required this.reference, required this.request});
0010 |   final String reference;
0011 |   final Map<String, dynamic> request;
0012 |   @override
0013 |   State<InformationResponseScreen> createState() =>
0014 |       _InformationResponseScreenState();
0015 | }
0016 |
0017 | class _InformationResponseScreenState extends State<InformationResponseScreen> {
0018 |   final response = TextEditingController();
0019 |   final List<PlatformFile> files = [];
0020 |   bool busy = false;
0021 |   String? error;
0022 |   @override
0023 |   void dispose() {
0024 |     response.dispose();
0025 |     super.dispose();
0026 |   }
0027 |
0028 |   Future<void> attach() async {
0029 |     try {
0030 |       final result = await FilePicker.platform.pickFiles(
0031 |           allowMultiple: true,
0032 |           type: FileType.custom,
0033 |           allowedExtensions: ['pdf', 'docx', 'png', 'jpg', 'jpeg'],
0034 |           withData: true);
0035 |       if (result != null && mounted) {
0036 |         setState(() {
0037 |           files.addAll(result.files);
0038 |         });
0039 |       }
0040 |     } catch (exception) {
0041 |       if (mounted) setState(() => error = readableApiError(exception));
0042 |     }
0043 |   }
0044 |
0045 |   Future<void> submit() async {
0046 |     final api = workspaceApi(context);
0047 |     if (response.text.trim().isEmpty && files.isEmpty) {
0048 |       setState(
0049 |           () => error = 'Enter your response or attach supporting documents.');
0050 |       return;
0051 |     }
0052 |     if (files.length > 10 || files.any((f) => f.size > 10 * 1024 * 1024)) {
0053 |       setState(() => error = 'Attach up to 10 documents, each under 10 MB.');
0054 |       return;
0055 |     }
0056 |     setState(() {
0057 |       busy = true;
0058 |       error = null;
0059 |     });
0060 |     try {
0061 |       final multipart = FormData.fromMap(
0062 |           {'response_text': response.text, 'background': true});
0063 |       for (final file in files) {
0064 |         final mime = switch (file.extension?.toLowerCase()) {
0065 |           'pdf' => 'application/pdf',
0066 |           'docx' =>
0067 |             'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
0068 |           'png' => 'image/png',
0069 |           _ => 'image/jpeg'
0070 |         };
0071 |         final part = file.bytes != null
0072 |             ? MultipartFile.fromBytes(file.bytes!,
0073 |                 filename: file.name, contentType: DioMediaType.parse(mime))
0074 |             : await MultipartFile.fromFile(file.path!,
0075 |                 filename: file.name, contentType: DioMediaType.parse(mime));
0076 |         multipart.files.add(MapEntry('files', part));
0077 |       }
0078 |       await api.post<dynamic>(
0079 |           '/claims/${widget.reference}/information/${widget.request['id']}/respond',
0080 |           data: multipart,
0081 |           options: Options(receiveTimeout: const Duration(minutes: 5)));
0082 |       if (mounted) Navigator.pop(context, true);
0083 |     } catch (exception) {
0084 |       if (mounted) {
0085 |         setState(() {
0086 |           busy = false;
0087 |           error = readableApiError(exception);
0088 |         });
0089 |       }
0090 |     }
0091 |   }
0092 |
0093 |   @override
0094 |   Widget build(BuildContext context) => Scaffold(
0095 |       appBar: AppBar(title: const Text('Provide information')),
0096 |       body: ListView(padding: const EdgeInsets.all(20), children: [
0097 |         Text(widget.request['reason'] as String,
0098 |             style: Theme.of(context).textTheme.titleLarge),
0099 |         const SizedBox(height: 12),
0100 |         Text(widget.request['questions'] as String),
0101 |         if ((widget.request['required_documents'] ?? '') != '')
0102 |           Padding(
0103 |               padding: const EdgeInsets.symmetric(vertical: 12),
0104 |               child: Text(
0105 |                   'Requested documents: ${widget.request['required_documents']}')),
0106 |         const SizedBox(height: 20),
0107 |         TextField(
0108 |             controller: response,
0109 |             enabled: !busy,
0110 |             maxLines: 6,
0111 |             maxLength: 4000,
0112 |             decoration: const InputDecoration(
0113 |                 labelText: 'Your response', alignLabelWithHint: true)),
0114 |         const SizedBox(height: 16),
0115 |         OutlinedButton.icon(
0116 |             onPressed: busy ? null : attach,
0117 |             icon: const Icon(Icons.attach_file),
0118 |             label: const Text('Attach supporting documents')),
0119 |         for (final file in files)
0120 |           ListTile(
0121 |               leading: const Icon(Icons.description_outlined),
0122 |               title: Text(file.name),
0123 |               subtitle: Text('${(file.size / 1024).round()} KB'),
0124 |               trailing: IconButton(
0125 |                   tooltip: 'Remove attachment',
0126 |                   onPressed:
0127 |                       busy ? null : () => setState(() => files.remove(file)),
0128 |                   icon: const Icon(Icons.close))),
0129 |         if (error != null)
0130 |           Text(error!,
0131 |               style: TextStyle(color: Theme.of(context).colorScheme.error)),
0132 |         const SizedBox(height: 20),
0133 |         FilledButton.icon(
0134 |             onPressed: busy ? null : submit,
0135 |             icon: const Icon(Icons.send_outlined),
0136 |             label: Text(busy ? 'Submitting & processing…' : 'Submit response')),
0137 |       ]));
0138 | }
```

## mobile/claimlens_mobile/lib/screens/login_screen.dart

180 lines. SHA-256: `386f890cbb137e310f939fa372c0a9bc9f0cdb8e763557096ae035f8e7c01a5c`.

Symbols: `LoginScreen`: L11; `_LoginScreenState`: L17

```dart
0001 | import 'package:flutter/material.dart';
0002 | import '../widgets/claimlens_logo.dart';
0003 | import 'package:flutter/foundation.dart';
0004 | import 'package:provider/provider.dart';
0005 |
0006 | import '../providers/auth_provider.dart';
0007 | import 'password_recovery_screen.dart';
0008 | import 'signup_screen.dart';
0009 | import '../widgets/workspace_form.dart';
0010 |
0011 | class LoginScreen extends StatefulWidget {
0012 |   const LoginScreen({super.key});
0013 |   @override
0014 |   State<LoginScreen> createState() => _LoginScreenState();
0015 | }
0016 |
0017 | class _LoginScreenState extends State<LoginScreen> {
0018 |   final email = TextEditingController();
0019 |   final password = TextEditingController();
0020 |   final formKey = GlobalKey<FormState>();
0021 |   bool hidden = true;
0022 |
0023 |   Future<void> openSignup() async {
0024 |     context.read<AuthProvider>().clearError();
0025 |     final registeredEmail = await Navigator.push<String>(
0026 |         context,
0027 |         MaterialPageRoute(
0028 |             builder: (_) => SignupScreen(initialEmail: email.text.trim())));
0029 |     if (!mounted || registeredEmail == null) return;
0030 |     email.text = registeredEmail;
0031 |     password.clear();
0032 |   }
0033 |
0034 |   @override
0035 |   void dispose() {
0036 |     email.dispose();
0037 |     password.dispose();
0038 |     super.dispose();
0039 |   }
0040 |
0041 |   @override
0042 |   Widget build(BuildContext context) {
0043 |     final auth = context.watch<AuthProvider>();
0044 |     return Scaffold(
0045 |       body: SafeArea(
0046 |         child: Center(
0047 |           child: SingleChildScrollView(
0048 |             padding: const EdgeInsets.all(24),
0049 |             child: ConstrainedBox(
0050 |               constraints: const BoxConstraints(maxWidth: 440),
0051 |               child: Form(
0052 |                 key: formKey,
0053 |                 child: Column(
0054 |                   crossAxisAlignment: CrossAxisAlignment.stretch,
0055 |                   children: [
0056 |                     const ClaimLensLogo(size: 72),
0057 |                     const SizedBox(height: 16),
0058 |                     Text(
0059 |                       'ClaimLens',
0060 |                       textAlign: TextAlign.center,
0061 |                       style: Theme.of(context)
0062 |                           .textTheme
0063 |                           .headlineMedium
0064 |                           ?.copyWith(fontWeight: FontWeight.w800),
0065 |                     ),
0066 |                     const SizedBox(height: 8),
0067 |                     Text(
0068 |                       'Clients and staff sign in here.',
0069 |                       textAlign: TextAlign.center,
0070 |                       style: Theme.of(context).textTheme.bodyLarge,
0071 |                     ),
0072 |                     const SizedBox(height: 32),
0073 |                     TextFormField(
0074 |                       controller: email,
0075 |                       keyboardType: TextInputType.emailAddress,
0076 |                       decoration: const InputDecoration(
0077 |                         labelText: 'Email',
0078 |                         prefixIcon: Icon(Icons.email_outlined),
0079 |                       ),
0080 |                       validator: (value) => value != null && value.contains('@')
0081 |                           ? null
0082 |                           : 'Enter your email.',
0083 |                     ),
0084 |                     const SizedBox(height: 16),
0085 |                     TextFormField(
0086 |                       controller: password,
0087 |                       obscureText: hidden,
0088 |                       decoration: InputDecoration(
0089 |                         labelText: 'Password',
0090 |                         prefixIcon: const Icon(Icons.lock_outline),
0091 |                         suffixIcon: IconButton(
0092 |                           onPressed: () => setState(() => hidden = !hidden),
0093 |                           icon: Icon(
0094 |                             hidden ? Icons.visibility : Icons.visibility_off,
0095 |                           ),
0096 |                         ),
0097 |                       ),
0098 |                       validator: (value) => value == null || value.isEmpty
0099 |                           ? 'Enter your password.'
0100 |                           : null,
0101 |                     ),
0102 |                     if (auth.error != null)
0103 |                       Padding(
0104 |                         padding: const EdgeInsets.only(top: 12),
0105 |                         child: Text(
0106 |                           auth.error!,
0107 |                           style: TextStyle(
0108 |                             color: Theme.of(context).colorScheme.error,
0109 |                           ),
0110 |                         ),
0111 |                       ),
0112 |                     const SizedBox(height: 20),
0113 |                     if (auth.client.hasSession)
0114 |                       TextButton.icon(
0115 |                           onPressed: auth.busy ? null : auth.initialise,
0116 |                           icon: const Icon(Icons.refresh),
0117 |                           label: const Text('Retry saved session')),
0118 |                     FilledButton.icon(
0119 |                       onPressed: auth.busy
0120 |                           ? null
0121 |                           : () {
0122 |                               if (formKey.currentState!.validate()) {
0123 |                                 auth.login(email.text, password.text);
0124 |                               }
0125 |                             },
0126 |                       icon: auth.busy
0127 |                           ? const SizedBox.square(
0128 |                               dimension: 18,
0129 |                               child: CircularProgressIndicator(strokeWidth: 2),
0130 |                             )
0131 |                           : const Icon(Icons.login),
0132 |                       label: const Padding(
0133 |                         padding: EdgeInsets.symmetric(vertical: 14),
0134 |                         child: Text('Sign in'),
0135 |                       ),
0136 |                     ),
0137 |                     const SizedBox(height: 16),
0138 |                     TextButton(
0139 |                       onPressed: auth.busy
0140 |                           ? null
0141 |                           : () => Navigator.push(
0142 |                                 context,
0143 |                                 MaterialPageRoute<void>(
0144 |                                   builder: (_) => PasswordRecoveryScreen(
0145 |                                     initialEmail: email.text.trim(),
0146 |                                   ),
0147 |                                 ),
0148 |                               ),
0149 |                       child: const Text('Forgot password?'),
0150 |                     ),
0151 |                     OutlinedButton(
0152 |                       onPressed: auth.busy ? null : openSignup,
0153 |                       child: const Text('New client? Sign up'),
0154 |                     ),
0155 |                     if (kDebugMode)
0156 |                       TextButton.icon(
0157 |                           onPressed: auth.busy
0158 |                               ? null
0159 |                               : () => workspaceForm(context,
0160 |                                   title: 'Development connection',
0161 |                                   explanation:
0162 |                                       'For USB debugging use http://127.0.0.1:8000. For a hotspot or Wi-Fi connection, enter the API computer’s local address. A hosted server must use HTTPS.',
0163 |                                   fields: [
0164 |                                     FormEntry('url', 'API server URL',
0165 |                                         value: auth.client.dio.options.baseUrl)
0166 |                                   ],
0167 |                                   button: 'Check & save connection',
0168 |                                   submit: (v) => auth.changeServer(v['url']!)),
0169 |                           icon: const Icon(Icons.settings_ethernet),
0170 |                           label: const Text('Development connection')),
0171 |                   ],
0172 |                 ),
0173 |               ),
0174 |             ),
0175 |           ),
0176 |         ),
0177 |       ),
0178 |     );
0179 |   }
0180 | }
```

## mobile/claimlens_mobile/lib/screens/new_claim_screen.dart

316 lines. SHA-256: `b39482702a282032dc1e9c193cb73df8d2d7c6c9cab0913543d90aef8dcb1bac`.

Symbols: `NewClaimScreen`: L15; `_NewClaimScreenState`: L21

```dart
0001 | import 'dart:math';
0002 | import 'package:file_picker/file_picker.dart';
0003 | import 'package:flutter/material.dart';
0004 | import 'package:image_picker/image_picker.dart';
0005 | import 'package:provider/provider.dart';
0006 |
0007 | import '../models/selected_document.dart';
0008 | import '../providers/claims_provider.dart';
0009 | import '../services/api_client.dart';
0010 | import 'processing_screen.dart';
0011 | import 'claim_details_screen.dart';
0012 | import 'help_screen.dart';
0013 | import '../services/workspace_service.dart';
0014 |
0015 | class NewClaimScreen extends StatefulWidget {
0016 |   const NewClaimScreen({super.key});
0017 |   @override
0018 |   State<NewClaimScreen> createState() => _NewClaimScreenState();
0019 | }
0020 |
0021 | class _NewClaimScreenState extends State<NewClaimScreen> {
0022 |   final documents = <SelectedDocument>[];
0023 |   final picker = ImagePicker();
0024 |   bool busy = false;
0025 |   String? error;
0026 |   final member = TextEditingController(),
0027 |       policy = TextEditingController(),
0028 |       description = TextEditingController();
0029 |   DateTime? treatmentDate;
0030 |   double? progress;
0031 |   String? draftReference;
0032 |   final requestKey =
0033 |       List.generate(32, (_) => Random.secure().nextInt(16).toRadixString(16))
0034 |           .join();
0035 |   @override
0036 |   void dispose() {
0037 |     member.dispose();
0038 |     policy.dispose();
0039 |     description.dispose();
0040 |     super.dispose();
0041 |   }
0042 |
0043 |   String _mime(String name) {
0044 |     final lower = name.toLowerCase();
0045 |     if (lower.endsWith('.pdf')) return 'application/pdf';
0046 |     if (lower.endsWith('.docx')) {
0047 |       return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
0048 |     }
0049 |     if (lower.endsWith('.png')) return 'image/png';
0050 |     return 'image/jpeg';
0051 |   }
0052 |
0053 |   Future<void> _pickFiles() async {
0054 |     final result = await FilePicker.platform.pickFiles(
0055 |       allowMultiple: true,
0056 |       withData: true,
0057 |       type: FileType.custom,
0058 |       allowedExtensions: ['pdf', 'docx', 'png', 'jpg', 'jpeg'],
0059 |     );
0060 |     if (result == null) return;
0061 |     setState(() {
0062 |       for (final file in result.files) {
0063 |         if (file.bytes != null) {
0064 |           documents.add(
0065 |             SelectedDocument(
0066 |               name: file.name,
0067 |               mimeType: _mime(file.name),
0068 |               bytes: file.bytes!,
0069 |             ),
0070 |           );
0071 |         }
0072 |       }
0073 |     });
0074 |   }
0075 |
0076 |   Future<void> _pickImages(ImageSource source) async {
0077 |     final List<XFile> images;
0078 |     if (source == ImageSource.gallery) {
0079 |       images = await picker.pickMultiImage(
0080 |           imageQuality: 90, maxWidth: 2500, maxHeight: 2500);
0081 |     } else {
0082 |       final image = await picker.pickImage(
0083 |           source: source, imageQuality: 90, maxWidth: 2500, maxHeight: 2500);
0084 |       images = image == null ? [] : [image];
0085 |     }
0086 |     final selected = <SelectedDocument>[];
0087 |     for (final image in images) {
0088 |       selected.add(
0089 |         SelectedDocument(
0090 |           name: image.name,
0091 |           mimeType: _mime(image.name),
0092 |           bytes: await image.readAsBytes(),
0093 |         ),
0094 |       );
0095 |     }
0096 |     setState(() => documents.addAll(selected));
0097 |   }
0098 |
0099 |   Future<void> _submit({bool extract = true}) async {
0100 |     if (documents.isEmpty) {
0101 |       setState(() => error = 'Add at least one claim document.');
0102 |       return;
0103 |     }
0104 |     if (documents.length > 10) {
0105 |       setState(() => error = 'A claim can contain up to 10 documents.');
0106 |       return;
0107 |     }
0108 |     final oversized = documents
0109 |         .where((document) => document.bytes.length > 10 * 1024 * 1024)
0110 |         .toList();
0111 |     if (oversized.isNotEmpty) {
0112 |       setState(() => error = '${oversized.first.name} is larger than 10 MB.');
0113 |       return;
0114 |     }
0115 |     setState(() {
0116 |       busy = true;
0117 |       error = null;
0118 |     });
0119 |     try {
0120 |       final service = context.read<ClaimsProvider>().service;
0121 |       final api = workspaceApi(context);
0122 |       if (draftReference == null) {
0123 |         final claim = await service.create(documents, requestKey: requestKey,
0124 |             onSendProgress: (sent, total) {
0125 |           if (mounted) {
0126 |             setState(() => progress = total > 0 ? sent / total : null);
0127 |           }
0128 |         });
0129 |         draftReference = claim.reference;
0130 |       }
0131 |       await api.put<dynamic>('/claims/$draftReference/information', data: {
0132 |         'member_number': member.text.trim(),
0133 |         'policy_number': policy.text.trim(),
0134 |         'description': description.text.trim(),
0135 |         'treatment_date': treatmentDate?.toIso8601String().substring(0, 10)
0136 |       });
0137 |       if (!mounted) return;
0138 |       Navigator.pushReplacement(
0139 |         context,
0140 |         MaterialPageRoute(
0141 |           builder: (_) => extract
0142 |               ? ProcessingScreen(reference: draftReference!)
0143 |               : ClaimDetailsScreen(reference: draftReference!),
0144 |         ),
0145 |       );
0146 |     } catch (exception) {
0147 |       if (mounted) setState(() => error = readableApiError(exception));
0148 |     } finally {
0149 |       if (mounted) setState(() => busy = false);
0150 |     }
0151 |   }
0152 |
0153 |   @override
0154 |   Widget build(BuildContext context) => Scaffold(
0155 |         appBar: AppBar(title: const Text('New claim')),
0156 |         body: ListView(
0157 |           padding: EdgeInsets.fromLTRB(
0158 |               16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
0159 |           children: [
0160 |             Text(
0161 |               'Upload every document for this claim',
0162 |               style: Theme.of(
0163 |                 context,
0164 |               ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
0165 |             ),
0166 |             const SizedBox(height: 8),
0167 |             const Text(
0168 |               'Add invoices, receipts, pharmacy documents, medical certificates, memos, claim forms, or other supporting evidence. OCR will propose values; you will confirm them before submission.',
0169 |             ),
0170 |             const SizedBox(height: 20),
0171 |             TextField(
0172 |                 controller: member,
0173 |                 decoration: const InputDecoration(
0174 |                     labelText: 'Member number (if applicable)')),
0175 |             const SizedBox(height: 14),
0176 |             TextField(
0177 |                 controller: policy,
0178 |                 decoration: const InputDecoration(
0179 |                     labelText: 'Policy number (if applicable)')),
0180 |             const SizedBox(height: 14),
0181 |             ListTile(
0182 |                 contentPadding: EdgeInsets.zero,
0183 |                 leading: const Icon(Icons.calendar_today_outlined),
0184 |                 title: const Text('Treatment date'),
0185 |                 subtitle: Text(treatmentDate == null
0186 |                     ? 'Choose a date'
0187 |                     : treatmentDate!.toIso8601String().substring(0, 10)),
0188 |                 trailing: const Icon(Icons.chevron_right),
0189 |                 onTap: busy
0190 |                     ? null
0191 |                     : () async {
0192 |                         final chosen = await showDatePicker(
0193 |                             context: context,
0194 |                             firstDate: DateTime(2000),
0195 |                             lastDate: DateTime.now(),
0196 |                             initialDate: treatmentDate ?? DateTime.now());
0197 |                         if (chosen != null && mounted) {
0198 |                           setState(() => treatmentDate = chosen);
0199 |                         }
0200 |                       }),
0201 |             const SizedBox(height: 14),
0202 |             TextField(
0203 |                 controller: description,
0204 |                 maxLines: 3,
0205 |                 maxLength: 2000,
0206 |                 decoration: const InputDecoration(
0207 |                     labelText: 'What is this claim for?',
0208 |                     alignLabelWithHint: true)),
0209 |             TextButton.icon(
0210 |                 onPressed: () => Navigator.push(context,
0211 |                     MaterialPageRoute(builder: (_) => const HelpScreen())),
0212 |                 icon: const Icon(Icons.checklist),
0213 |                 label: const Text('View document requirements')),
0214 |             const SizedBox(height: 20),
0215 |             Wrap(spacing: 8, runSpacing: 8, children: [
0216 |               OutlinedButton.icon(
0217 |                   onPressed:
0218 |                       busy ? null : () => _pickImages(ImageSource.camera),
0219 |                   icon: const Icon(Icons.camera_alt_outlined),
0220 |                   label: const Text('Camera')),
0221 |               OutlinedButton.icon(
0222 |                   onPressed:
0223 |                       busy ? null : () => _pickImages(ImageSource.gallery),
0224 |                   icon: const Icon(Icons.photo_library_outlined),
0225 |                   label: const Text('Gallery')),
0226 |             ]),
0227 |             const SizedBox(height: 8),
0228 |             OutlinedButton.icon(
0229 |               onPressed: busy ? null : _pickFiles,
0230 |               icon: const Icon(Icons.attach_file),
0231 |               label: const Padding(
0232 |                 padding: EdgeInsets.symmetric(vertical: 12),
0233 |                 child: Text('PDF, Word, or image files'),
0234 |               ),
0235 |             ),
0236 |             const SizedBox(height: 20),
0237 |             Text(
0238 |               '${documents.length} document${documents.length == 1 ? '' : 's'} selected',
0239 |               style: Theme.of(
0240 |                 context,
0241 |               ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
0242 |             ),
0243 |             const SizedBox(height: 8),
0244 |             if (documents.isEmpty)
0245 |               const Card(
0246 |                 child: Padding(
0247 |                   padding: EdgeInsets.all(20),
0248 |                   child: Text('No documents selected yet.'),
0249 |                 ),
0250 |               ),
0251 |             ...documents.asMap().entries.map(
0252 |                   (entry) => Card(
0253 |                     margin: const EdgeInsets.only(bottom: 8),
0254 |                     child: ListTile(
0255 |                       leading: const Icon(Icons.description_outlined),
0256 |                       title: Text(
0257 |                         entry.value.name,
0258 |                         maxLines: 2,
0259 |                         overflow: TextOverflow.ellipsis,
0260 |                       ),
0261 |                       subtitle: Text(
0262 |                         '${(entry.value.bytes.length / 1024).toStringAsFixed(0)} KB',
0263 |                       ),
0264 |                       trailing: IconButton(
0265 |                         onPressed: busy
0266 |                             ? null
0267 |                             : () =>
0268 |                                 setState(() => documents.removeAt(entry.key)),
0269 |                         icon: const Icon(Icons.close),
0270 |                       ),
0271 |                     ),
0272 |                   ),
0273 |                 ),
0274 |             if (error != null)
0275 |               Padding(
0276 |                 padding: const EdgeInsets.symmetric(vertical: 8),
0277 |                 child: Text(
0278 |                   error!,
0279 |                   style: TextStyle(color: Theme.of(context).colorScheme.error),
0280 |                 ),
0281 |               ),
0282 |             const SizedBox(height: 12),
0283 |             FilledButton.icon(
0284 |               onPressed: busy ? null : () => _submit(),
0285 |               icon: busy
0286 |                   ? const SizedBox.square(
0287 |                       dimension: 18,
0288 |                       child: CircularProgressIndicator(strokeWidth: 2),
0289 |                     )
0290 |                   : const Icon(Icons.cloud_upload_outlined),
0291 |               label: const Padding(
0292 |                 padding: EdgeInsets.symmetric(vertical: 14),
0293 |                 child: Text('Upload and extract'),
0294 |               ),
0295 |             ),
0296 |             if (busy)
0297 |               Padding(
0298 |                   padding: const EdgeInsets.symmetric(vertical: 12),
0299 |                   child: Column(children: [
0300 |                     LinearProgressIndicator(value: progress),
0301 |                     const SizedBox(height: 8),
0302 |                     Text(progress == null
0303 |                         ? 'Preparing upload…'
0304 |                         : progress! < 1
0305 |                             ? 'Uploading ${(progress! * 100).round()}%'
0306 |                             : 'Saving your draft…')
0307 |                   ])),
0308 |             const SizedBox(height: 12),
0309 |             OutlinedButton.icon(
0310 |                 onPressed: busy ? null : () => _submit(extract: false),
0311 |                 icon: const Icon(Icons.save_outlined),
0312 |                 label: const Text('Save draft for later')),
0313 |           ],
0314 |         ),
0315 |       );
0316 | }
```

## mobile/claimlens_mobile/lib/screens/password_recovery_screen.dart

118 lines. SHA-256: `f1284cb339d0be79e51433ebc95a248e89710257643688bdc9c827e1f21a7a9b`.

Symbols: `PasswordRecoveryScreen`: L7; `_PasswordRecoveryScreenState`: L14

```dart
0001 | import 'package:flutter/material.dart';
0002 | import 'package:provider/provider.dart';
0003 |
0004 | import '../providers/auth_provider.dart';
0005 | import '../services/api_client.dart';
0006 |
0007 | class PasswordRecoveryScreen extends StatefulWidget {
0008 |   const PasswordRecoveryScreen({super.key, this.initialEmail = ''});
0009 |   final String initialEmail;
0010 |   @override
0011 |   State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
0012 | }
0013 |
0014 | class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
0015 |   final form = GlobalKey<FormState>();
0016 |   late final email = TextEditingController(text: widget.initialEmail);
0017 |   bool busy = false;
0018 |   String? error, message;
0019 |
0020 |   @override
0021 |   void dispose() {
0022 |     email.dispose();
0023 |     super.dispose();
0024 |   }
0025 |
0026 |   Future<void> submit() async {
0027 |     if (busy || !form.currentState!.validate()) return;
0028 |     setState(() {
0029 |       busy = true;
0030 |       error = null;
0031 |     });
0032 |     try {
0033 |       final response = await context
0034 |           .read<AuthProvider>()
0035 |           .client
0036 |           .dio
0037 |           .post<Map<String, dynamic>>(
0038 |         '/auth/forgot-password',
0039 |         data: {'email': email.text.trim()},
0040 |       );
0041 |       if (mounted) {
0042 |         setState(() => message = response.data?['message'] as String? ??
0043 |             'Check your email for a password reset link.');
0044 |       }
0045 |     } catch (exception) {
0046 |       if (mounted) setState(() => error = readableApiError(exception));
0047 |     } finally {
0048 |       if (mounted) setState(() => busy = false);
0049 |     }
0050 |   }
0051 |
0052 |   @override
0053 |   Widget build(BuildContext context) => Scaffold(
0054 |         appBar: AppBar(title: const Text('Reset password')),
0055 |         body: SafeArea(
0056 |             child: Center(
0057 |                 child: SingleChildScrollView(
0058 |           padding: const EdgeInsets.all(24),
0059 |           child: ConstrainedBox(
0060 |               constraints: const BoxConstraints(maxWidth: 440),
0061 |               child: Form(
0062 |                 key: form,
0063 |                 child: Column(
0064 |                     crossAxisAlignment: CrossAxisAlignment.stretch,
0065 |                     children: [
0066 |                       Icon(Icons.lock_reset,
0067 |                           size: 48,
0068 |                           color: Theme.of(context).colorScheme.primary),
0069 |                       const SizedBox(height: 16),
0070 |                       Text('Recover your account',
0071 |                           textAlign: TextAlign.center,
0072 |                           style: Theme.of(context).textTheme.headlineSmall),
0073 |                       const SizedBox(height: 12),
0074 |                       const Text(
0075 |                           'We will email you a secure link to choose a new password.',
0076 |                           textAlign: TextAlign.center),
0077 |                       const SizedBox(height: 24),
0078 |                       if (message == null) ...[
0079 |                         TextFormField(
0080 |                             controller: email,
0081 |                             enabled: !busy,
0082 |                             keyboardType: TextInputType.emailAddress,
0083 |                             autocorrect: false,
0084 |                             decoration:
0085 |                                 const InputDecoration(labelText: 'Email'),
0086 |                             validator: (v) =>
0087 |                                 RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
0088 |                                         .hasMatch(v?.trim() ?? '')
0089 |                                     ? null
0090 |                                     : 'Enter a valid email.'),
0091 |                         const SizedBox(height: 24),
0092 |                         FilledButton(
0093 |                             onPressed: busy ? null : submit,
0094 |                             child: Padding(
0095 |                                 padding: const EdgeInsets.all(12),
0096 |                                 child: busy
0097 |                                     ? const SizedBox.square(
0098 |                                         dimension: 20,
0099 |                                         child: CircularProgressIndicator(
0100 |                                             strokeWidth: 2))
0101 |                                     : const Text('Send reset link'))),
0102 |                       ] else
0103 |                         Text(message!),
0104 |                       if (error != null)
0105 |                         Padding(
0106 |                             padding: const EdgeInsets.only(top: 16),
0107 |                             child: Text(error!,
0108 |                                 style: TextStyle(
0109 |                                     color:
0110 |                                         Theme.of(context).colorScheme.error))),
0111 |                       TextButton(
0112 |                           onPressed: busy ? null : () => Navigator.pop(context),
0113 |                           child: const Text('Back to sign in')),
0114 |                     ]),
0115 |               )),
0116 |         ))),
0117 |       );
0118 | }
```

## mobile/claimlens_mobile/lib/screens/processing_screen.dart

133 lines. SHA-256: `ca17d45cb618af324623e391eef3510fa824943afcebdb280614fd3aa030c8b4`.

Symbols: `ProcessingScreen`: L9; `_ProcessingScreenState`: L16

```dart
0001 | import 'package:flutter/material.dart';
0002 | import 'package:provider/provider.dart';
0003 |
0004 | import '../providers/claims_provider.dart';
0005 | import '../services/api_client.dart';
0006 | import 'extracted_info_screen.dart';
0007 | import 'claim_details_screen.dart';
0008 |
0009 | class ProcessingScreen extends StatefulWidget {
0010 |   const ProcessingScreen({super.key, required this.reference});
0011 |   final String reference;
0012 |   @override
0013 |   State<ProcessingScreen> createState() => _ProcessingScreenState();
0014 | }
0015 |
0016 | class _ProcessingScreenState extends State<ProcessingScreen> {
0017 |   String? error;
0018 |   bool running = true;
0019 |
0020 |   @override
0021 |   void initState() {
0022 |     super.initState();
0023 |     WidgetsBinding.instance.addPostFrameCallback((_) => _process());
0024 |   }
0025 |
0026 |   Future<void> _process() async {
0027 |     setState(() {
0028 |       running = true;
0029 |       error = null;
0030 |     });
0031 |     try {
0032 |       final service = context.read<ClaimsProvider>().service;
0033 |       final current = await service.details(widget.reference);
0034 |       if (current.status != 'PROCESSING') {
0035 |         await service.process(widget.reference);
0036 |       }
0037 |       var details = await service.details(widget.reference);
0038 |       final deadline = DateTime.now().add(const Duration(minutes: 10));
0039 |       while (mounted &&
0040 |           details.status == 'PROCESSING' &&
0041 |           DateTime.now().isBefore(deadline)) {
0042 |         await Future<void>.delayed(const Duration(seconds: 3));
0043 |         if (!mounted) return;
0044 |         details = await service.details(widget.reference);
0045 |       }
0046 |       if (details.status == 'PROCESSING') {
0047 |         throw Exception(
0048 |             'Processing is continuing. You can return to Claims and check its progress.');
0049 |       }
0050 |       if (details.status == 'PROCESSING_FAILED') {
0051 |         throw Exception(
0052 |             'Processing did not finish. Retry, or enter the document information manually.');
0053 |       }
0054 |       if (!mounted) return;
0055 |       Navigator.pushReplacement(
0056 |         context,
0057 |         MaterialPageRoute(
0058 |           builder: (_) => details.status == 'UPLOADED'
0059 |               ? ExtractedInfoScreen(reference: widget.reference)
0060 |               : ClaimDetailsScreen(reference: widget.reference),
0061 |         ),
0062 |       );
0063 |     } catch (exception) {
0064 |       if (mounted) setState(() => error = readableApiError(exception));
0065 |     } finally {
0066 |       if (mounted) setState(() => running = false);
0067 |     }
0068 |   }
0069 |
0070 |   @override
0071 |   Widget build(BuildContext context) => Scaffold(
0072 |         appBar: AppBar(title: Text(widget.reference)),
0073 |         body: Center(
0074 |           child: Padding(
0075 |             padding: const EdgeInsets.all(28),
0076 |             child: Column(
0077 |               mainAxisSize: MainAxisSize.min,
0078 |               children: [
0079 |                 if (running) ...[
0080 |                   const CircularProgressIndicator(),
0081 |                   const SizedBox(height: 24),
0082 |                   Text(
0083 |                     'Reading your documents',
0084 |                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
0085 |                           fontWeight: FontWeight.w800,
0086 |                         ),
0087 |                   ),
0088 |                   const SizedBox(height: 8),
0089 |                   const Text(
0090 |                     'Text extraction and OCR are identifying patient, provider, dates, and payable totals. Large scanned PDFs can take longer.',
0091 |                     textAlign: TextAlign.center,
0092 |                   ),
0093 |                 ] else ...[
0094 |                   Icon(
0095 |                     Icons.error_outline,
0096 |                     size: 52,
0097 |                     color: Theme.of(context).colorScheme.error,
0098 |                   ),
0099 |                   const SizedBox(height: 16),
0100 |                   Text(
0101 |                     'Processing needs attention',
0102 |                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
0103 |                           fontWeight: FontWeight.w800,
0104 |                         ),
0105 |                   ),
0106 |                   const SizedBox(height: 8),
0107 |                   Text(
0108 |                     error ?? 'Processing did not finish.',
0109 |                     textAlign: TextAlign.center,
0110 |                   ),
0111 |                   const SizedBox(height: 20),
0112 |                   FilledButton.icon(
0113 |                     onPressed: _process,
0114 |                     icon: const Icon(Icons.refresh),
0115 |                     label: const Text('Retry'),
0116 |                   ),
0117 |                   TextButton(
0118 |                     onPressed: () => Navigator.pushReplacement(
0119 |                       context,
0120 |                       MaterialPageRoute(
0121 |                         builder: (_) =>
0122 |                             ExtractedInfoScreen(reference: widget.reference),
0123 |                       ),
0124 |                     ),
0125 |                     child: const Text('Enter information manually'),
0126 |                   ),
0127 |                 ],
0128 |               ],
0129 |             ),
0130 |           ),
0131 |         ),
0132 |       );
0133 | }
```

## mobile/claimlens_mobile/lib/screens/profile_screen.dart

195 lines. SHA-256: `943cbe6c91b5c061fc6d73d529fecfa45c525e2b4d89820178e235678a4619c5`.

Symbols: `ProfileScreen`: L8

```dart
0001 | import 'package:flutter/material.dart';
0002 | import 'package:provider/provider.dart';
0003 | import '../providers/auth_provider.dart';
0004 | import '../services/workspace_service.dart';
0005 | import '../widgets/workspace_form.dart';
0006 | import '../services/api_client.dart';
0007 |
0008 | class ProfileScreen extends StatelessWidget {
0009 |   const ProfileScreen({super.key});
0010 |   @override
0011 |   Widget build(BuildContext context) {
0012 |     final auth = context.watch<AuthProvider>();
0013 |     final user = auth.user!;
0014 |     Future<void> edit() async {
0015 |       await workspaceForm(context,
0016 |           title: 'Account settings',
0017 |           fields: [
0018 |             FormEntry('display_name', 'Full name', value: user.displayName),
0019 |             FormEntry('phone', 'Phone number',
0020 |                 value: user.phone, required: false),
0021 |             FormEntry('theme', 'Appearance',
0022 |                 value: user.theme,
0023 |                 options: labelOptions(['system', 'light', 'dark'])),
0024 |             FormEntry('notifications_enabled', 'Claim notifications',
0025 |                 value: user.notificationsEnabled.toString(),
0026 |                 options: const {
0027 |                   'true': 'Allow updates and unread badge',
0028 |                   'false': 'Mute push alerts and unread badge'
0029 |                 })
0030 |           ],
0031 |           submit: (v) => auth.updateProfile({
0032 |                 ...v,
0033 |                 'notifications_enabled': v['notifications_enabled'] == 'true'
0034 |               }));
0035 |     }
0036 |
0037 |     return Scaffold(
0038 |         appBar: AppBar(title: const Text('Account & settings')),
0039 |         body: ListView(padding: const EdgeInsets.all(20), children: [
0040 |           if (user.isClient && !user.emailVerified)
0041 |             Card(
0042 |                 color: Theme.of(context).colorScheme.secondaryContainer,
0043 |                 child: Padding(
0044 |                     padding: const EdgeInsets.all(18),
0045 |                     child: Column(
0046 |                         crossAxisAlignment: CrossAxisAlignment.start,
0047 |                         children: [
0048 |                           Text('Verify your email',
0049 |                               style: Theme.of(context).textTheme.titleMedium),
0050 |                           const SizedBox(height: 8),
0051 |                           const Text(
0052 |                               'Open the link in your verification email, then refresh your account. Public signup accounts must verify before submitting claims.'),
0053 |                           Wrap(spacing: 8, children: [
0054 |                             TextButton(
0055 |                                 onPressed: () async {
0056 |                                   try {
0057 |                                     final response = await workspaceApi(context)
0058 |                                         .post<Map<String, dynamic>>(
0059 |                                             '/auth/verification-email');
0060 |                                     if (context.mounted) {
0061 |                                       ScaffoldMessenger.of(context)
0062 |                                           .showSnackBar(SnackBar(
0063 |                                               content: Text(
0064 |                                                   response.data!['message']
0065 |                                                       as String)));
0066 |                                     }
0067 |                                   } catch (e) {
0068 |                                     if (context.mounted) {
0069 |                                       ScaffoldMessenger.of(context)
0070 |                                           .showSnackBar(SnackBar(
0071 |                                               content:
0072 |                                                   Text(readableApiError(e))));
0073 |                                     }
0074 |                                   }
0075 |                                 },
0076 |                                 child: const Text('Send verification email')),
0077 |                             TextButton(
0078 |                                 onPressed: () async {
0079 |                                   try {
0080 |                                     await auth.reloadProfile(
0081 |                                         refreshToken: true);
0082 |                                   } catch (e) {
0083 |                                     if (context.mounted) {
0084 |                                       ScaffoldMessenger.of(context)
0085 |                                           .showSnackBar(SnackBar(
0086 |                                               content:
0087 |                                                   Text(readableApiError(e))));
0088 |                                     }
0089 |                                   }
0090 |                                 },
0091 |                                 child: const Text('I’ve verified my email'))
0092 |                           ])
0093 |                         ]))),
0094 |           Card(
0095 |               child: Padding(
0096 |                   padding: const EdgeInsets.all(24),
0097 |                   child: Column(children: [
0098 |                     CircleAvatar(
0099 |                         radius: 36,
0100 |                         child: Text(
0101 |                             user.displayName.isEmpty
0102 |                                 ? '?'
0103 |                                 : user.displayName[0].toUpperCase(),
0104 |                             style: const TextStyle(fontSize: 28))),
0105 |                     const SizedBox(height: 16),
0106 |                     Text(user.displayName,
0107 |                         style: Theme.of(context).textTheme.headlineSmall,
0108 |                         textAlign: TextAlign.center),
0109 |                     const SizedBox(height: 4),
0110 |                     Text(user.email ?? '', textAlign: TextAlign.center),
0111 |                     Chip(label: Text(friendlyLabel(user.role))),
0112 |                     if (user.phone.isNotEmpty) Text(user.phone)
0113 |                   ]))),
0114 |           const SizedBox(height: 20),
0115 |           Card(
0116 |               child: Column(children: [
0117 |             ListTile(
0118 |                 leading: const Icon(Icons.manage_accounts_outlined),
0119 |                 title: const Text('Personal information'),
0120 |                 subtitle: const Text('Update your name and phone number'),
0121 |                 trailing: const Icon(Icons.chevron_right),
0122 |                 onTap: edit),
0123 |             const Divider(height: 1),
0124 |             ListTile(
0125 |                 leading: const Icon(Icons.palette_outlined),
0126 |                 title: const Text('Appearance & notifications'),
0127 |                 subtitle: Text('${friendlyLabel(user.theme)} theme'),
0128 |                 trailing: const Icon(Icons.chevron_right),
0129 |                 onTap: edit),
0130 |             const Divider(height: 1),
0131 |             ListTile(
0132 |                 leading: const Icon(Icons.lock_outline),
0133 |                 title: const Text('Change password'),
0134 |                 subtitle: const Text('Keep your account secure'),
0135 |                 trailing: const Icon(Icons.chevron_right),
0136 |                 onTap: () => workspaceForm(context,
0137 |                         title: 'Change password',
0138 |                         fields: const [
0139 |                           FormEntry('current', 'Current password',
0140 |                               secret: true),
0141 |                           FormEntry('password',
0142 |                               'New password (at least 12 characters)',
0143 |                               secret: true),
0144 |                           FormEntry('confirm', 'Confirm new password',
0145 |                               secret: true)
0146 |                         ], submit: (v) async {
0147 |                       if (v['password'] != v['confirm']) {
0148 |                         throw Exception('The new passwords do not match.');
0149 |                       }
0150 |                       if (v['password']!.length < 12) {
0151 |                         throw Exception('Use at least 12 characters.');
0152 |                       }
0153 |                       await auth.changePassword(v['current']!, v['password']!);
0154 |                     }))
0155 |           ])),
0156 |           const SizedBox(height: 24),
0157 |           OutlinedButton.icon(
0158 |               onPressed: auth.lock,
0159 |               icon: const Icon(Icons.lock_outline),
0160 |               label: const Text('Lock this session')),
0161 |           const SizedBox(height: 12),
0162 |           OutlinedButton.icon(
0163 |               icon: const Icon(Icons.logout),
0164 |               label: const Text('Sign out'),
0165 |               onPressed: auth.busy
0166 |                   ? null
0167 |                   : () async {
0168 |                       final confirmed = await showDialog<bool>(
0169 |                           context: context,
0170 |                           builder: (c) => AlertDialog(
0171 |                                   title: const Text('Sign out?'),
0172 |                                   content: const Text(
0173 |                                       'You can sign in again to access your claims.'),
0174 |                                   actions: [
0175 |                                     TextButton(
0176 |                                         onPressed: () =>
0177 |                                             Navigator.pop(c, false),
0178 |                                         child: const Text('Cancel')),
0179 |                                     FilledButton(
0180 |                                         onPressed: () => Navigator.pop(c, true),
0181 |                                         child: const Text('Sign out'))
0182 |                                   ]));
0183 |                       if (confirmed == true && context.mounted) {
0184 |                         Navigator.of(context)
0185 |                             .popUntil((route) => route.isFirst);
0186 |                         await auth.logout();
0187 |                       }
0188 |                     }),
0189 |           const SizedBox(height: 20),
0190 |           Text('ClaimLens\nMedical claims, clearly managed.',
0191 |               textAlign: TextAlign.center,
0192 |               style: Theme.of(context).textTheme.bodySmall),
0193 |         ]));
0194 |   }
0195 | }
```

## mobile/claimlens_mobile/lib/screens/required_password_screen.dart

114 lines. SHA-256: `80c28fa901a0912117b929aa75185045063f1e692b27136971b836af392a16ab`.

Symbols: `RequiredPasswordScreen`: L6; `_RequiredPasswordScreenState`: L12

```dart
0001 | import 'package:flutter/material.dart';
0002 | import 'package:provider/provider.dart';
0003 | import '../providers/auth_provider.dart';
0004 | import '../services/api_client.dart';
0005 |
0006 | class RequiredPasswordScreen extends StatefulWidget {
0007 |   const RequiredPasswordScreen({super.key});
0008 |   @override
0009 |   State<RequiredPasswordScreen> createState() => _RequiredPasswordScreenState();
0010 | }
0011 |
0012 | class _RequiredPasswordScreenState extends State<RequiredPasswordScreen> {
0013 |   final key = GlobalKey<FormState>();
0014 |   final current = TextEditingController(),
0015 |       password = TextEditingController(),
0016 |       confirm = TextEditingController();
0017 |   bool busy = false;
0018 |   String? error;
0019 |   @override
0020 |   void dispose() {
0021 |     current.dispose();
0022 |     password.dispose();
0023 |     confirm.dispose();
0024 |     super.dispose();
0025 |   }
0026 |
0027 |   Future<void> save() async {
0028 |     if (!key.currentState!.validate()) return;
0029 |     setState(() {
0030 |       busy = true;
0031 |       error = null;
0032 |     });
0033 |     try {
0034 |       await context
0035 |           .read<AuthProvider>()
0036 |           .changePassword(current.text, password.text);
0037 |     } catch (e) {
0038 |       if (mounted) setState(() => error = readableApiError(e));
0039 |     } finally {
0040 |       if (mounted) setState(() => busy = false);
0041 |     }
0042 |   }
0043 |
0044 |   @override
0045 |   Widget build(BuildContext context) => Scaffold(
0046 |       appBar: AppBar(title: const Text('Secure your account')),
0047 |       body: SafeArea(
0048 |           child: Center(
0049 |               child: SingleChildScrollView(
0050 |                   padding: const EdgeInsets.all(24),
0051 |                   child: ConstrainedBox(
0052 |                       constraints: const BoxConstraints(maxWidth: 440),
0053 |                       child: Form(
0054 |                           key: key,
0055 |                           child: Column(
0056 |                               crossAxisAlignment: CrossAxisAlignment.stretch,
0057 |                               children: [
0058 |                                 const Icon(Icons.lock_reset, size: 56),
0059 |                                 const SizedBox(height: 20),
0060 |                                 Text('Choose your own password',
0061 |                                     style: Theme.of(context)
0062 |                                         .textTheme
0063 |                                         .headlineSmall),
0064 |                                 const SizedBox(height: 12),
0065 |                                 const Text(
0066 |                                     'Your administrator set a temporary password. Change it before continuing to your workspace.'),
0067 |                                 const SizedBox(height: 24),
0068 |                                 TextFormField(
0069 |                                     controller: current,
0070 |                                     obscureText: true,
0071 |                                     decoration: const InputDecoration(
0072 |                                         labelText: 'Temporary password'),
0073 |                                     validator: (v) => (v ?? '').isEmpty
0074 |                                         ? 'Enter your temporary password'
0075 |                                         : null),
0076 |                                 const SizedBox(height: 16),
0077 |                                 TextFormField(
0078 |                                     controller: password,
0079 |                                     obscureText: true,
0080 |                                     decoration: const InputDecoration(
0081 |                                         labelText: 'New password'),
0082 |                                     validator: (v) => (v ?? '').length < 12
0083 |                                         ? 'Use at least 12 characters'
0084 |                                         : v == current.text
0085 |                                             ? 'Choose a different password'
0086 |                                             : null),
0087 |                                 const SizedBox(height: 16),
0088 |                                 TextFormField(
0089 |                                     controller: confirm,
0090 |                                     obscureText: true,
0091 |                                     decoration: const InputDecoration(
0092 |                                         labelText: 'Confirm new password'),
0093 |                                     validator: (v) => v != password.text
0094 |                                         ? 'Passwords do not match'
0095 |                                         : null),
0096 |                                 const SizedBox(height: 20),
0097 |                                 if (error != null)
0098 |                                   Text(error!,
0099 |                                       style: TextStyle(
0100 |                                           color: Theme.of(context)
0101 |                                               .colorScheme
0102 |                                               .error)),
0103 |                                 FilledButton(
0104 |                                     onPressed: busy ? null : save,
0105 |                                     child: Text(busy
0106 |                                         ? 'Saving…'
0107 |                                         : 'Save password & continue')),
0108 |                                 TextButton(
0109 |                                     onPressed: busy
0110 |                                         ? null
0111 |                                         : context.read<AuthProvider>().logout,
0112 |                                     child: const Text('Sign out'))
0113 |                               ])))))));
0114 | }
```

## mobile/claimlens_mobile/lib/screens/signup_screen.dart

214 lines. SHA-256: `65479c4e1649489702ffbae39d7e59d24c8e3e709a436e41fbbae4c7626bba0d`.

Symbols: `SignupScreen`: L7; `_SignupScreenState`: L15

```dart
0001 | import 'package:flutter/material.dart';
0002 | import 'package:provider/provider.dart';
0003 |
0004 | import '../providers/auth_provider.dart';
0005 | import '../services/api_client.dart';
0006 |
0007 | class SignupScreen extends StatefulWidget {
0008 |   const SignupScreen({super.key, this.initialEmail = ''});
0009 |   final String initialEmail;
0010 |
0011 |   @override
0012 |   State<SignupScreen> createState() => _SignupScreenState();
0013 | }
0014 |
0015 | class _SignupScreenState extends State<SignupScreen> {
0016 |   final form = GlobalKey<FormState>();
0017 |   final name = TextEditingController();
0018 |   late final email = TextEditingController(text: widget.initialEmail);
0019 |   final password = TextEditingController();
0020 |   final confirm = TextEditingController();
0021 |   bool busy = false, hidden = true;
0022 |   String? error, success;
0023 |
0024 |   @override
0025 |   void dispose() {
0026 |     for (final controller in [name, email, password, confirm]) {
0027 |       controller.dispose();
0028 |     }
0029 |     super.dispose();
0030 |   }
0031 |
0032 |   void backToLogin() =>
0033 |       Navigator.pop(context, success == null ? null : email.text.trim());
0034 |
0035 |   Future<void> submit() async {
0036 |     if (busy || !form.currentState!.validate()) return;
0037 |     FocusScope.of(context).unfocus();
0038 |     setState(() {
0039 |       busy = true;
0040 |       error = null;
0041 |     });
0042 |     try {
0043 |       final response = await context
0044 |           .read<AuthProvider>()
0045 |           .client
0046 |           .dio
0047 |           .post<Map<String, dynamic>>(
0048 |         '/auth/signup',
0049 |         data: {
0050 |           'display_name': name.text.trim(),
0051 |           'email': email.text.trim(),
0052 |           'password': password.text,
0053 |         },
0054 |       );
0055 |       if (!mounted) return;
0056 |       setState(() {
0057 |         success = response.data?['message'] as String? ??
0058 |             'Account created. You can now sign in.';
0059 |         password.clear();
0060 |         confirm.clear();
0061 |       });
0062 |     } catch (exception) {
0063 |       if (mounted) setState(() => error = readableApiError(exception));
0064 |     } finally {
0065 |       if (mounted) setState(() => busy = false);
0066 |     }
0067 |   }
0068 |
0069 |   @override
0070 |   Widget build(BuildContext context) => Scaffold(
0071 |         appBar: AppBar(
0072 |             title: const Text('Sign up'),
0073 |             leading: IconButton(
0074 |               tooltip: 'Back to sign in',
0075 |               onPressed: busy ? null : backToLogin,
0076 |               icon: const Icon(Icons.arrow_back),
0077 |             )),
0078 |         body: SafeArea(
0079 |             child: Center(
0080 |                 child: SingleChildScrollView(
0081 |           padding: const EdgeInsets.all(24),
0082 |           child: ConstrainedBox(
0083 |               constraints: const BoxConstraints(maxWidth: 440),
0084 |               child: Form(
0085 |                 key: form,
0086 |                 child: Column(
0087 |                     crossAxisAlignment: CrossAxisAlignment.stretch,
0088 |                     children: [
0089 |                       Icon(
0090 |                           success == null
0091 |                               ? Icons.person_add_alt_1
0092 |                               : Icons.check_circle_outline,
0093 |                           size: 54,
0094 |                           color: Theme.of(context).colorScheme.primary),
0095 |                       const SizedBox(height: 16),
0096 |                       Text(
0097 |                           success == null
0098 |                               ? 'Join claimelens'
0099 |                               : 'Your account is ready',
0100 |                           textAlign: TextAlign.center,
0101 |                           style: Theme.of(context)
0102 |                               .textTheme
0103 |                               .headlineSmall
0104 |                               ?.copyWith(fontWeight: FontWeight.w800)),
0105 |                       const SizedBox(height: 8),
0106 |                       if (success == null) ...[
0107 |                         const Text(
0108 |                             'Create a client account to submit and track your medical claims.',
0109 |                             textAlign: TextAlign.center),
0110 |                         const SizedBox(height: 24),
0111 |                         TextFormField(
0112 |                             controller: name,
0113 |                             enabled: !busy,
0114 |                             textCapitalization: TextCapitalization.words,
0115 |                             autofillHints: const [AutofillHints.name],
0116 |                             decoration: const InputDecoration(
0117 |                                 labelText: 'Full name',
0118 |                                 prefixIcon: Icon(Icons.person_outline)),
0119 |                             validator: (v) => (v?.trim().length ?? 0) < 2 ||
0120 |                                     (v?.trim().length ?? 0) > 120
0121 |                                 ? 'Enter a name between 2 and 120 characters.'
0122 |                                 : null),
0123 |                         const SizedBox(height: 16),
0124 |                         TextFormField(
0125 |                             controller: email,
0126 |                             enabled: !busy,
0127 |                             keyboardType: TextInputType.emailAddress,
0128 |                             autofillHints: const [AutofillHints.email],
0129 |                             autocorrect: false,
0130 |                             decoration: const InputDecoration(
0131 |                                 labelText: 'Email',
0132 |                                 prefixIcon: Icon(Icons.email_outlined)),
0133 |                             validator: (v) =>
0134 |                                 RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
0135 |                                         .hasMatch(v?.trim() ?? '')
0136 |                                     ? null
0137 |                                     : 'Enter a valid email.'),
0138 |                         const SizedBox(height: 16),
0139 |                         TextFormField(
0140 |                             controller: password,
0141 |                             enabled: !busy,
0142 |                             obscureText: hidden,
0143 |                             autofillHints: const [AutofillHints.newPassword],
0144 |                             autocorrect: false,
0145 |                             enableSuggestions: false,
0146 |                             decoration: InputDecoration(
0147 |                                 labelText: 'Password',
0148 |                                 helperText: 'Use 12 to 128 characters.',
0149 |                                 prefixIcon: const Icon(Icons.lock_outline),
0150 |                                 suffixIcon: IconButton(
0151 |                                     tooltip: hidden
0152 |                                         ? 'Show password'
0153 |                                         : 'Hide password',
0154 |                                     onPressed: () =>
0155 |                                         setState(() => hidden = !hidden),
0156 |                                     icon: Icon(hidden
0157 |                                         ? Icons.visibility
0158 |                                         : Icons.visibility_off))),
0159 |                             validator: (v) =>
0160 |                                 (v?.length ?? 0) < 8 || (v?.length ?? 0) > 128
0161 |                                     ? 'Use 12 to 128 characters.'
0162 |                                     : null),
0163 |                         const SizedBox(height: 16),
0164 |                         TextFormField(
0165 |                             controller: confirm,
0166 |                             enabled: !busy,
0167 |                             obscureText: true,
0168 |                             autocorrect: false,
0169 |                             enableSuggestions: false,
0170 |                             decoration: const InputDecoration(
0171 |                                 labelText: 'Confirm password',
0172 |                                 prefixIcon: Icon(Icons.lock_outline)),
0173 |                             validator: (v) => v != password.text
0174 |                                 ? 'Passwords do not match.'
0175 |                                 : null),
0176 |                         const SizedBox(height: 20),
0177 |                         if (error != null)
0178 |                           Padding(
0179 |                               padding: const EdgeInsets.only(bottom: 12),
0180 |                               child: Text(error!,
0181 |                                   style: TextStyle(
0182 |                                       color: Theme.of(context)
0183 |                                           .colorScheme
0184 |                                           .error))),
0185 |                         FilledButton(
0186 |                             onPressed: busy ? null : submit,
0187 |                             child: Padding(
0188 |                                 padding:
0189 |                                     const EdgeInsets.symmetric(vertical: 14),
0190 |                                 child: busy
0191 |                                     ? const SizedBox.square(
0192 |                                         dimension: 20,
0193 |                                         child: CircularProgressIndicator(
0194 |                                             strokeWidth: 2))
0195 |                                     : const Text('Create account'))),
0196 |                         const SizedBox(height: 16),
0197 |                         const Text(
0198 |                             'Administrator, claims officer, and supervisor accounts are provided by your organisation. Staff use the same sign-in page.',
0199 |                             textAlign: TextAlign.center),
0200 |                       ] else ...[
0201 |                         const SizedBox(height: 16),
0202 |                         Text(success!, textAlign: TextAlign.center),
0203 |                         const SizedBox(height: 16),
0204 |                       ],
0205 |                       TextButton(
0206 |                           onPressed: busy ? null : backToLogin,
0207 |                           child: Text(success == null
0208 |                               ? 'Already have an account? Sign in'
0209 |                               : 'Back to sign in')),
0210 |                     ]),
0211 |               )),
0212 |         ))),
0213 |       );
0214 | }
```

## mobile/claimlens_mobile/lib/screens/splash_screen.dart

32 lines. SHA-256: `1f644a10365b8ec8736c8472da1877baa8013bd364784c0317dc435db715b231`.

Symbols: `SplashScreen`: L4

```dart
0001 | import 'package:flutter/material.dart';
0002 | import '../widgets/claimlens_logo.dart';
0003 |
0004 | class SplashScreen extends StatelessWidget {
0005 |   const SplashScreen({super.key});
0006 |
0007 |   @override
0008 |   Widget build(BuildContext context) => Scaffold(
0009 |         body: Center(
0010 |           child: Column(
0011 |             mainAxisSize: MainAxisSize.min,
0012 |             children: [
0013 |               const ClaimLensLogo(size: 72),
0014 |               const SizedBox(height: 18),
0015 |               Text(
0016 |                 'ClaimLens',
0017 |                 style: Theme.of(
0018 |                   context,
0019 |                 )
0020 |                     .textTheme
0021 |                     .headlineMedium
0022 |                     ?.copyWith(fontWeight: FontWeight.w900),
0023 |               ),
0024 |               const SizedBox(height: 18),
0025 |               const CircularProgressIndicator(),
0026 |               const SizedBox(height: 12),
0027 |               const Text('Restoring your secure session...'),
0028 |             ],
0029 |           ),
0030 |         ),
0031 |       );
0032 | }
```

## mobile/claimlens_mobile/lib/screens/staff_review_screen.dart

217 lines. SHA-256: `3c566b0ee490b2fe102d782b8d7e48bcccb64ceaa1f0c85ccd4f9294b5aa1c94`.

Symbols: `StaffReviewScreen`: L7; `_StaffReviewScreenState`: L14

```dart
0001 | import 'package:flutter/material.dart';
0002 | import 'document_preview_screen.dart';
0003 | import '../models/claim.dart';
0004 | import '../services/api_client.dart';
0005 | import '../services/workspace_service.dart';
0006 |
0007 | class StaffReviewScreen extends StatefulWidget {
0008 |   const StaffReviewScreen({super.key, required this.claim});
0009 |   final ClaimDetails claim;
0010 |   @override
0011 |   State<StaffReviewScreen> createState() => _StaffReviewScreenState();
0012 | }
0013 |
0014 | class _StaffReviewScreenState extends State<StaffReviewScreen> {
0015 |   final key = GlobalKey<FormState>();
0016 |   late final patient = TextEditingController(text: widget.claim.patientName);
0017 |   late final provider = TextEditingController(text: widget.claim.providerName);
0018 |   late final amounts = {
0019 |     for (final d in widget.claim.documents)
0020 |       d.id: TextEditingController(
0021 |           text: (d.confirmedAmount ?? d.extractedAmount)?.toStringAsFixed(2) ??
0022 |               '')
0023 |   };
0024 |   late final currencies = {
0025 |     for (final d in widget.claim.documents)
0026 |       d.id: TextEditingController(
0027 |           text: d.confirmedCurrency ??
0028 |               d.extractedCurrency ??
0029 |               widget.claim.currency)
0030 |   };
0031 |   late final included = {
0032 |     for (final d in widget.claim.documents)
0033 |       d.id: d.includeInTotal && d.duplicateOf == null
0034 |   };
0035 |   late final fields = {
0036 |     for (final d in widget.claim.documents)
0037 |       for (final f in d.fields)
0038 |         f.id: TextEditingController(text: f.normalizedValue)
0039 |   };
0040 |   bool busy = false;
0041 |   String? error;
0042 |   @override
0043 |   void dispose() {
0044 |     patient.dispose();
0045 |     provider.dispose();
0046 |     for (final c in [
0047 |       ...amounts.values,
0048 |       ...currencies.values,
0049 |       ...fields.values
0050 |     ]) {
0051 |       c.dispose();
0052 |     }
0053 |     super.dispose();
0054 |   }
0055 |
0056 |   Future<void> save() async {
0057 |     if (!key.currentState!.validate()) return;
0058 |     setState(() {
0059 |       busy = true;
0060 |       error = null;
0061 |     });
0062 |     try {
0063 |       await workspaceApi(context).post<dynamic>(
0064 |           '/claims/${widget.claim.reference}/actions/correct',
0065 |           data: {
0066 |             'patient_name': patient.text,
0067 |             'provider_name': provider.text,
0068 |             'documents': [
0069 |               for (final d in widget.claim.documents)
0070 |                 {
0071 |                   'id': d.id,
0072 |                   'include': included[d.id],
0073 |                   'amount': included[d.id] == true ? amounts[d.id]!.text : null,
0074 |                   'currency': currencies[d.id]!.text.toUpperCase()
0075 |                 }
0076 |             ],
0077 |             'fields': [
0078 |               for (final d in widget.claim.documents)
0079 |                 for (final f in d.fields)
0080 |                   if (fields[f.id]!.text != f.normalizedValue)
0081 |                     {'id': f.id, 'value': fields[f.id]!.text}
0082 |             ]
0083 |           });
0084 |       if (mounted) Navigator.pop(context, true);
0085 |     } catch (exception) {
0086 |       if (mounted) {
0087 |         setState(() {
0088 |           busy = false;
0089 |           error = readableApiError(exception);
0090 |         });
0091 |       }
0092 |     }
0093 |   }
0094 |
0095 |   @override
0096 |   Widget build(BuildContext context) => Scaffold(
0097 |       appBar: AppBar(title: const Text('Review & correct')),
0098 |       body: Form(
0099 |           key: key,
0100 |           child: ListView(padding: const EdgeInsets.all(20), children: [
0101 |             const Text(
0102 |                 'Compare every value with the source document. Corrections are recorded in the audit trail.'),
0103 |             const SizedBox(height: 20),
0104 |             TextFormField(
0105 |                 controller: patient,
0106 |                 decoration: const InputDecoration(labelText: 'Patient name'),
0107 |                 validator: name),
0108 |             const SizedBox(height: 16),
0109 |             TextFormField(
0110 |                 controller: provider,
0111 |                 decoration: const InputDecoration(labelText: 'Provider name'),
0112 |                 validator: name),
0113 |             const SizedBox(height: 24),
0114 |             for (final d in widget.claim.documents)
0115 |               Padding(
0116 |                   padding: const EdgeInsets.only(bottom: 16),
0117 |                   child: Card(
0118 |                       child: Padding(
0119 |                           padding: const EdgeInsets.all(16),
0120 |                           child: Column(
0121 |                               crossAxisAlignment: CrossAxisAlignment.stretch,
0122 |                               children: [
0123 |                                 Text(d.originalName,
0124 |                                     style: Theme.of(context)
0125 |                                         .textTheme
0126 |                                         .titleMedium),
0127 |                                 Text(
0128 |                                     'OCR amount: ${d.extractedCurrency ?? widget.claim.currency} ${d.extractedAmount?.toStringAsFixed(2) ?? "Not found"}'),
0129 |                                 Text(
0130 |                                     'Client proposal: ${d.clientProposedCurrency ?? d.confirmedCurrency ?? widget.claim.currency} ${(d.clientProposedAmount ?? d.confirmedAmount)?.toStringAsFixed(2) ?? "Not supplied"}'),
0131 |                                 if (d.clientReportedIncorrectAmount)
0132 |                                   const Text(
0133 |                                       'Client reported an incorrect OCR amount. Compare the proposal with the source document.'),
0134 |                                 Text(
0135 |                                     '${friendlyLabel(d.documentType)} • ${friendlyLabel(d.extractionStatus)}'),
0136 |                                 if (d.signedUrl != null)
0137 |                                   TextButton.icon(
0138 |                                       onPressed: () => Navigator.push(
0139 |                                           context,
0140 |                                           MaterialPageRoute(
0141 |                                               builder: (_) =>
0142 |                                                   DocumentPreviewScreen(
0143 |                                                       reference: widget
0144 |                                                           .claim.reference,
0145 |                                                       documentId: d.id,
0146 |                                                       name: d.originalName))),
0147 |                                       icon: const Icon(Icons.open_in_new),
0148 |                                       label: const Text(
0149 |                                           'Compare source document')),
0150 |                                 if (d.duplicateOf != null)
0151 |                                   const Text(
0152 |                                       'Duplicate evidence is excluded from the total.'),
0153 |                                 SwitchListTile(
0154 |                                     contentPadding: EdgeInsets.zero,
0155 |                                     title: const Text('Include in claim total'),
0156 |                                     value: included[d.id]!,
0157 |                                     onChanged: busy || d.duplicateOf != null
0158 |                                         ? null
0159 |                                         : (v) =>
0160 |                                             setState(() => included[d.id] = v)),
0161 |                                 TextFormField(
0162 |                                     controller: amounts[d.id],
0163 |                                     keyboardType:
0164 |                                         const TextInputType.numberWithOptions(
0165 |                                             decimal: true),
0166 |                                     decoration: const InputDecoration(
0167 |                                         labelText: 'Confirmed amount'),
0168 |                                     validator: (v) => included[d.id] == true &&
0169 |                                             (double.tryParse(v ?? '') == null ||
0170 |                                                 double.parse(v!) <= 0)
0171 |                                         ? 'Enter a positive amount'
0172 |                                         : null),
0173 |                                 const SizedBox(height: 12),
0174 |                                 TextFormField(
0175 |                                     controller: currencies[d.id],
0176 |                                     decoration: const InputDecoration(
0177 |                                         labelText: 'Currency (three letters)'),
0178 |                                     validator: (v) => included[d.id] == true &&
0179 |                                             !RegExp(r'^[A-Za-z]{3}$')
0180 |                                                 .hasMatch(v ?? '')
0181 |                                         ? 'Enter a three-letter currency'
0182 |                                         : null),
0183 |                                 if (d.fields.isNotEmpty)
0184 |                                   ExpansionTile(
0185 |                                       title: const Text('Extracted fields'),
0186 |                                       tilePadding: EdgeInsets.zero,
0187 |                                       children: [
0188 |                                         for (final f in d.fields)
0189 |                                           Padding(
0190 |                                               padding: const EdgeInsets.only(
0191 |                                                   bottom: 12),
0192 |                                               child: TextFormField(
0193 |                                                   controller: fields[f.id],
0194 |                                                   decoration: InputDecoration(
0195 |                                                       labelText: friendlyLabel(
0196 |                                                           f.fieldName),
0197 |                                                       helperText:
0198 |                                                           '${(f.confidence * 100).round()}% extraction confidence'),
0199 |                                                   validator: (v) => v == null ||
0200 |                                                           v.trim().isEmpty
0201 |                                                       ? 'Enter a value'
0202 |                                                       : null))
0203 |                                       ]),
0204 |                               ])))),
0205 |             if (error != null)
0206 |               Text(error!,
0207 |                   style: TextStyle(color: Theme.of(context).colorScheme.error)),
0208 |             const SizedBox(height: 16),
0209 |             FilledButton.icon(
0210 |                 onPressed: busy ? null : save,
0211 |                 icon: const Icon(Icons.save_outlined),
0212 |                 label: Text(busy ? 'Saving…' : 'Save reviewed information')),
0213 |           ])));
0214 |   String? name(String? value) => value == null || value.trim().length < 2
0215 |       ? 'Enter at least 2 characters'
0216 |       : null;
0217 | }
```

## mobile/claimlens_mobile/lib/screens/workspace_screens.dart

612 lines. SHA-256: `e98e508ba2571bfac2243f1d59adf79619e66e8ccad1369fe4138adde7496fff`.

Symbols: `WorkspaceMenuScreen`: L13; `WorkspaceData`: L79; `_WorkspaceDataState`: L94; `NotificationsScreen`: L155; `AnalyticsScreen`: L205; `_AnalyticsScreenState`: L211; `AuditScreen`: L292; `_AuditScreenState`: L298; `UsersScreen`: L337; `_UsersScreenState`: L343; `_Empty`: L564; `_Heading`: L583; `_Total`: L592

```dart
0001 | import 'dart:convert';
0002 | import 'package:flutter/material.dart';
0003 | import 'package:flutter/services.dart';
0004 | import 'package:provider/provider.dart';
0005 | import '../providers/auth_provider.dart';
0006 | import '../services/api_client.dart';
0007 | import '../services/workspace_service.dart';
0008 | import '../widgets/workspace_form.dart';
0009 | import 'claim_details_screen.dart';
0010 | import 'profile_screen.dart';
0011 | import 'help_screen.dart';
0012 |
0013 | class WorkspaceMenuScreen extends StatelessWidget {
0014 |   const WorkspaceMenuScreen({super.key});
0015 |   @override
0016 |   Widget build(BuildContext context) {
0017 |     final user = context.watch<AuthProvider>().user!;
0018 |     final entries = <(IconData, String, String, Widget)>[
0019 |       if (!user.isClient)
0020 |         (
0021 |           Icons.bar_chart_outlined,
0022 |           'Analytics',
0023 |           'Claim volumes, outcomes and amounts',
0024 |           const AnalyticsScreen()
0025 |         ),
0026 |       if (!user.isClient)
0027 |         (
0028 |           Icons.history_edu_outlined,
0029 |           'Audit trail',
0030 |           'Review claim and access activity',
0031 |           const AuditScreen()
0032 |         ),
0033 |       (
0034 |         Icons.notifications_outlined,
0035 |         'Notifications',
0036 |         'Updates on your claims and assignments',
0037 |         const NotificationsScreen()
0038 |       ),
0039 |       if (user.isAdmin)
0040 |         (
0041 |           Icons.admin_panel_settings_outlined,
0042 |           'User access',
0043 |           'Manage clients, officers and supervisors',
0044 |           const UsersScreen()
0045 |         ),
0046 |       (
0047 |         Icons.help_outline,
0048 |         'Help & requirements',
0049 |         'Document checklist, privacy and claim settings',
0050 |         const HelpScreen()
0051 |       ),
0052 |       (
0053 |         Icons.settings_outlined,
0054 |         'Account & settings',
0055 |         'Profile, password and appearance',
0056 |         const ProfileScreen()
0057 |       ),
0058 |     ];
0059 |     return Scaffold(
0060 |         appBar: AppBar(title: const Text('Workspace')),
0061 |         body: ListView(padding: const EdgeInsets.all(16), children: [
0062 |           Text('Your tools', style: Theme.of(context).textTheme.headlineSmall),
0063 |           const SizedBox(height: 6),
0064 |           Text('Signed in as ${friendlyLabel(user.role)}'),
0065 |           const SizedBox(height: 20),
0066 |           ...entries.map((entry) => Card(
0067 |               child: ListTile(
0068 |                   contentPadding: const EdgeInsets.all(16),
0069 |                   leading: Icon(entry.$1),
0070 |                   title: Text(entry.$2),
0071 |                   subtitle: Text(entry.$3),
0072 |                   trailing: const Icon(Icons.chevron_right),
0073 |                   onTap: () => Navigator.push(
0074 |                       context, MaterialPageRoute(builder: (_) => entry.$4))))),
0075 |         ]));
0076 |   }
0077 | }
0078 |
0079 | class WorkspaceData extends StatefulWidget {
0080 |   const WorkspaceData(
0081 |       {super.key,
0082 |       required this.title,
0083 |       required this.path,
0084 |       required this.render,
0085 |       this.actions = const []});
0086 |   final String title, path;
0087 |   final List<Widget> actions;
0088 |   final List<Widget> Function(BuildContext, dynamic, Future<void> Function())
0089 |       render;
0090 |   @override
0091 |   State<WorkspaceData> createState() => _WorkspaceDataState();
0092 | }
0093 |
0094 | class _WorkspaceDataState extends State<WorkspaceData> {
0095 |   dynamic data;
0096 |   String? error;
0097 |   bool busy = true;
0098 |   @override
0099 |   void initState() {
0100 |     super.initState();
0101 |     load();
0102 |   }
0103 |
0104 |   @override
0105 |   void didUpdateWidget(WorkspaceData oldWidget) {
0106 |     super.didUpdateWidget(oldWidget);
0107 |     if (oldWidget.path != widget.path) load();
0108 |   }
0109 |
0110 |   Future<void> load() async {
0111 |     setState(() {
0112 |       busy = true;
0113 |       error = null;
0114 |     });
0115 |     try {
0116 |       final response = await workspaceApi(context).get<dynamic>(widget.path);
0117 |       if (mounted) setState(() => data = response.data);
0118 |     } catch (exception) {
0119 |       if (mounted) setState(() => error = readableApiError(exception));
0120 |     } finally {
0121 |       if (mounted) setState(() => busy = false);
0122 |     }
0123 |   }
0124 |
0125 |   @override
0126 |   Widget build(BuildContext context) => Scaffold(
0127 |       appBar: AppBar(title: Text(widget.title), actions: [
0128 |         ...widget.actions,
0129 |         IconButton(
0130 |             tooltip: 'Refresh',
0131 |             onPressed: busy ? null : load,
0132 |             icon: const Icon(Icons.refresh))
0133 |       ]),
0134 |       body: RefreshIndicator(
0135 |           onRefresh: load,
0136 |           child: ListView(
0137 |               physics: const AlwaysScrollableScrollPhysics(),
0138 |               padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
0139 |               children: [
0140 |                 if (busy) const LinearProgressIndicator(),
0141 |                 if (error != null)
0142 |                   Card(
0143 |                       child: Padding(
0144 |                           padding: const EdgeInsets.all(20),
0145 |                           child: Column(children: [
0146 |                             Text(error!),
0147 |                             TextButton(
0148 |                                 onPressed: load, child: const Text('Try again'))
0149 |                           ]))),
0150 |                 if (data != null && error == null)
0151 |                   ...widget.render(context, data, load),
0152 |               ])));
0153 | }
0154 |
0155 | class NotificationsScreen extends StatelessWidget {
0156 |   const NotificationsScreen({super.key});
0157 |   @override
0158 |   Widget build(BuildContext context) => WorkspaceData(
0159 |       title: 'Notifications',
0160 |       path: '/notifications',
0161 |       render: (context, data, reload) => [
0162 |             if ((data as List).isEmpty)
0163 |               const _Empty(
0164 |                   icon: Icons.notifications_none,
0165 |                   title: 'You’re all caught up',
0166 |                   message: 'Claim updates and assignments will appear here.'),
0167 |             ...data.map<Widget>((row) => Card(
0168 |                 child: ListTile(
0169 |                     isThreeLine: true,
0170 |                     leading: Icon(
0171 |                         row['read'] == true
0172 |                             ? Icons.mark_email_read_outlined
0173 |                             : Icons.mark_email_unread_outlined,
0174 |                         color: Theme.of(context).colorScheme.primary),
0175 |                     title: Text(row['title'] as String,
0176 |                         style: TextStyle(
0177 |                             fontWeight: row['read'] == true
0178 |                                 ? FontWeight.normal
0179 |                                 : FontWeight.bold)),
0180 |                     subtitle:
0181 |                         Text('${row['body']}\n${_date(row['created_at'])}'),
0182 |                     onTap: () async {
0183 |                       try {
0184 |                         await workspaceApi(context)
0185 |                             .post<dynamic>('/notifications/${row['id']}/read');
0186 |                         if (!context.mounted) return;
0187 |                         if (row['reference'] != null) {
0188 |                           await Navigator.push(
0189 |                               context,
0190 |                               MaterialPageRoute(
0191 |                                   builder: (_) => ClaimDetailsScreen(
0192 |                                       reference: row['reference'] as String)));
0193 |                         }
0194 |                         await reload();
0195 |                       } catch (error) {
0196 |                         if (context.mounted) {
0197 |                           ScaffoldMessenger.of(context).showSnackBar(
0198 |                               SnackBar(content: Text(readableApiError(error))));
0199 |                         }
0200 |                       }
0201 |                     }))),
0202 |           ]);
0203 | }
0204 |
0205 | class AnalyticsScreen extends StatefulWidget {
0206 |   const AnalyticsScreen({super.key});
0207 |   @override
0208 |   State<AnalyticsScreen> createState() => _AnalyticsScreenState();
0209 | }
0210 |
0211 | class _AnalyticsScreenState extends State<AnalyticsScreen> {
0212 |   DateTimeRange? range;
0213 |   @override
0214 |   Widget build(BuildContext context) => WorkspaceData(
0215 |       title: 'Analytics',
0216 |       path:
0217 |           '/workspace/analytics${range == null ? '' : '?from_date=${range!.start.toIso8601String().substring(0, 10)}&to_date=${range!.end.toIso8601String().substring(0, 10)}'}',
0218 |       actions: [
0219 |         IconButton(
0220 |             tooltip: 'Choose date range',
0221 |             icon: const Icon(Icons.date_range),
0222 |             onPressed: () async {
0223 |               final result = await showDateRangePicker(
0224 |                   context: context,
0225 |                   firstDate: DateTime(2020),
0226 |                   lastDate: DateTime.now(),
0227 |                   initialDateRange: range);
0228 |               if (result != null) setState(() => range = result);
0229 |             })
0230 |       ],
0231 |       render: (context, raw, reload) {
0232 |         final data = Map<String, dynamic>.from(raw as Map);
0233 |         final total = data['total'] as int;
0234 |         List<Widget> bars(Map values) => values.entries
0235 |             .map<Widget>((entry) => Padding(
0236 |                 padding: const EdgeInsets.symmetric(vertical: 8),
0237 |                 child: Column(
0238 |                     crossAxisAlignment: CrossAxisAlignment.start,
0239 |                     children: [
0240 |                       Text(
0241 |                           '${friendlyLabel(entry.key.toString())}  •  ${entry.value}'),
0242 |                       const SizedBox(height: 6),
0243 |                       LinearProgressIndicator(
0244 |                           value: total == 0 ? 0 : (entry.value as num) / total,
0245 |                           minHeight: 8,
0246 |                           borderRadius: BorderRadius.circular(6))
0247 |                     ])))
0248 |             .toList();
0249 |         return [
0250 |           Text(data['scope'] as String,
0251 |               style: Theme.of(context).textTheme.bodySmall),
0252 |           if (range != null)
0253 |             TextButton.icon(
0254 |                 onPressed: () => setState(() => range = null),
0255 |                 icon: const Icon(Icons.clear),
0256 |                 label: Text(
0257 |                     '${_date(range!.start.toIso8601String())} – ${_date(range!.end.toIso8601String())}')),
0258 |           const SizedBox(height: 16),
0259 |           Wrap(spacing: 12, runSpacing: 12, children: [
0260 |             _Total(label: 'Claims', value: '$total'),
0261 |             _Total(label: 'Awaiting assignment', value: '${data['unassigned']}')
0262 |           ]),
0263 |           if (total == 0)
0264 |             const _Empty(
0265 |                 icon: Icons.query_stats,
0266 |                 title: 'No claims in this period',
0267 |                 message:
0268 |                     'Choose another date range or return after claims are submitted.'),
0269 |           const _Heading('Claim status'),
0270 |           ...bars(data['by_status'] as Map),
0271 |           const _Heading('Monthly submissions'),
0272 |           ...bars(data['monthly'] as Map),
0273 |           const _Heading('Amounts by currency'),
0274 |           ...(data['amounts'] as Map).entries.map<Widget>((entry) => Card(
0275 |               child: Padding(
0276 |                   padding: const EdgeInsets.all(20),
0277 |                   child: Column(
0278 |                       crossAxisAlignment: CrossAxisAlignment.start,
0279 |                       children: [
0280 |                         Text(entry.key.toString(),
0281 |                             style: Theme.of(context).textTheme.titleLarge),
0282 |                         for (final name in ['claimed', 'approved', 'paid'])
0283 |                           ListTile(
0284 |                               contentPadding: EdgeInsets.zero,
0285 |                               title: Text(friendlyLabel(name)),
0286 |                               trailing: Text('${entry.value[name]}'))
0287 |                       ])))),
0288 |         ];
0289 |       });
0290 | }
0291 |
0292 | class AuditScreen extends StatefulWidget {
0293 |   const AuditScreen({super.key});
0294 |   @override
0295 |   State<AuditScreen> createState() => _AuditScreenState();
0296 | }
0297 |
0298 | class _AuditScreenState extends State<AuditScreen> {
0299 |   String search = '';
0300 |   @override
0301 |   Widget build(BuildContext context) => WorkspaceData(
0302 |       title: 'Audit trail',
0303 |       path: '/workspace/audit?search=${Uri.encodeQueryComponent(search)}',
0304 |       render: (context, data, reload) => [
0305 |             TextFormField(
0306 |                 initialValue: search,
0307 |                 decoration: const InputDecoration(
0308 |                     labelText: 'Search reference or event',
0309 |                     prefixIcon: Icon(Icons.search)),
0310 |                 textInputAction: TextInputAction.search,
0311 |                 onFieldSubmitted: (v) => setState(() => search = v)),
0312 |             const SizedBox(height: 16),
0313 |             if ((data as List).isEmpty)
0314 |               const _Empty(
0315 |                   icon: Icons.history_edu,
0316 |                   title: 'No matching activity',
0317 |                   message: 'Recorded actions will appear here.'),
0318 |             ...data.map<Widget>((row) => Card(
0319 |                     child: ExpansionTile(
0320 |                         leading: const Icon(Icons.history),
0321 |                         title: Text(friendlyLabel(row['event_type'] as String)),
0322 |                         subtitle: Text(
0323 |                             '${row['reference']} • ${_date(row['created_at'])}'),
0324 |                         childrenPadding: const EdgeInsets.all(16),
0325 |                         children: [
0326 |                       Align(
0327 |                           alignment: Alignment.centerLeft,
0328 |                           child: SelectableText(
0329 |                               'Actor: ${row['actor_id'] ?? 'System'}\n${const JsonEncoder.withIndent('  ').convert(row['metadata'] ?? {})}'))
0330 |                     ]))),
0331 |             if (data.length == 200)
0332 |               const Text(
0333 |                   'Showing the latest 200 events. Search to narrow the results.'),
0334 |           ]);
0335 | }
0336 |
0337 | class UsersScreen extends StatefulWidget {
0338 |   const UsersScreen({super.key});
0339 |   @override
0340 |   State<UsersScreen> createState() => _UsersScreenState();
0341 | }
0342 |
0343 | class _UsersScreenState extends State<UsersScreen> {
0344 |   static const grants = {
0345 |     'claims.review': 'Review and verify claims',
0346 |     'claims.decide': 'Approve or reject claims',
0347 |     'payments.record': 'Record payments'
0348 |   };
0349 |   List<FormEntry> permissionFields([Map? row]) => grants.entries
0350 |       .map((p) => FormEntry(p.key, 'Additional right: ${p.value}',
0351 |               value: ((row?['permissions'] as List? ?? []).contains(p.key))
0352 |                   .toString(),
0353 |               options: const {
0354 |                 'false': 'Use role defaults',
0355 |                 'true': 'Grant this additional right'
0356 |               }))
0357 |       .toList();
0358 |   Map<String, dynamic> accountPayload(Map<String, String> values) => {
0359 |         for (final item in values.entries)
0360 |           if (!grants.containsKey(item.key)) item.key: item.value,
0361 |         'permissions': [
0362 |           for (final p in grants.keys)
0363 |             if (values[p] == 'true') p
0364 |         ]
0365 |       };
0366 |   String search = '', role = 'all';
0367 |   int revision = 0;
0368 |   Future<void> create() async {
0369 |     final saved = await workspaceForm(context,
0370 |         title: 'Create account',
0371 |         explanation:
0372 |             'Public signup creates client accounts. Only administrators can create staff accounts.',
0373 |         fields: [
0374 |           const FormEntry('display_name', 'Full name'),
0375 |           const FormEntry('email', 'Email address'),
0376 |           FormEntry('role', 'Role',
0377 |               value: 'client', options: labelOptions(accountRoles)),
0378 |           const FormEntry(
0379 |               'password', 'Initial password (at least 12 characters)',
0380 |               secret: true),
0381 |           ...permissionFields()
0382 |         ], submit: (v) async {
0383 |       await workspaceApi(context)
0384 |           .post<dynamic>('/users', data: accountPayload(v));
0385 |     });
0386 |     if (saved == true && mounted) setState(() => revision++);
0387 |   }
0388 |
0389 |   Future<void> edit(Map row, Future<void> Function() reload) async {
0390 |     final saved =
0391 |         await workspaceForm(context, title: 'Edit user access', fields: [
0392 |       FormEntry('display_name', 'Full name',
0393 |           value: row['display_name'] as String),
0394 |       FormEntry('role', 'Role',
0395 |           value: row['role'] as String, options: labelOptions(accountRoles)),
0396 |       FormEntry('status', 'Account status',
0397 |           value: row['status'] as String,
0398 |           options: labelOptions(['active', 'inactive'])),
0399 |       ...permissionFields(row)
0400 |     ], submit: (v) async {
0401 |       await workspaceApi(context)
0402 |           .put<dynamic>('/users/${row['id']}', data: accountPayload(v));
0403 |     });
0404 |     if (saved == true) await reload();
0405 |   }
0406 |
0407 |   Future<void> action(
0408 |       String value, Map row, Future<void> Function() reload) async {
0409 |     try {
0410 |       if (value == 'edit') {
0411 |         await edit(row, reload);
0412 |         return;
0413 |       }
0414 |       if (value == 'password') {
0415 |         await workspaceForm(context,
0416 |             title: 'Set temporary password',
0417 |             explanation:
0418 |                 'The user’s existing sessions will be revoked. They must change this temporary password when they next sign in.',
0419 |             fields: const [
0420 |               FormEntry('new_password',
0421 |                   'New temporary password (at least 12 characters)',
0422 |                   secret: true),
0423 |               FormEntry('confirm', 'Confirm temporary password', secret: true),
0424 |               FormEntry('admin_password', 'Your administrator password',
0425 |                   secret: true)
0426 |             ], submit: (v) async {
0427 |           if (v['new_password'] != v['confirm']) {
0428 |             throw Exception('Passwords do not match.');
0429 |           }
0430 |           await workspaceApi(context)
0431 |               .post<dynamic>('/users/${row['id']}/password', data: {
0432 |             'new_password': v['new_password'],
0433 |             'admin_password': v['admin_password']
0434 |           });
0435 |         });
0436 |         return;
0437 |       }
0438 |       if (value == 'reset') {
0439 |         final result = await workspaceApi(context)
0440 |             .post<Map<String, dynamic>>('/users/${row['id']}/password-reset');
0441 |         if (!mounted) return;
0442 |         final link = result.data!['link'] as String;
0443 |         await showDialog<void>(
0444 |             context: context,
0445 |             builder: (c) => AlertDialog(
0446 |                     title: const Text('Private recovery link'),
0447 |                     content: SingleChildScrollView(
0448 |                         child:
0449 |                             Column(mainAxisSize: MainAxisSize.min, children: [
0450 |                       const Text(
0451 |                           'Share this link privately with the account owner. It has not been emailed.'),
0452 |                       const SizedBox(height: 12),
0453 |                       SelectableText(link)
0454 |                     ])),
0455 |                     actions: [
0456 |                       TextButton(
0457 |                           onPressed: () =>
0458 |                               Clipboard.setData(ClipboardData(text: link)),
0459 |                           child: const Text('Copy link')),
0460 |                       FilledButton(
0461 |                           onPressed: () => Navigator.pop(c),
0462 |                           child: const Text('Done'))
0463 |                     ]));
0464 |       } else {
0465 |         final confirmed = await showDialog<bool>(
0466 |             context: context,
0467 |             builder: (c) => AlertDialog(
0468 |                     title: const Text('Delete login account?'),
0469 |                     content: Text(
0470 |                         '${row['email']} will no longer be able to sign in. Claim and audit records are retained.'),
0471 |                     actions: [
0472 |                       TextButton(
0473 |                           onPressed: () => Navigator.pop(c, false),
0474 |                           child: const Text('Cancel')),
0475 |                       FilledButton(
0476 |                           onPressed: () => Navigator.pop(c, true),
0477 |                           child: const Text('Delete account'))
0478 |                     ]));
0479 |         if (confirmed == true && mounted) {
0480 |           await workspaceApi(context).delete<dynamic>('/users/${row['id']}');
0481 |           await reload();
0482 |         }
0483 |       }
0484 |     } catch (error) {
0485 |       if (mounted) {
0486 |         ScaffoldMessenger.of(context)
0487 |             .showSnackBar(SnackBar(content: Text(readableApiError(error))));
0488 |       }
0489 |     }
0490 |   }
0491 |
0492 |   @override
0493 |   Widget build(BuildContext context) => WorkspaceData(
0494 |       key: ValueKey(revision),
0495 |       title: 'User access',
0496 |       path: '/users',
0497 |       actions: [
0498 |         IconButton(
0499 |             tooltip: 'Create account',
0500 |             onPressed: create,
0501 |             icon: const Icon(Icons.person_add_outlined))
0502 |       ],
0503 |       render: (context, raw, reload) {
0504 |         final data = (raw as List)
0505 |             .where((row) =>
0506 |                 (role == 'all' || row['role'] == role) &&
0507 |                 '${row['display_name']} ${row['email']} ${row['status']}'
0508 |                     .toLowerCase()
0509 |                     .contains(search.toLowerCase()))
0510 |             .toList();
0511 |         return [
0512 |           TextField(
0513 |               decoration: const InputDecoration(
0514 |                   labelText: 'Search name, email or status',
0515 |                   prefixIcon: Icon(Icons.search)),
0516 |               onChanged: (v) => setState(() => search = v)),
0517 |           const SizedBox(height: 12),
0518 |           DropdownButtonFormField<String>(
0519 |               initialValue: role,
0520 |               isExpanded: true,
0521 |               decoration: const InputDecoration(labelText: 'Role'),
0522 |               items: [
0523 |                 const DropdownMenuItem(value: 'all', child: Text('All roles')),
0524 |                 ...accountRoles.map((r) =>
0525 |                     DropdownMenuItem(value: r, child: Text(friendlyLabel(r))))
0526 |               ],
0527 |               onChanged: (v) => setState(() => role = v!)),
0528 |           const SizedBox(height: 12),
0529 |           if (data.isEmpty)
0530 |             const _Empty(
0531 |                 icon: Icons.people_outline,
0532 |                 title: 'No users match',
0533 |                 message: 'Change your filters or create an account.'),
0534 |           ...data.map<Widget>((row) => Card(
0535 |               child: ListTile(
0536 |                   isThreeLine: true,
0537 |                   leading: CircleAvatar(
0538 |                       child: Icon(row['role'] == 'client'
0539 |                           ? Icons.person_outline
0540 |                           : Icons.badge_outlined)),
0541 |                   title: Text(row['display_name'] as String),
0542 |                   subtitle: Text(
0543 |                       '${row['email']}\n${friendlyLabel(row['role'] as String)} • ${friendlyLabel(row['status'] as String)}'),
0544 |                   trailing: PopupMenuButton<String>(
0545 |                       tooltip: 'Manage account',
0546 |                       onSelected: (value) => action(value, row as Map, reload),
0547 |                       itemBuilder: (_) => const [
0548 |                             PopupMenuItem(
0549 |                                 value: 'edit', child: Text('Edit access')),
0550 |                             PopupMenuItem(
0551 |                                 value: 'reset',
0552 |                                 child: Text('Password recovery')),
0553 |                             PopupMenuItem(
0554 |                                 value: 'password',
0555 |                                 child: Text('Set temporary password')),
0556 |                             PopupMenuItem(
0557 |                                 value: 'delete', child: Text('Delete login'))
0558 |                           ]),
0559 |                   onTap: () => edit(row as Map, reload)))),
0560 |         ];
0561 |       });
0562 | }
0563 |
0564 | class _Empty extends StatelessWidget {
0565 |   const _Empty(
0566 |       {required this.icon, required this.title, required this.message});
0567 |   final IconData icon;
0568 |   final String title, message;
0569 |   @override
0570 |   Widget build(BuildContext context) => Padding(
0571 |       padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
0572 |       child: Column(children: [
0573 |         Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary),
0574 |         const SizedBox(height: 16),
0575 |         Text(title,
0576 |             style: Theme.of(context).textTheme.titleLarge,
0577 |             textAlign: TextAlign.center),
0578 |         const SizedBox(height: 8),
0579 |         Text(message, textAlign: TextAlign.center)
0580 |       ]));
0581 | }
0582 |
0583 | class _Heading extends StatelessWidget {
0584 |   const _Heading(this.text);
0585 |   final String text;
0586 |   @override
0587 |   Widget build(BuildContext context) => Padding(
0588 |       padding: const EdgeInsets.only(top: 24, bottom: 12),
0589 |       child: Text(text, style: Theme.of(context).textTheme.titleLarge));
0590 | }
0591 |
0592 | class _Total extends StatelessWidget {
0593 |   const _Total({required this.label, required this.value});
0594 |   final String label, value;
0595 |   @override
0596 |   Widget build(BuildContext context) => Card(
0597 |       child: Padding(
0598 |           padding: const EdgeInsets.all(24),
0599 |           child: Column(
0600 |               crossAxisAlignment: CrossAxisAlignment.start,
0601 |               children: [
0602 |                 Text(value, style: Theme.of(context).textTheme.headlineLarge),
0603 |                 Text(label)
0604 |               ])));
0605 | }
0606 |
0607 | String _date(dynamic value) =>
0608 |     DateTime.tryParse(value?.toString() ?? '')
0609 |         ?.toLocal()
0610 |         .toString()
0611 |         .substring(0, 16) ??
0612 |     '';
```

## mobile/claimlens_mobile/lib/services/api_client.dart

182 lines. SHA-256: `a99b344d5fcf2064338f5311797d086bc67d61f0aebf576f53ea4643b25dc522`.

Symbols: `ApiClient`: L9

```dart
0001 | import 'dart:async';
0002 |
0003 | import 'package:dio/dio.dart';
0004 | import 'package:flutter_secure_storage/flutter_secure_storage.dart';
0005 | import 'package:flutter/foundation.dart';
0006 |
0007 | import '../config/api_config.dart';
0008 |
0009 | class ApiClient {
0010 |   ApiClient()
0011 |       : dio = Dio(
0012 |           BaseOptions(
0013 |             baseUrl: ApiConfig.baseUrl,
0014 |             connectTimeout: const Duration(seconds: 15),
0015 |             receiveTimeout: const Duration(seconds: 120),
0016 |             headers: {'Accept': 'application/json'},
0017 |           ),
0018 |         ) {
0019 |     dio.interceptors.add(
0020 |       InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
0021 |     );
0022 |   }
0023 |
0024 |   final Dio dio;
0025 |   final FlutterSecureStorage _storage = const FlutterSecureStorage();
0026 |   String? _accessToken;
0027 |   String? _refreshToken;
0028 |   Future<bool>? _refreshOperation;
0029 |   void Function()? onSessionExpired;
0030 |
0031 |   bool get hasSession => _accessToken != null && _refreshToken != null;
0032 |   Future<bool> refreshSession() => _refresh();
0033 |
0034 |   Future<void> initialise() async {
0035 |     final savedServer = await _storage.read(key: 'server_url');
0036 |     final previousBuildServer = await _storage.read(key: 'build_server_url');
0037 |     // A newly installed build may move from USB to an internet API. Do not let
0038 |     // an older saved development address override that build's configuration.
0039 |     final buildChanged = previousBuildServer != ApiConfig.baseUrl;
0040 |     final server =
0041 |         buildChanged ? ApiConfig.baseUrl : savedServer ?? ApiConfig.baseUrl;
0042 |     if (savedServer != null && savedServer != server) {
0043 |       await clearSession();
0044 |     }
0045 |     await _storage.write(key: 'build_server_url', value: ApiConfig.baseUrl);
0046 |     await _storage.write(key: 'server_url', value: server);
0047 |     dio.options.baseUrl = server;
0048 |     _accessToken = await _storage.read(key: 'access_token');
0049 |     _refreshToken = await _storage.read(key: 'refresh_token');
0050 |   }
0051 |
0052 |   Future<void> saveSession(String accessToken, String refreshToken) async {
0053 |     _accessToken = accessToken;
0054 |     _refreshToken = refreshToken;
0055 |     await Future.wait([
0056 |       _storage.write(key: 'access_token', value: accessToken),
0057 |       _storage.write(key: 'refresh_token', value: refreshToken),
0058 |     ]);
0059 |   }
0060 |
0061 |   Future<void> clearSession() async {
0062 |     _accessToken = null;
0063 |     _refreshToken = null;
0064 |     await Future.wait([
0065 |       _storage.delete(key: 'access_token'),
0066 |       _storage.delete(key: 'refresh_token')
0067 |     ]);
0068 |   }
0069 |
0070 |   void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
0071 |     if (_accessToken != null) {
0072 |       options.headers['Authorization'] = 'Bearer $_accessToken';
0073 |     }
0074 |     handler.next(options);
0075 |   }
0076 |
0077 |   Future<void> _onError(
0078 |     DioException error,
0079 |     ErrorInterceptorHandler handler,
0080 |   ) async {
0081 |     final request = error.requestOptions;
0082 |     if (error.response?.statusCode != 401 ||
0083 |         request.extra['retried'] == true ||
0084 |         _refreshToken == null ||
0085 |         request.path.contains('/auth/')) {
0086 |       handler.next(error);
0087 |       return;
0088 |     }
0089 |     _refreshOperation ??= _refresh();
0090 |     final refreshed = await _refreshOperation!;
0091 |     _refreshOperation = null;
0092 |     if (!refreshed) {
0093 |       handler.next(error);
0094 |       return;
0095 |     }
0096 |     request.headers['Authorization'] = 'Bearer $_accessToken';
0097 |     request.extra['retried'] = true;
0098 |     try {
0099 |       handler.resolve(await dio.fetch<dynamic>(request));
0100 |     } on DioException catch (retryError) {
0101 |       handler.next(retryError);
0102 |     }
0103 |   }
0104 |
0105 |   Future<bool> _refresh() async {
0106 |     try {
0107 |       final response = await Dio(BaseOptions(baseUrl: dio.options.baseUrl))
0108 |           .post<Map<String, dynamic>>(
0109 |         '/auth/refresh',
0110 |         data: {'refresh_token': _refreshToken},
0111 |       );
0112 |       final data = response.data!;
0113 |       await saveSession(
0114 |         data['access_token'] as String,
0115 |         data['refresh_token'] as String,
0116 |       );
0117 |       return true;
0118 |     } catch (exception) {
0119 |       final status =
0120 |           exception is DioException ? exception.response?.statusCode : null;
0121 |       if ([400, 401, 403].contains(status)) {
0122 |         await clearSession();
0123 |         onSessionExpired?.call();
0124 |       }
0125 |       return false;
0126 |     }
0127 |   }
0128 |
0129 |   Future<void> configureServer(String value) async {
0130 |     final uri = Uri.tryParse(value.trim());
0131 |     if (uri == null ||
0132 |         uri.host.isEmpty ||
0133 |         uri.userInfo.isNotEmpty ||
0134 |         uri.hasQuery ||
0135 |         uri.hasFragment ||
0136 |         !['https', 'http'].contains(uri.scheme)) {
0137 |       throw Exception('Enter a valid server URL.');
0138 |     }
0139 |     final host = uri.host;
0140 |     final local = host == 'localhost' ||
0141 |         host == '127.0.0.1' ||
0142 |         host.startsWith('10.') ||
0143 |         host.startsWith('192.168.') ||
0144 |         RegExp(r'^172\.(1[6-9]|2[0-9]|3[01])\.').hasMatch(host);
0145 |     if (uri.scheme != 'https' && !(kDebugMode && local)) {
0146 |       throw Exception('Internet connections must use HTTPS.');
0147 |     }
0148 |     final base = uri.replace(path: '/api/v1').toString();
0149 |     final health = await Dio().get<Map<String, dynamic>>('$base/health',
0150 |         options: Options(receiveTimeout: const Duration(seconds: 15)));
0151 |     if (!['ClaimLens API', 'claimelens API']
0152 |         .contains(health.data?['service'])) {
0153 |       throw Exception('This address is not a ClaimLens server.');
0154 |     }
0155 |     await clearSession();
0156 |     await _storage.write(key: 'server_url', value: base);
0157 |     dio.options.baseUrl = base;
0158 |   }
0159 | }
0160 |
0161 | String readableApiError(Object error) {
0162 |   if (error is DioException) {
0163 |     final data = error.response?.data;
0164 |     if (data is Map && data['detail'] != null) {
0165 |       final detail = data['detail'];
0166 |       if (detail is List) {
0167 |         return detail
0168 |             .whereType<Map>()
0169 |             .map(
0170 |                 (entry) => entry['msg']?.toString() ?? 'Check the form fields.')
0171 |             .join('\n');
0172 |       }
0173 |       return detail.toString();
0174 |     }
0175 |     if (error.type == DioExceptionType.connectionError ||
0176 |         error.type == DioExceptionType.connectionTimeout) {
0177 |       return 'Cannot reach the ClaimLens server. Check the API address and your connection.';
0178 |     }
0179 |     return error.message ?? 'The request could not be completed.';
0180 |   }
0181 |   return error.toString().replaceFirst('Exception: ', '');
0182 | }
```

## mobile/claimlens_mobile/lib/services/auth_service.dart

33 lines. SHA-256: `3c08690fb18bd3a09edae3a0e4a97bf88ba2dcc0d294839f7d1d45e7ab170245`.

Symbols: `AuthService`: L4

```dart
0001 | import '../models/user_profile.dart';
0002 | import 'api_client.dart';
0003 |
0004 | class AuthService {
0005 |   const AuthService(this.client);
0006 |   final ApiClient client;
0007 |
0008 |   Future<UserProfile> login(String email, String password) async {
0009 |     final response = await client.dio.post<Map<String, dynamic>>(
0010 |       '/auth/login',
0011 |       data: {'email': email.trim(), 'password': password},
0012 |     );
0013 |     final data = response.data!;
0014 |     await client.saveSession(
0015 |       data['access_token'] as String,
0016 |       data['refresh_token'] as String,
0017 |     );
0018 |     return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
0019 |   }
0020 |
0021 |   Future<UserProfile> profile() async {
0022 |     final response = await client.dio.get<Map<String, dynamic>>('/profile');
0023 |     return UserProfile.fromJson(response.data!);
0024 |   }
0025 |
0026 |   Future<void> logout() async {
0027 |     try {
0028 |       await client.dio.post<void>('/auth/logout');
0029 |     } finally {
0030 |       await client.clearSession();
0031 |     }
0032 |   }
0033 | }
```

## mobile/claimlens_mobile/lib/services/claim_service.dart

87 lines. SHA-256: `53e9e02270beddf143512cd43452a1f8930be7b567025c6c675f2cdbb11c4487`.

Symbols: `ClaimService`: L8

```dart
0001 | import 'package:dio/dio.dart';
0002 | import 'package:http_parser/http_parser.dart';
0003 |
0004 | import '../models/claim.dart';
0005 | import '../models/selected_document.dart';
0006 | import 'api_client.dart';
0007 |
0008 | class ClaimService {
0009 |   const ClaimService(this.client);
0010 |   final ApiClient client;
0011 |
0012 |   Future<DashboardData> dashboard() async {
0013 |     final response = await client.dio.get<Map<String, dynamic>>(
0014 |       '/claims/dashboard',
0015 |     );
0016 |     return DashboardData.fromJson(response.data!);
0017 |   }
0018 |
0019 |   Future<List<ClaimSummary>> list({String? search, String? status}) async {
0020 |     final response = await client.dio.get<List<dynamic>>(
0021 |       '/claims',
0022 |       queryParameters: {
0023 |         if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
0024 |         if (status != null && status.isNotEmpty) 'status': status,
0025 |       },
0026 |     );
0027 |     return response.data!
0028 |         .map((item) => ClaimSummary.fromJson(item as Map<String, dynamic>))
0029 |         .toList();
0030 |   }
0031 |
0032 |   Future<ClaimDetails> create(List<SelectedDocument> documents,
0033 |       {String? requestKey, void Function(int, int)? onSendProgress}) async {
0034 |     final data = FormData();
0035 |     for (final document in documents) {
0036 |       data.files.add(
0037 |         MapEntry(
0038 |           'files',
0039 |           MultipartFile.fromBytes(
0040 |             document.bytes,
0041 |             filename: document.name,
0042 |             contentType: MediaType.parse(document.mimeType),
0043 |           ),
0044 |         ),
0045 |       );
0046 |     }
0047 |     final response = await client.dio.post<Map<String, dynamic>>(
0048 |       '/claims',
0049 |       data: data,
0050 |       options: Options(
0051 |           headers: {if (requestKey != null) 'Idempotency-Key': requestKey}),
0052 |       onSendProgress: onSendProgress,
0053 |     );
0054 |     return ClaimDetails.fromJson(response.data!);
0055 |   }
0056 |
0057 |   Future<ClaimDetails> details(String reference) async {
0058 |     final response = await client.dio.get<Map<String, dynamic>>(
0059 |       '/claims/$reference',
0060 |     );
0061 |     return ClaimDetails.fromJson(response.data!);
0062 |   }
0063 |
0064 |   Future<void> process(String reference) async {
0065 |     await client.dio.post<Map<String, dynamic>>('/claims/$reference/process',
0066 |         queryParameters: {'background': true});
0067 |   }
0068 |
0069 |   Future<String> confirm(
0070 |     String reference,
0071 |     String patient,
0072 |     String provider,
0073 |     List<DocumentConfirmation> documents,
0074 |     List<FieldCorrection> fields,
0075 |   ) async {
0076 |     final response = await client.dio.post<Map<String, dynamic>>(
0077 |       '/claims/$reference/confirm',
0078 |       data: {
0079 |         'patient_name': patient,
0080 |         'provider_name': provider,
0081 |         'documents': documents.map((document) => document.toJson()).toList(),
0082 |         'fields': fields.map((field) => field.toJson()).toList(),
0083 |       },
0084 |     );
0085 |     return response.data!['status'] as String;
0086 |   }
0087 | }
```

## mobile/claimlens_mobile/lib/services/push_service.dart

61 lines. SHA-256: `904d45fe8ca8af054ffcc9d20317505fd9542913edf4b21fbf01b17bc9d69047`.

Symbols: `PushService`: L13

```dart
0001 | import 'dart:async';
0002 | import 'package:firebase_core/firebase_core.dart';
0003 | import 'package:firebase_messaging/firebase_messaging.dart';
0004 | import 'api_client.dart';
0005 |
0006 | @pragma('vm:entry-point')
0007 | Future<void> claimLensBackgroundMessage(RemoteMessage message) async {
0008 |   await Firebase.initializeApp();
0009 |   // OS notifications contain generic text. Medical details are fetched only
0010 |   // after the user opens the app and an authenticated API request succeeds.
0011 | }
0012 |
0013 | class PushService {
0014 |   PushService(this.client);
0015 |   final ApiClient client;
0016 |   static String? _installationId;
0017 |   StreamSubscription<String>? refresh;
0018 |   StreamSubscription<RemoteMessage>? opened;
0019 |   Future<void> initialise({required void Function(String) onOpen}) async {
0020 |     if (Firebase.apps.isEmpty) return;
0021 |     try {
0022 |       final messaging = FirebaseMessaging.instance;
0023 |       final permission = await messaging.requestPermission();
0024 |       if (permission.authorizationStatus != AuthorizationStatus.authorized &&
0025 |           permission.authorizationStatus != AuthorizationStatus.provisional) {
0026 |         return;
0027 |       }
0028 |       refresh = messaging.onRegistered.listen((fid) async {
0029 |         _installationId = fid;
0030 |         try {
0031 |           await client.dio.post<dynamic>('/devices', data: {'token': fid});
0032 |         } catch (_) {}
0033 |       });
0034 |       await messaging.register();
0035 |       opened = FirebaseMessaging.onMessageOpenedApp.listen((message) {
0036 |         final reference = message.data['reference'];
0037 |         if (reference is String && reference.isNotEmpty) onOpen(reference);
0038 |       });
0039 |       final initial = await messaging.getInitialMessage();
0040 |       final reference = initial?.data['reference'];
0041 |       if (reference is String && reference.isNotEmpty) onOpen(reference);
0042 |     } catch (_) {/* In-app notifications work when OS push is unavailable. */}
0043 |   }
0044 |
0045 |   Future<void> dispose() async {
0046 |     await refresh?.cancel();
0047 |     await opened?.cancel();
0048 |   }
0049 |
0050 |   static Future<void> unregister(ApiClient client) async {
0051 |     if (Firebase.apps.isEmpty) return;
0052 |     try {
0053 |       final token = _installationId;
0054 |       if (token != null) {
0055 |         await client.dio.delete<dynamic>('/devices', data: {'token': token});
0056 |       }
0057 |       await FirebaseMessaging.instance.unregister();
0058 |       _installationId = null;
0059 |     } catch (_) {}
0060 |   }
0061 | }
```

## mobile/claimlens_mobile/lib/services/workspace_service.dart

37 lines. SHA-256: `0fb054a054f728f2d200ce0552f32fcbb163c25c91b6abd89ccec7fa8b4d0492`.

Symbols: Configuration/resource file.

```dart
0001 | import 'package:dio/dio.dart';
0002 | import 'package:provider/provider.dart';
0003 | import 'package:flutter/widgets.dart';
0004 | import '../providers/auth_provider.dart';
0005 |
0006 | Dio workspaceApi(BuildContext context) =>
0007 |     context.read<AuthProvider>().client.dio;
0008 |
0009 | String friendlyLabel(String value) => value
0010 |     .replaceAll('_', ' ')
0011 |     .replaceAll('-', ' ')
0012 |     .split(' ')
0013 |     .map((word) => word.isEmpty
0014 |         ? ''
0015 |         : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
0016 |     .join(' ');
0017 |
0018 | const claimStatuses = [
0019 |   'UPLOADED',
0020 |   'PROCESSING',
0021 |   'REVIEW_REQUIRED',
0022 |   'INFORMATION_REQUIRED',
0023 |   'INFORMATION_RECEIVED',
0024 |   'VERIFIED',
0025 |   'APPROVED',
0026 |   'REJECTED',
0027 |   'PAYMENT_PENDING',
0028 |   'PAID',
0029 |   'PROCESSING_FAILED'
0030 | ];
0031 | const accountRoles = [
0032 |   'client',
0033 |   'claims_officer',
0034 |   'supervisor',
0035 |   'finance',
0036 |   'administrator'
0037 | ];
```

## mobile/claimlens_mobile/lib/widgets/claim_card.dart

78 lines. SHA-256: `3a77721f917736c98c877f7eed047426171ea00aa14d4631425ba99c09b6ff9f`.

Symbols: `ClaimCard`: L8

```dart
0001 | import 'package:flutter/material.dart';
0002 | import 'package:intl/intl.dart';
0003 |
0004 | import '../models/claim.dart';
0005 | import '../screens/claim_details_screen.dart';
0006 | import 'status_chip.dart';
0007 |
0008 | class ClaimCard extends StatelessWidget {
0009 |   const ClaimCard({super.key, required this.claim});
0010 |   final ClaimSummary claim;
0011 |
0012 |   @override
0013 |   Widget build(BuildContext context) => Card(
0014 |         clipBehavior: Clip.antiAlias,
0015 |         child: InkWell(
0016 |           onTap: () => Navigator.push(
0017 |             context,
0018 |             MaterialPageRoute(
0019 |               builder: (_) => ClaimDetailsScreen(reference: claim.reference),
0020 |             ),
0021 |           ),
0022 |           child: Padding(
0023 |             padding: const EdgeInsets.all(16),
0024 |             child: Column(
0025 |               crossAxisAlignment: CrossAxisAlignment.start,
0026 |               children: [
0027 |                 Wrap(
0028 |                   spacing: 12,
0029 |                   runSpacing: 8,
0030 |                   children: [
0031 |                     Text(
0032 |                       claim.reference,
0033 |                       style: const TextStyle(fontWeight: FontWeight.w800),
0034 |                     ),
0035 |                     StatusChip(status: claim.status),
0036 |                   ],
0037 |                 ),
0038 |                 const SizedBox(height: 10),
0039 |                 Text(
0040 |                   claim.patientName.isEmpty
0041 |                       ? 'Patient awaiting confirmation'
0042 |                       : claim.patientName,
0043 |                 ),
0044 |                 Text(
0045 |                   claim.providerName.isEmpty
0046 |                       ? 'Provider awaiting confirmation'
0047 |                       : claim.providerName,
0048 |                   style: TextStyle(color: Colors.grey.shade700),
0049 |                 ),
0050 |                 const SizedBox(height: 10),
0051 |                 Column(
0052 |                   crossAxisAlignment: CrossAxisAlignment.start,
0053 |                   children: [
0054 |                     Text(
0055 |                       claim.claimedAmount == null
0056 |                           ? 'Amount pending'
0057 |                           : '${claim.currency} ${claim.claimedAmount!.toStringAsFixed(2)}',
0058 |                       style: const TextStyle(fontWeight: FontWeight.w700),
0059 |                     ),
0060 |                     const SizedBox(height: 8),
0061 |                     Row(children: [
0062 |                       Expanded(
0063 |                           child: Text(
0064 |                         DateFormat('dd MMM yyyy')
0065 |                             .format(claim.createdAt.toLocal()),
0066 |                         style: Theme.of(context).textTheme.bodySmall,
0067 |                       )),
0068 |                       const SizedBox(width: 4),
0069 |                       const Icon(Icons.chevron_right, size: 18)
0070 |                     ]),
0071 |                   ],
0072 |                 ),
0073 |               ],
0074 |             ),
0075 |           ),
0076 |         ),
0077 |       );
0078 | }
```

## mobile/claimlens_mobile/lib/widgets/claimlens_logo.dart

50 lines. SHA-256: `82cb3233899f96230bc4ccb993e341e4d4fa7b5e7f16b926bf107e5b198d5c01`.

Symbols: `ClaimLensLogo`: L3; `_LogoPainter`: L16

```dart
0001 | import 'package:flutter/material.dart';
0002 |
0003 | class ClaimLensLogo extends StatelessWidget {
0004 |   const ClaimLensLogo({super.key, this.size = 64});
0005 |   final double size;
0006 |   @override
0007 |   Widget build(BuildContext context) => ExcludeSemantics(
0008 |       child: Center(
0009 |           widthFactor: 1,
0010 |           heightFactor: 1,
0011 |           child: SizedBox.square(
0012 |               dimension: size,
0013 |               child: CustomPaint(painter: const _LogoPainter()))));
0014 | }
0015 |
0016 | class _LogoPainter extends CustomPainter {
0017 |   const _LogoPainter();
0018 |   @override
0019 |   void paint(Canvas canvas, Size size) {
0020 |     final side = size.width;
0021 |     canvas.drawRRect(
0022 |         RRect.fromRectAndRadius(
0023 |             Offset.zero & size, Radius.circular(side * .24)),
0024 |         Paint()..color = const Color(0xff006d77));
0025 |     final white = Paint()
0026 |       ..color = Colors.white
0027 |       ..style = PaintingStyle.stroke
0028 |       ..strokeWidth = side * .073
0029 |       ..strokeCap = StrokeCap.round;
0030 |     canvas.drawCircle(Offset(side * .438, side * .438), side * .214, white);
0031 |     canvas.drawLine(Offset(side * .625, side * .625),
0032 |         Offset(side * .802, side * .802), white);
0033 |     final mint = Paint()..color = const Color(0xff8de2d7);
0034 |     canvas.drawRect(
0035 |         Rect.fromCenter(
0036 |             center: Offset(side * .438, side * .438),
0037 |             width: side * .083,
0038 |             height: side * .23),
0039 |         mint);
0040 |     canvas.drawRect(
0041 |         Rect.fromCenter(
0042 |             center: Offset(side * .438, side * .438),
0043 |             width: side * .23,
0044 |             height: side * .083),
0045 |         mint);
0046 |   }
0047 |
0048 |   @override
0049 |   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
0050 | }
```

## mobile/claimlens_mobile/lib/widgets/session_guard.dart

157 lines. SHA-256: `2a4b75bf1876450d446110ae0a8ab71b2cbb34a3e69defeaad71e6af5c2dc52f`.

Symbols: `SessionGuard`: L7; `_SessionGuardState`: L14; `_UnlockScreen`: L60; `_UnlockScreenState`: L66

```dart
0001 | import 'dart:async';
0002 | import 'package:flutter/material.dart';
0003 | import 'package:provider/provider.dart';
0004 | import '../providers/auth_provider.dart';
0005 | import '../services/api_client.dart';
0006 |
0007 | class SessionGuard extends StatefulWidget {
0008 |   const SessionGuard({super.key, required this.child});
0009 |   final Widget child;
0010 |   @override
0011 |   State<SessionGuard> createState() => _SessionGuardState();
0012 | }
0013 |
0014 | class _SessionGuardState extends State<SessionGuard>
0015 |     with WidgetsBindingObserver {
0016 |   Timer? timer;
0017 |   @override
0018 |   void initState() {
0019 |     super.initState();
0020 |     WidgetsBinding.instance.addObserver(this);
0021 |     timer = Timer.periodic(const Duration(seconds: 15), (_) => check());
0022 |   }
0023 |
0024 |   void check() {
0025 |     if (!mounted) return;
0026 |     final auth = context.read<AuthProvider>();
0027 |     if (auth.authenticated &&
0028 |         DateTime.now().difference(auth.lastActivity) >
0029 |             Duration(minutes: auth.user!.isClient ? 15 : 5)) {
0030 |       auth.lock();
0031 |     }
0032 |   }
0033 |
0034 |   @override
0035 |   void didChangeAppLifecycleState(AppLifecycleState state) {
0036 |     if (state == AppLifecycleState.resumed) check();
0037 |   }
0038 |
0039 |   @override
0040 |   void dispose() {
0041 |     timer?.cancel();
0042 |     WidgetsBinding.instance.removeObserver(this);
0043 |     super.dispose();
0044 |   }
0045 |
0046 |   @override
0047 |   Widget build(BuildContext context) {
0048 |     final auth = context.watch<AuthProvider>();
0049 |     return Listener(
0050 |         onPointerDown: (_) => auth.touch(),
0051 |         onPointerMove: (_) => auth.touch(),
0052 |         child: Stack(children: [
0053 |           widget.child,
0054 |           if (auth.authenticated && auth.locked)
0055 |             const Positioned.fill(child: _UnlockScreen())
0056 |         ]));
0057 |   }
0058 | }
0059 |
0060 | class _UnlockScreen extends StatefulWidget {
0061 |   const _UnlockScreen();
0062 |   @override
0063 |   State<_UnlockScreen> createState() => _UnlockScreenState();
0064 | }
0065 |
0066 | class _UnlockScreenState extends State<_UnlockScreen> {
0067 |   final password = TextEditingController();
0068 |   String? error;
0069 |   bool busy = false;
0070 |   Future<void> deviceUnlock() async {
0071 |     setState(() {
0072 |       busy = true;
0073 |       error = null;
0074 |     });
0075 |     try {
0076 |       await context.read<AuthProvider>().unlockWithDevice();
0077 |     } catch (e) {
0078 |       if (mounted) setState(() => error = readableApiError(e));
0079 |     } finally {
0080 |       if (mounted) setState(() => busy = false);
0081 |     }
0082 |   }
0083 |
0084 |   @override
0085 |   void dispose() {
0086 |     password.dispose();
0087 |     super.dispose();
0088 |   }
0089 |
0090 |   Future<void> unlock() async {
0091 |     if (password.text.isEmpty) return;
0092 |     setState(() {
0093 |       busy = true;
0094 |       error = null;
0095 |     });
0096 |     try {
0097 |       await context.read<AuthProvider>().unlock(password.text);
0098 |     } catch (e) {
0099 |       if (mounted) setState(() => error = readableApiError(e));
0100 |     } finally {
0101 |       if (mounted) setState(() => busy = false);
0102 |     }
0103 |   }
0104 |
0105 |   @override
0106 |   Widget build(BuildContext context) => PopScope(
0107 |       canPop: false,
0108 |       child: Scaffold(
0109 |           body: SafeArea(
0110 |               child: Center(
0111 |                   child: SingleChildScrollView(
0112 |                       padding: const EdgeInsets.all(24),
0113 |                       child: ConstrainedBox(
0114 |                           constraints: const BoxConstraints(maxWidth: 420),
0115 |                           child: Column(
0116 |                               crossAxisAlignment: CrossAxisAlignment.stretch,
0117 |                               children: [
0118 |                                 const Icon(Icons.lock_outline, size: 56),
0119 |                                 const SizedBox(height: 20),
0120 |                                 Text('Your workspace is locked',
0121 |                                     style: Theme.of(context)
0122 |                                         .textTheme
0123 |                                         .headlineSmall,
0124 |                                     textAlign: TextAlign.center),
0125 |                                 const SizedBox(height: 10),
0126 |                                 const Text('Enter your password to continue.',
0127 |                                     textAlign: TextAlign.center),
0128 |                                 const SizedBox(height: 24),
0129 |                                 TextField(
0130 |                                     controller: password,
0131 |                                     obscureText: true,
0132 |                                     decoration: const InputDecoration(
0133 |                                         labelText: 'Password'),
0134 |                                     onSubmitted: (_) => busy ? null : unlock()),
0135 |                                 const SizedBox(height: 16),
0136 |                                 if (error != null)
0137 |                                   Text(error!,
0138 |                                       style: TextStyle(
0139 |                                           color: Theme.of(context)
0140 |                                               .colorScheme
0141 |                                               .error)),
0142 |                                 FilledButton(
0143 |                                     onPressed: busy ? null : unlock,
0144 |                                     child:
0145 |                                         Text(busy ? 'Unlocking…' : 'Unlock')),
0146 |                                 OutlinedButton.icon(
0147 |                                     onPressed: busy ? null : deviceUnlock,
0148 |                                     icon: const Icon(Icons.fingerprint),
0149 |                                     label: const Text(
0150 |                                         'Use fingerprint or device lock')),
0151 |                                 TextButton(
0152 |                                     onPressed: busy
0153 |                                         ? null
0154 |                                         : context.read<AuthProvider>().logout,
0155 |                                     child: const Text('Sign out instead'))
0156 |                               ])))))));
0157 | }
```

## mobile/claimlens_mobile/lib/widgets/status_chip.dart

38 lines. SHA-256: `5543a71f985b29a6e2cb62305ca17558e9eab0539a2fdea5d1b4d37b6832e179`.

Symbols: `StatusChip`: L3

```dart
0001 | import 'package:flutter/material.dart';
0002 |
0003 | class StatusChip extends StatelessWidget {
0004 |   const StatusChip({super.key, required this.status});
0005 |   final String status;
0006 |
0007 |   @override
0008 |   Widget build(BuildContext context) {
0009 |     final color = switch (status) {
0010 |       'VERIFIED' || 'APPROVED' || 'PAID' => Colors.green,
0011 |       'REVIEW_REQUIRED' ||
0012 |       'INFORMATION_REQUIRED' ||
0013 |       'PAYMENT_PENDING' =>
0014 |         Colors.orange,
0015 |       'PROCESSING_FAILED' || 'REJECTED' => Colors.red,
0016 |       'INFORMATION_RECEIVED' => Colors.teal,
0017 |       'PROCESSING' => Colors.blue,
0018 |       _ => Colors.blueGrey,
0019 |     };
0020 |     return Container(
0021 |       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
0022 |       decoration: BoxDecoration(
0023 |         color: color.withValues(alpha: .12),
0024 |         borderRadius: BorderRadius.circular(99),
0025 |       ),
0026 |       child: Text(
0027 |         status.replaceAll('_', ' '),
0028 |         style: TextStyle(
0029 |           color: Theme.of(context).brightness == Brightness.dark
0030 |               ? color.shade200
0031 |               : color.shade700,
0032 |           fontSize: 11,
0033 |           fontWeight: FontWeight.w700,
0034 |         ),
0035 |       ),
0036 |     );
0037 |   }
0038 | }
```

## mobile/claimlens_mobile/lib/widgets/workspace_form.dart

158 lines. SHA-256: `9a05bb52ae21b5212d0c98278091e62ed6153dfee763d089524c493c71a3859c`.

Symbols: `FormEntry`: L5; `_WorkspaceForm`: L37; `_WorkspaceFormState`: L52

```dart
0001 | import 'package:flutter/material.dart';
0002 | import '../services/api_client.dart';
0003 | import '../services/workspace_service.dart';
0004 |
0005 | class FormEntry {
0006 |   const FormEntry(this.keyName, this.label,
0007 |       {this.value = '',
0008 |       this.options,
0009 |       this.required = true,
0010 |       this.secret = false,
0011 |       this.lines = 1,
0012 |       this.numeric = false});
0013 |   final String keyName, label, value;
0014 |   final Map<String, String>? options;
0015 |   final bool required, secret, numeric;
0016 |   final int lines;
0017 | }
0018 |
0019 | Future<bool?> workspaceForm(BuildContext context,
0020 |         {required String title,
0021 |         required List<FormEntry> fields,
0022 |         required Future<void> Function(Map<String, String>) submit,
0023 |         String button = 'Save changes',
0024 |         String? explanation}) =>
0025 |     showModalBottomSheet<bool>(
0026 |       context: context,
0027 |       isScrollControlled: true,
0028 |       useSafeArea: true,
0029 |       builder: (_) => _WorkspaceForm(
0030 |           title: title,
0031 |           fields: fields,
0032 |           submit: submit,
0033 |           button: button,
0034 |           explanation: explanation),
0035 |     );
0036 |
0037 | class _WorkspaceForm extends StatefulWidget {
0038 |   const _WorkspaceForm(
0039 |       {required this.title,
0040 |       required this.fields,
0041 |       required this.submit,
0042 |       required this.button,
0043 |       this.explanation});
0044 |   final String title, button;
0045 |   final String? explanation;
0046 |   final List<FormEntry> fields;
0047 |   final Future<void> Function(Map<String, String>) submit;
0048 |   @override
0049 |   State<_WorkspaceForm> createState() => _WorkspaceFormState();
0050 | }
0051 |
0052 | class _WorkspaceFormState extends State<_WorkspaceForm> {
0053 |   final key = GlobalKey<FormState>();
0054 |   late final values = {
0055 |     for (final field in widget.fields) field.keyName: field.value
0056 |   };
0057 |   bool busy = false;
0058 |   String? error;
0059 |   @override
0060 |   Widget build(BuildContext context) => Padding(
0061 |         padding: EdgeInsets.fromLTRB(
0062 |             24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
0063 |         child: SingleChildScrollView(
0064 |             child: Form(
0065 |                 key: key,
0066 |                 child: Column(
0067 |                     mainAxisSize: MainAxisSize.min,
0068 |                     crossAxisAlignment: CrossAxisAlignment.stretch,
0069 |                     children: [
0070 |                       Text(widget.title,
0071 |                           style: Theme.of(context).textTheme.headlineSmall),
0072 |                       if (widget.explanation != null)
0073 |                         Padding(
0074 |                             padding: const EdgeInsets.only(top: 12),
0075 |                             child: Text(widget.explanation!)),
0076 |                       const SizedBox(height: 20),
0077 |                       for (final field in widget.fields)
0078 |                         Padding(
0079 |                             padding: const EdgeInsets.only(bottom: 16),
0080 |                             child: field.options != null
0081 |                                 ? DropdownButtonFormField<String>(
0082 |                                     isExpanded: true,
0083 |                                     initialValue:
0084 |                                         field.options!.containsKey(field.value)
0085 |                                             ? field.value
0086 |                                             : null,
0087 |                                     decoration:
0088 |                                         InputDecoration(labelText: field.label),
0089 |                                     items: field.options!.entries
0090 |                                         .map((entry) => DropdownMenuItem(
0091 |                                             value: entry.key,
0092 |                                             child: Text(entry.value,
0093 |                                                 overflow:
0094 |                                                     TextOverflow.ellipsis)))
0095 |                                         .toList(),
0096 |                                     onChanged: busy
0097 |                                         ? null
0098 |                                         : (v) =>
0099 |                                             values[field.keyName] = v ?? '',
0100 |                                     validator: (v) =>
0101 |                                         field.required && (v == null || v.isEmpty)
0102 |                                             ? 'Choose ${field.label.toLowerCase()}'
0103 |                                             : null)
0104 |                                 : TextFormField(
0105 |                                     initialValue: field.value,
0106 |                                     enabled: !busy,
0107 |                                     obscureText: field.secret,
0108 |                                     maxLines: field.secret ? 1 : field.lines,
0109 |                                     keyboardType: field.numeric ? const TextInputType.numberWithOptions(decimal: true) : null,
0110 |                                     decoration: InputDecoration(labelText: field.label),
0111 |                                     onChanged: (v) => values[field.keyName] = v,
0112 |                                     validator: (v) => field.required && (v == null || v.trim().isEmpty) ? 'Enter ${field.label.toLowerCase()}' : null)),
0113 |                       if (error != null)
0114 |                         Padding(
0115 |                             padding: const EdgeInsets.only(bottom: 16),
0116 |                             child: Text(error!,
0117 |                                 style: TextStyle(
0118 |                                     color:
0119 |                                         Theme.of(context).colorScheme.error))),
0120 |                       FilledButton(
0121 |                           onPressed: busy
0122 |                               ? null
0123 |                               : () async {
0124 |                                   if (!key.currentState!.validate()) return;
0125 |                                   setState(() {
0126 |                                     busy = true;
0127 |                                     error = null;
0128 |                                   });
0129 |                                   try {
0130 |                                     await widget.submit(values);
0131 |                                     if (context.mounted) {
0132 |                                       Navigator.pop(context, true);
0133 |                                     }
0134 |                                   } catch (exception) {
0135 |                                     if (mounted) {
0136 |                                       setState(() {
0137 |                                         busy = false;
0138 |                                         error = readableApiError(exception);
0139 |                                       });
0140 |                                     }
0141 |                                   }
0142 |                                 },
0143 |                           child: busy
0144 |                               ? const SizedBox(
0145 |                                   width: 20,
0146 |                                   height: 20,
0147 |                                   child:
0148 |                                       CircularProgressIndicator(strokeWidth: 2))
0149 |                               : Text(widget.button)),
0150 |                       TextButton(
0151 |                           onPressed: busy ? null : () => Navigator.pop(context),
0152 |                           child: const Text('Cancel')),
0153 |                     ]))),
0154 |       );
0155 | }
0156 |
0157 | Map<String, String> labelOptions(Iterable<String> values) =>
0158 |     {for (final value in values) value: friendlyLabel(value)};
```

## mobile/claimlens_mobile/pubspec.yaml

29 lines. SHA-256: `248239f6e37ecd90a892ce0f25f3c9b326e06400f5e19185d1e46d2f77bb5f2a`.

Symbols: Configuration/resource file.

```text
0001 | name: claimlens
0002 | description: ClaimLens mobile client for claim submission and review.
0003 | publish_to: none
0004 | version: 1.1.0+2
0005 |
0006 | environment:
0007 |   sdk: ">=3.4.0 <4.0.0"
0008 |
0009 | dependencies:
0010 |   flutter:
0011 |     sdk: flutter
0012 |   dio: ^5.7.0
0013 |   file_picker: ^8.1.4
0014 |   flutter_secure_storage: ^9.2.2
0015 |   http_parser: ^4.1.2
0016 |   image_picker: ^1.1.2
0017 |   intl: ^0.20.2
0018 |   provider: ^6.1.2
0019 |   firebase_core: ^5.2.0
0020 |   firebase_messaging: ^17.1.0
0021 |   local_auth: ^3.0.2
0022 |
0023 | dev_dependencies:
0024 |   flutter_test:
0025 |     sdk: flutter
0026 |   flutter_lints: ^5.0.0
0027 |
0028 | flutter:
0029 |   uses-material-design: true
```

## services/api/app/__init__.py

0 lines. SHA-256: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.

Symbols: Configuration/resource file.

```python

```

## services/api/app/backups.py

157 lines. SHA-256: `f3de010c725f97714f20584ca9697162efd436688b0649c782961c376a27668c`.

Symbols: `derive`: L23–L26; `create_backup`: L29–L55; `open_backup`: L58–L88; `main`: L91–L153

```python
0001 | """Operator-only encrypted backup and restore of Firestore application data/files.
0002 |
0003 | Passwords are entered interactively; they are never command-line arguments.
0004 | Firebase Authentication accounts remain managed by Firebase and are not exported.
0005 | """
0006 | import argparse
0007 | from getpass import getpass
0008 | import json
0009 | import os
0010 | from pathlib import Path, PurePosixPath
0011 | import secrets
0012 | import tempfile
0013 | import zipfile
0014 |
0015 | from cryptography.hazmat.primitives import hashes
0016 | from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
0017 | from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
0018 |
0019 | COLLECTIONS = ['profiles', 'claims', 'claim_documents', 'claim_extracted_fields', 'claim_processing_jobs', 'processing_queue', 'document_fingerprints', 'claim_information_requests', 'claim_appeals', 'audit_events', 'notifications', 'configuration']
0020 | MAGIC = b'CLB1'
0021 |
0022 |
0023 | def derive(password, salt):
0024 |     if len(password) < 12:
0025 |         raise ValueError('Use a backup passphrase of at least 12 characters.')
0026 |     return PBKDF2HMAC(algorithm=hashes.SHA256(), length=32, salt=salt, iterations=600_000).derive(password.encode())
0027 |
0028 |
0029 | def create_backup(root, records, project, output, password):
0030 |     root, output = Path(root), Path(output)
0031 |     salt, nonce = secrets.token_bytes(16), secrets.token_bytes(12)
0032 |     key = derive(password, salt)
0033 |     with tempfile.TemporaryFile() as temporary:
0034 |         with zipfile.ZipFile(temporary, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
0035 |             archive.writestr('database.json', json.dumps({'version': 1, 'project': project, 'collections': records}, default=str))
0036 |             for folder in ('files', 'metadata'):
0037 |                 base = root / folder
0038 |                 if base.exists():
0039 |                     for file in base.rglob('*'):
0040 |                         if file.is_file() and not file.is_symlink():
0041 |                             archive.write(file, 'storage/' + file.relative_to(root).as_posix())
0042 |             for name in ('.signing-key', '.encryption-key'):
0043 |                 if (root/name).exists():
0044 |                     archive.write(root/name, 'storage/' + name)
0045 |         temporary.seek(0)
0046 |         encryptor = Cipher(algorithms.AES(key), modes.GCM(nonce)).encryptor()
0047 |         header = MAGIC+salt+nonce
0048 |         encryptor.authenticate_additional_data(header)
0049 |         with output.open('xb') as target:
0050 |             os.chmod(output, 0o600)
0051 |             target.write(header)
0052 |             while chunk := temporary.read(1024*1024):
0053 |                 target.write(encryptor.update(chunk))
0054 |             target.write(encryptor.finalize())
0055 |             target.write(encryptor.tag)
0056 |
0057 |
0058 | def open_backup(path, password):
0059 |     temporary = tempfile.TemporaryFile()
0060 |     try:
0061 |         with Path(path).open('rb') as source:
0062 |             header = source.read(32)
0063 |             if header[:4] != MAGIC:
0064 |                 raise ValueError('This is not a ClaimLens backup.')
0065 |             source.seek(-16, 2); tag = source.read(16)
0066 |             length = source.tell()-48
0067 |             source.seek(32)
0068 |             decryptor = Cipher(algorithms.AES(derive(password, header[4:20])), modes.GCM(header[20:32], tag)).decryptor()
0069 |             decryptor.authenticate_additional_data(header)
0070 |             while length > 0:
0071 |                 chunk = source.read(min(length, 1024*1024))
0072 |                 if not chunk:
0073 |                     raise ValueError('The backup is incomplete.')
0074 |                 temporary.write(decryptor.update(chunk)); length -= len(chunk)
0075 |             temporary.write(decryptor.finalize())
0076 |         temporary.seek(0)
0077 |         archive = zipfile.ZipFile(temporary)
0078 |         for name in archive.namelist():
0079 |             path = PurePosixPath(name)
0080 |             if path.is_absolute() or '..' in path.parts or '\\' in name or ':' in name:
0081 |                 raise ValueError('Unsafe backup path.')
0082 |         manifest = json.loads(archive.read('database.json'))
0083 |         if manifest.get('version') != 1 or set(manifest.get('collections', {})) - set(COLLECTIONS):
0084 |             raise ValueError('Unsupported backup schema.')
0085 |         return temporary, archive, manifest
0086 |     except Exception:
0087 |         temporary.close()
0088 |         raise
0089 |
0090 |
0091 | def main():
0092 |     parser = argparse.ArgumentParser(description=__doc__)
0093 |     parser.add_argument('action', choices=['create', 'verify', 'restore'])
0094 |     parser.add_argument('file')
0095 |     parser.add_argument('--destination', help='A new empty directory for recovered storage.')
0096 |     parser.add_argument('--apply-database', action='store_true', help='Create missing database records; never overwrite conflicting records.')
0097 |     args = parser.parse_args()
0098 |     password = getpass('Backup passphrase: ')
0099 |     from .config import get_settings
0100 |     settings = get_settings()
0101 |     if args.action == 'create':
0102 |         if password != getpass('Confirm backup passphrase: '):
0103 |             raise ValueError('Passphrases do not match.')
0104 |         from .firebase import firebase_app
0105 |         from firebase_admin import firestore
0106 |         db = firestore.client(firebase_app())
0107 |         records = {name: {row.id: row.to_dict() for row in db.collection(name).stream()} for name in COLLECTIONS}
0108 |         create_backup(settings.document_storage_path, records, settings.firebase_project_id, args.file, password)
0109 |         print('Encrypted backup created. Keep the passphrase separately and verify the backup before relying on it.')
0110 |         return
0111 |     temporary, archive, manifest = open_backup(args.file, password)
0112 |     try:
0113 |         print('Backup verified:', sum(len(rows) for rows in manifest['collections'].values()), 'database records.')
0114 |         if args.action != 'restore':
0115 |             return
0116 |         if not args.destination:
0117 |             raise ValueError('Supply --destination with a new empty storage directory.')
0118 |         destination = Path(args.destination).resolve()
0119 |         if destination.exists() and any(destination.iterdir()):
0120 |             raise ValueError('The recovery destination must be empty.')
0121 |         if manifest['project'] != settings.firebase_project_id:
0122 |             raise ValueError('The backup belongs to a different Firebase project.')
0123 |         db = None
0124 |         if args.apply_database:
0125 |             from .firebase import firebase_app
0126 |             from firebase_admin import firestore
0127 |             db = firestore.client(firebase_app())
0128 |             for name, rows in manifest['collections'].items():
0129 |                 for identifier, record in rows.items():
0130 |                     existing = db.collection(name).document(identifier).get()
0131 |                     if existing.exists and existing.to_dict() != record:
0132 |                         raise ValueError('Conflicting database records exist. Restore into an empty recovery project or resolve conflicts first.')
0133 |         destination.mkdir(parents=True, exist_ok=True, mode=0o700)
0134 |         for name in archive.namelist():
0135 |             if name.startswith('storage/'):
0136 |                 target = destination.joinpath(*PurePosixPath(name).parts[1:])
0137 |                 target.parent.mkdir(parents=True, exist_ok=True)
0138 |                 with target.open('xb') as output:
0139 |                     os.chmod(target, 0o600)
0140 |                     with archive.open(name) as source:
0141 |                         while chunk := source.read(1024*1024):
0142 |                             output.write(chunk)
0143 |         if db:
0144 |             from google.api_core.exceptions import AlreadyExists
0145 |             for name, rows in manifest['collections'].items():
0146 |                 for identifier, record in rows.items():
0147 |                     try:
0148 |                         db.collection(name).document(identifier).create(record)
0149 |                     except AlreadyExists:
0150 |                         pass
0151 |         print('Recovery files written. Point DOCUMENT_STORAGE_PATH to the recovered directory after verification. Firebase Authentication accounts are not restored by this command.')
0152 |     finally:
0153 |         archive.close(); temporary.close()
0154 |
0155 |
0156 | if __name__ == '__main__':
0157 |     main()
```

## services/api/app/config.py

41 lines. SHA-256: `0c5109287eabe5ae32c0eec6cc95f4f885265322064f4aeaad13c86891647434`.

Symbols: `Settings`: L15–L36; `get_settings`: L40–L41; `cors_origins`: L33–L36

```python
0001 | from __future__ import annotations
0002 |
0003 | import os
0004 | from dataclasses import dataclass
0005 | from functools import lru_cache
0006 | from pathlib import Path
0007 |
0008 | from dotenv import load_dotenv
0009 |
0010 |
0011 | load_dotenv(Path(__file__).resolve().parents[1] / ".env", encoding="utf-8-sig")
0012 |
0013 |
0014 | @dataclass(frozen=True)
0015 | class Settings:
0016 |     firebase_project_id: str = os.getenv("FIREBASE_PROJECT_ID", "claimelens")
0017 |     firebase_api_key: str = os.getenv("FIREBASE_API_KEY", "")
0018 |     firebase_credentials: str = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")
0019 |     document_storage_path: str = os.getenv(
0020 |         "DOCUMENT_STORAGE_PATH",
0021 |         str(
0022 |             Path(os.getenv("LOCALAPPDATA", str(Path.home() / ".local/share")))
0023 |             / "claimelens/documents"
0024 |         ),
0025 |     )
0026 |     public_api_url: str = os.getenv("PUBLIC_API_URL", "http://127.0.0.1:8000")
0027 |     max_file_bytes: int = int(os.getenv("MAX_UPLOAD_BYTES", str(10 * 1024 * 1024)))
0028 |     max_claim_documents: int = int(os.getenv("MAX_CLAIM_DOCUMENTS", "10"))
0029 |     paddle_device: str = os.getenv("PADDLE_DEVICE", "cpu")
0030 |     cors_origins_raw: str = os.getenv("CORS_ORIGINS", "http://localhost:3000")
0031 |
0032 |     @property
0033 |     def cors_origins(self) -> list[str]:
0034 |         return [
0035 |             value.strip() for value in self.cors_origins_raw.split(",") if value.strip()
0036 |         ]
0037 |
0038 |
0039 | @lru_cache
0040 | def get_settings() -> Settings:
0041 |     return Settings()
```

## services/api/app/documents.py

175 lines. SHA-256: `a2b985858da82c0b6b942bc2c4f6e1e21eaf6406ef2e4a61c9a058ac0ae8ee6b`.

Symbols: `LocalDocuments`: L26–L154; `document_store`: L157–L159; `download_document`: L163–L175; `__init__`: L27–L29; `file`: L31–L42; `_metadata`: L44–L49; `_cipher`: L51–L65; `_key`: L67–L77; `upload`: L79–L94; `download`: L96–L110; `delete`: L112–L114; `_signature`: L116–L119; `signed_url`: L121–L135; `verify`: L137–L154

```python
0001 | """Private local document storage for the no-billing development setup."""
0002 |
0003 | from __future__ import annotations
0004 |
0005 | import base64
0006 | import hashlib
0007 | import hmac
0008 | import json
0009 | import os
0010 | from pathlib import Path
0011 | import secrets
0012 | from threading import Lock
0013 | import time
0014 | from urllib.parse import urlencode, quote
0015 |
0016 | from fastapi import APIRouter, HTTPException
0017 | from fastapi.responses import Response
0018 | from cryptography.fernet import Fernet, InvalidToken
0019 |
0020 | from .config import get_settings
0021 |
0022 | _key_lock = Lock()
0023 | router = APIRouter(prefix="/documents", tags=["documents"])
0024 |
0025 |
0026 | class LocalDocuments:
0027 |     def __init__(self, root: str | Path, public_api_url: str):
0028 |         self.root = Path(root).resolve()
0029 |         self.public_api_url = public_api_url.rstrip("/")
0030 |
0031 |     def file(self, path: str) -> Path:
0032 |         # Storage paths are constructed by the API as uid/claim-id/random-name.
0033 |         parts = path.split("/")
0034 |         if len(parts) != 3 or any(
0035 |             p in {"", ".", ".."} or "\\" in p or ":" in p for p in parts
0036 |         ):
0037 |             raise HTTPException(403, "Invalid document link.")
0038 |         base = (self.root / "files").resolve()
0039 |         target = base.joinpath(*parts).resolve()
0040 |         if not target.is_relative_to(base):
0041 |             raise HTTPException(403, "Invalid document link.")
0042 |         return target
0043 |
0044 |     def _metadata(self, path: str) -> Path:
0045 |         return (
0046 |             self.root
0047 |             / "metadata"
0048 |             / (hashlib.sha256(path.encode()).hexdigest() + ".json")
0049 |         )
0050 |
0051 |     def _cipher(self):
0052 |         key = os.getenv("DOCUMENT_ENCRYPTION_KEY")
0053 |         if key:
0054 |             return Fernet(key.encode())
0055 |         with _key_lock:
0056 |             self.root.mkdir(parents=True, exist_ok=True)
0057 |             path = self.root / ".encryption-key"
0058 |             try:
0059 |                 descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
0060 |             except FileExistsError:
0061 |                 pass
0062 |             else:
0063 |                 with os.fdopen(descriptor, "wb") as stream:
0064 |                     stream.write(Fernet.generate_key())
0065 |             return Fernet(path.read_bytes())
0066 |
0067 |     def _key(self) -> bytes:
0068 |         with _key_lock:
0069 |             self.root.mkdir(parents=True, exist_ok=True)
0070 |             key_path = self.root / ".signing-key"
0071 |             if not key_path.exists():
0072 |                 descriptor = os.open(
0073 |                     key_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600
0074 |                 )
0075 |                 with os.fdopen(descriptor, "wb") as stream:
0076 |                     stream.write(secrets.token_bytes(32))
0077 |             return key_path.read_bytes()
0078 |
0079 |     def upload(self, path: str, content: bytes, content_type: str):
0080 |         target = self.file(path)
0081 |         target.parent.mkdir(parents=True, exist_ok=True)
0082 |         encrypted = self._cipher().encrypt(content)
0083 |         with target.open("xb") as stream:
0084 |             stream.write(encrypted)
0085 |         metadata = self._metadata(path)
0086 |         metadata.parent.mkdir(parents=True, exist_ok=True)
0087 |         try:
0088 |             metadata.write_text(
0089 |                 json.dumps({"content_type": content_type, "encrypted": True}),
0090 |                 encoding="utf-8",
0091 |             )
0092 |         except Exception:
0093 |             target.unlink(missing_ok=True)
0094 |             raise
0095 |
0096 |     def download(self, path: str) -> bytes:
0097 |         target = self.file(path)
0098 |         if not target.is_file():
0099 |             raise HTTPException(404, "Document not found on this API server.")
0100 |         content = target.read_bytes()
0101 |         metadata = json.loads(self._metadata(path).read_text(encoding="utf-8"))
0102 |         if metadata.get("encrypted"):
0103 |             try:
0104 |                 return self._cipher().decrypt(content)
0105 |             except InvalidToken:
0106 |                 raise HTTPException(
0107 |                     503,
0108 |                     "The document cannot be decrypted. Contact your administrator to check the storage key.",
0109 |                 )
0110 |         return content
0111 |
0112 |     def delete(self, path: str):
0113 |         self.file(path).unlink(missing_ok=True)
0114 |         self._metadata(path).unlink(missing_ok=True)
0115 |
0116 |     def _signature(self, path: str, expires: int) -> str:
0117 |         return hmac.new(
0118 |             self._key(), f"{path}\n{expires}".encode(), hashlib.sha256
0119 |         ).hexdigest()
0120 |
0121 |     def signed_url(self, path: str, expires_in: int = 300) -> str:
0122 |         self.file(path)
0123 |         expires = int(time.time()) + min(300, max(1, expires_in))
0124 |         encoded = base64.urlsafe_b64encode(path.encode()).decode()
0125 |         return (
0126 |             self.public_api_url
0127 |             + "/api/v1/documents/download?"
0128 |             + urlencode(
0129 |                 {
0130 |                     "document": encoded,
0131 |                     "expires": expires,
0132 |                     "signature": self._signature(path, expires),
0133 |                 }
0134 |             )
0135 |         )
0136 |
0137 |     def verify(self, document: str, expires: int, signature: str) -> tuple[Path, str]:
0138 |         try:
0139 |             path = base64.b64decode(
0140 |                 document.encode(), altchars=b"-_", validate=True
0141 |             ).decode()
0142 |         except (ValueError, UnicodeError):
0143 |             raise HTTPException(403, "Invalid document link.")
0144 |         if expires < time.time() or not hmac.compare_digest(
0145 |             self._signature(path, expires), signature
0146 |         ):
0147 |             raise HTTPException(
0148 |                 403, "Document link has expired or is invalid. Open the claim again."
0149 |             )
0150 |         target = self.file(path)
0151 |         if not target.is_file():
0152 |             raise HTTPException(404, "Document not found on this API server.")
0153 |         metadata = json.loads(self._metadata(path).read_text(encoding="utf-8"))
0154 |         return target, metadata["content_type"]
0155 |
0156 |
0157 | def document_store():
0158 |     settings = get_settings()
0159 |     return LocalDocuments(settings.document_storage_path, settings.public_api_url)
0160 |
0161 |
0162 | @router.get("/download")
0163 | def download_document(document: str, expires: int, signature: str):
0164 |     store = document_store()
0165 |     target, content_type = store.verify(document, expires, signature)
0166 |     path = target.relative_to(store.root / "files").as_posix()
0167 |     return Response(
0168 |         store.download(path),
0169 |         media_type=content_type,
0170 |         headers={
0171 |             "Cache-Control": "private, no-store",
0172 |             "X-Content-Type-Options": "nosniff",
0173 |             "Content-Disposition": "attachment; filename*=UTF-8''" + quote(target.name),
0174 |         },
0175 |     )
```

## services/api/app/extraction.py

331 lines. SHA-256: `00cc3d86e352443360916863a016a72794e1985d5502b4a2702ee28eeb42693e`.

Symbols: `TextDocument`: L9–L13; `ExtractedValue`: L17–L24; `classify_document`: L149–L153; `normalize_money`: L156–L168; `detected_currency`: L171–L185; `after_label`: L188–L197; `provider_from_heading`: L200–L232; `ranked_amount`: L235–L266; `extract_fields`: L269–L331

```python
0001 | from __future__ import annotations
0002 |
0003 | import re
0004 | from dataclasses import dataclass
0005 | from decimal import Decimal, InvalidOperation
0006 |
0007 |
0008 | @dataclass(frozen=True)
0009 | class TextDocument:
0010 |     document_id: str
0011 |     text: str
0012 |     method: str = "pdf_text"
0013 |     source_confidence: float = 1.0
0014 |
0015 |
0016 | @dataclass(frozen=True)
0017 | class ExtractedValue:
0018 |     field_name: str
0019 |     raw_value: str
0020 |     normalized_value: str
0021 |     confidence: float
0022 |     extraction_method: str
0023 |     document_id: str
0024 |     page_number: int = 1
0025 |
0026 |
0027 | DOCUMENT_RULES = (
0028 |     (
0029 |         "PHARMACY_RECEIPT",
0030 |         re.compile(
0031 |             r"\b(pharmacy|chemist|dispensary)\b[\s\S]{0,500}\b(receipt|total|paid|amount)\b",
0032 |             re.I,
0033 |         ),
0034 |         0.91,
0035 |         True,
0036 |     ),
0037 |     ("INVOICE", re.compile(r"\b(invoice|facture|bill)\b", re.I), 0.94, True),
0038 |     (
0039 |         "RECEIPT",
0040 |         re.compile(r"\b(receipt|received\s+with\s+thanks|paid)\b", re.I),
0041 |         0.92,
0042 |         True,
0043 |     ),
0044 |     (
0045 |         "PRESCRIPTION",
0046 |         re.compile(r"\b(prescription|rx|prescribed)\b", re.I),
0047 |         0.88,
0048 |         False,
0049 |     ),
0050 |     (
0051 |         "MEDICAL_CERTIFICATE",
0052 |         re.compile(r"\bmedical\s+certificate|unfit\s+for\s+work|sick\s+leave\b", re.I),
0053 |         0.94,
0054 |         False,
0055 |     ),
0056 |     (
0057 |         "CLAIM_FORM",
0058 |         re.compile(
0059 |             r"\bclaim\s+(?:form|number|details)|policy\s+number|amount\s+claimed\b",
0060 |             re.I,
0061 |         ),
0062 |         0.89,
0063 |         False,
0064 |     ),
0065 |     (
0066 |         "MEDICAL_MEMO",
0067 |         re.compile(
0068 |             r"\b(medical\s+(?:memo|report|note)|treatment\s+note|consultation)\b", re.I
0069 |         ),
0070 |         0.82,
0071 |         True,
0072 |     ),
0073 | )
0074 |
0075 | FIELD_SPECS = (
0076 |     (
0077 |         "patient_name",
0078 |         (
0079 |             "Patient / Patient(e)",
0080 |             "Patient name",
0081 |             "Patient(e)",
0082 |             "Patient",
0083 |             "Received with thanks from",
0084 |             "Mr/Mrs/Miss",
0085 |             "Name",
0086 |         ),
0087 |         0.96,
0088 |         False,
0089 |     ),
0090 |     (
0091 |         "member_number",
0092 |         ("Member number", "Membership number", "Insurance Member ID"),
0093 |         0.94,
0094 |         False,
0095 |     ),
0096 |     ("provider_name", ("Provider name", "Provider", "Facility"), 0.90, False),
0097 |     (
0098 |         "invoice_number",
0099 |         (
0100 |             "No. facture / Invoice No.",
0101 |             "Invoice number",
0102 |             "Invoice no.",
0103 |             "Receipt No.",
0104 |             "No.",
0105 |         ),
0106 |         0.95,
0107 |         False,
0108 |     ),
0109 |     (
0110 |         "service_date",
0111 |         ("Service date", "Date of service", "Treatment Date", "Date"),
0112 |         0.91,
0113 |         False,
0114 |     ),
0115 |     (
0116 |         "invoice_total",
0117 |         ("Invoice total", "Total amount", "Grand total", "Total"),
0118 |         0.93,
0119 |         True,
0120 |     ),
0121 |     (
0122 |         "claimed_amount",
0123 |         (
0124 |             "Claimed amount",
0125 |             "Claim amount",
0126 |             "Amount claimed",
0127 |             "Invoice total",
0128 |             "Grand total",
0129 |             "Total",
0130 |         ),
0131 |         0.92,
0132 |         True,
0133 |     ),
0134 | )
0135 |
0136 | MONEY_PATTERN = re.compile(
0137 |     r"(?:(?:\b(?:MUR|USD|EUR|GBP|UGX|KES|TZS)|Rs\.?|Shs\.?)\s*(?:\d{1,3}(?:[ ,]\d{3})+|\d+)(?:\.\d{1,2})?|(?:\d{1,3}(?:[ ,]\d{3})+|\d+)\.\d{1,2}(?:\s+(?:MUR|USD|EUR|GBP|UGX|KES|TZS)\b)?)",
0138 |     re.I,
0139 | )
0140 | TOTAL_CONTEXT = re.compile(
0141 |     r"\b(total|payable|due|reimburs(?:e|ement)|claim(?:ed)?|net\s+amount|settlement|sum\s+of\s+shillings)\b",
0142 |     re.I,
0143 | )
0144 | NON_AMOUNT_CONTEXT = re.compile(
0145 |     r"\b(date|reference|member|policy|phone|fax|balance)\b", re.I
0146 | )
0147 |
0148 |
0149 | def classify_document(text: str) -> tuple[str, float, bool]:
0150 |     for document_type, pattern, confidence, payable in DOCUMENT_RULES:
0151 |         if pattern.search(text):
0152 |             return document_type, confidence, payable
0153 |     return "SUPPORTING_DOCUMENT", 0.55, False
0154 |
0155 |
0156 | def normalize_money(raw: str | None) -> str | None:
0157 |     if not raw:
0158 |         return None
0159 |     match = re.search(
0160 |         r"(?:MUR|Rs\.?|UGX|KES|TZS|Shs\.?)?\s*([0-9][0-9, ]*(?:\.\d{1,2})?)", raw, re.I
0161 |     )
0162 |     if not match:
0163 |         return None
0164 |     try:
0165 |         amount = Decimal(match.group(1).replace(",", "").replace(" ", ""))
0166 |     except InvalidOperation:
0167 |         return None
0168 |     return f"{amount:.2f}" if amount >= 0 else None
0169 |
0170 |
0171 | def detected_currency(text: str) -> str | None:
0172 |     match = re.search(r"\bcurrenc(?:y|ies)\b\s*(?::|-)?\s*([A-Z]{3})", text, re.I)
0173 |     if match:
0174 |         return match.group(1).upper()
0175 |     if re.search(r"\bRs\.?\s*\d", text, re.I):
0176 |         return "MUR"
0177 |     if re.search(r"\bShs\.?\s*\d", text, re.I):
0178 |         if re.search(r"\b(Uganda|Kampala|Kayunga)\b|\+?256\b", text, re.I):
0179 |             return "UGX"
0180 |         if re.search(r"\b(Kenya|Nairobi)\b|\+?254\b", text, re.I):
0181 |             return "KES"
0182 |         if re.search(r"\b(Tanzania|Dar\s+es\s+Salaam)\b|\+?255\b", text, re.I):
0183 |             return "TZS"
0184 |     match = re.search(r"\b(MUR|USD|EUR|GBP|UGX|KES|TZS)\b", text, re.I)
0185 |     return match.group(1).upper() if match else None
0186 |
0187 |
0188 | def after_label(text: str, labels: tuple[str, ...]) -> str | None:
0189 |     for label in labels:
0190 |         pattern = re.compile(
0191 |             rf"(?:^|\n)\s*{re.escape(label)}\s*(?::|-|\.{{2,}})?\s*(?:\n\s*)?([^\n]+)",
0192 |             re.I | re.M,
0193 |         )
0194 |         match = pattern.search(text)
0195 |         if match and match.group(1).strip():
0196 |             return match.group(1).strip()
0197 |     return None
0198 |
0199 |
0200 | def provider_from_heading(text: str) -> str | None:
0201 |     lines = [line.strip() for line in text.splitlines() if line.strip()]
0202 |     for line in lines:
0203 |         match = re.search(r"\bFor\s*:\s*(.+)$", line, re.I)
0204 |         if match:
0205 |             return match.group(1).strip()
0206 |     title_index = next(
0207 |         (
0208 |             i
0209 |             for i, line in enumerate(lines)
0210 |             if re.search(
0211 |                 r"\b(invoice|facture|receipt|claim\s+form|medical\s+certificate)\b",
0212 |                 line,
0213 |                 re.I,
0214 |             )
0215 |         ),
0216 |         min(len(lines), 6),
0217 |     )
0218 |     excluded = re.compile(
0219 |         r"\b(address|street|road|tel|phone|fax|email|brn|date|patient|member|invoice|payment|cash|cheque|balance|thanks|sign)\b",
0220 |         re.I,
0221 |     )
0222 |     return next(
0223 |         (
0224 |             line
0225 |             for line in lines[:title_index]
0226 |             if 3 <= len(line) <= 120
0227 |             and re.search(r"[a-z]{3}", line, re.I)
0228 |             and not excluded.search(line)
0229 |             and not line[0].isdigit()
0230 |         ),
0231 |         None,
0232 |     )
0233 |
0234 |
0235 | def ranked_amount(doc: TextDocument) -> tuple[str, str, int] | None:
0236 |     lines = [line.strip() for line in doc.text.splitlines() if line.strip()]
0237 |     values: list[tuple[str, str, int]] = []
0238 |     for index, line in enumerate(lines):
0239 |         for match in MONEY_PATTERN.finditer(line):
0240 |             raw = match.group(0).strip()
0241 |             normalized = normalize_money(raw)
0242 |             if not normalized:
0243 |                 continue
0244 |             context = " ".join(lines[max(0, index - 2) : index + 2])
0245 |             score = (
0246 |                 2
0247 |                 + (5 if TOTAL_CONTEXT.search(context) else 0)
0248 |                 + (3 if re.search(r"\btotal\b", context, re.I) else 0)
0249 |             )
0250 |             score += 2 if re.search(r"\b[A-Z]{3}\b", raw) else 0
0251 |             score += 1 if index >= int(len(lines) * 0.6) else 0
0252 |             score -= (
0253 |                 4
0254 |                 if NON_AMOUNT_CONTEXT.search(context)
0255 |                 and not TOTAL_CONTEXT.search(context)
0256 |                 else 0
0257 |             )
0258 |             values.append((raw, normalized, score))
0259 |     if not values:
0260 |         return None
0261 |     largest = max(Decimal(item[1]) for item in values)
0262 |     values = [
0263 |         (raw, value, score + (2 if Decimal(value) == largest else 0))
0264 |         for raw, value, score in values
0265 |     ]
0266 |     return max(values, key=lambda item: (item[2], Decimal(item[1])))
0267 |
0268 |
0269 | def extract_fields(
0270 |     doc: TextDocument,
0271 | ) -> tuple[list[ExtractedValue], str | None, str | None, int]:
0272 |     fields: list[ExtractedValue] = []
0273 |     for name, labels, confidence, monetary in FIELD_SPECS:
0274 |         raw = after_label(doc.text, labels)
0275 |         normalized = normalize_money(raw) if monetary else raw
0276 |         if raw and normalized:
0277 |             fields.append(
0278 |                 ExtractedValue(
0279 |                     name,
0280 |                     raw,
0281 |                     normalized,
0282 |                     min(confidence, doc.source_confidence),
0283 |                     f"{doc.method}_label_rule",
0284 |                     doc.document_id,
0285 |                 )
0286 |             )
0287 |     if not any(field.field_name == "provider_name" for field in fields):
0288 |         raw = provider_from_heading(doc.text)
0289 |         if raw:
0290 |             fields.append(
0291 |                 ExtractedValue(
0292 |                     "provider_name",
0293 |                     raw,
0294 |                     raw,
0295 |                     min(0.88, doc.source_confidence),
0296 |                     f"{doc.method}_heading_rule",
0297 |                     doc.document_id,
0298 |                 )
0299 |             )
0300 |     if not any(field.field_name == "claimed_amount" for field in fields):
0301 |         candidate = ranked_amount(doc)
0302 |         if candidate and candidate[2] >= 4:
0303 |             raw, normalized, score = candidate
0304 |             fields.append(
0305 |                 ExtractedValue(
0306 |                     "claimed_amount",
0307 |                     raw,
0308 |                     normalized,
0309 |                     min(0.94, 0.70 + score * 0.02, doc.source_confidence),
0310 |                     f"{doc.method}_ranked_monetary_candidate",
0311 |                     doc.document_id,
0312 |                 )
0313 |             )
0314 |     claimed = next(
0315 |         (
0316 |             field.normalized_value
0317 |             for field in fields
0318 |             if field.field_name == "claimed_amount"
0319 |         ),
0320 |         None,
0321 |     )
0322 |     invoice = next(
0323 |         (
0324 |             field.normalized_value
0325 |             for field in fields
0326 |             if field.field_name == "invoice_total"
0327 |         ),
0328 |         None,
0329 |     )
0330 |     warnings = 1 if claimed and invoice and claimed != invoice else 0
0331 |     return fields, claimed, detected_currency(doc.text), warnings
```

## services/api/app/firebase.py

504 lines. SHA-256: `73741e2c82b336873fce95a6cd1893df1075e66cc34bb9d145a7e8093297898b`.

Symbols: `firebase_app`: L22–L31; `now`: L34–L35; `can_access_claim`: L38–L48; `FirebaseGateway`: L51–L504; `__init__`: L52–L56; `_user`: L58–L61; `profile`: L63–L67; `ensure_profile`: L69–L91; `records`: L93–L252; `upload`: L254–L257; `download`: L259–L260; `delete_objects`: L262–L266; `signed_url`: L268–L270; `acquire_processing`: L272–L288; `reserve_draft_deletion`: L290–L301; `confirm`: L303–L504; `ensure`: L75–L89; `run`: L112–L250; `acquire`: L277–L286; `reserve`: L294–L300; `confirm`: L313–L502

```python
0001 | """Firebase Admin persistence. Client authorization is enforced here and in routes."""
0002 |
0003 | from __future__ import annotations
0004 |
0005 | import asyncio
0006 | from datetime import datetime, timezone
0007 | from decimal import Decimal
0008 | from functools import lru_cache
0009 | import uuid
0010 | import hashlib
0011 | from google.api_core.exceptions import AlreadyExists
0012 |
0013 | from fastapi import HTTPException
0014 | from firebase_admin import credentials, firestore, initialize_app
0015 | from google.cloud.firestore_v1.base_query import FieldFilter
0016 |
0017 | from .config import get_settings
0018 | from .documents import document_store
0019 |
0020 |
0021 | @lru_cache
0022 | def firebase_app():
0023 |     settings = get_settings()
0024 |     credential = (
0025 |         credentials.Certificate(settings.firebase_credentials)
0026 |         if settings.firebase_credentials
0027 |         else credentials.ApplicationDefault()
0028 |     )
0029 |     return initialize_app(
0030 |         credential, {"projectId": settings.firebase_project_id}, name="claimelens"
0031 |     )
0032 |
0033 |
0034 | def now():
0035 |     return datetime.now(timezone.utc).isoformat()
0036 |
0037 |
0038 | def can_access_claim(user, claim):
0039 |     if user.profile.role == "client":
0040 |         return claim.get("client_id") == user.id
0041 |     if user.profile.role == "claims_officer":
0042 |         return claim.get("assigned_to") == user.id or (
0043 |             claim.get("assigned_to") is None
0044 |             and claim.get("status") in {"REVIEW_REQUIRED", "INFORMATION_RECEIVED"}
0045 |         )
0046 |     if user.profile.role == "finance":
0047 |         return claim.get("status") in {"APPROVED", "PAYMENT_PENDING", "PAID"}
0048 |     return user.profile.role in {"supervisor", "administrator"}
0049 |
0050 |
0051 | class FirebaseGateway:
0052 |     def __init__(self, request):
0053 |         self.settings = get_settings()
0054 |         self.app = firebase_app()
0055 |         self.db = firestore.client(self.app)
0056 |         self.user = getattr(request.state, "current_user", None)
0057 |
0058 |     def _user(self):
0059 |         if self.user is None:
0060 |             raise HTTPException(401, "Authentication required.")
0061 |         return self.user
0062 |
0063 |     async def profile(self, uid):
0064 |         snapshot = await asyncio.to_thread(
0065 |             self.db.collection("profiles").document(uid).get
0066 |         )
0067 |         return snapshot.to_dict() if snapshot.exists else None
0068 |
0069 |     async def ensure_profile(
0070 |         self, uid, display_name, email, *, verification_required=False
0071 |     ):
0072 |         ref = self.db.collection("profiles").document(uid)
0073 |
0074 |         @firestore.transactional
0075 |         def ensure(transaction):
0076 |             snapshot = ref.get(transaction=transaction)
0077 |             if snapshot.exists:
0078 |                 return snapshot.to_dict()
0079 |             value = {
0080 |                 "id": uid,
0081 |                 "display_name": display_name or email.split("@")[0],
0082 |                 "email": email,
0083 |                 "role": "client",
0084 |                 "status": "active",
0085 |                 "created_at": now(),
0086 |                 "verification_required": verification_required,
0087 |             }
0088 |             transaction.set(ref, value)
0089 |             return value
0090 |
0091 |         return await asyncio.to_thread(ensure, self.db.transaction())
0092 |
0093 |     async def records(
0094 |         self, method, collection, *, service=False, params=None, json=None
0095 |     ):
0096 |         """Small internal CRUD interface used by the processing pipeline.
0097 |
0098 |         Filter expressions are generated by server code, never accepted from HTTP.
0099 |         Unprivileged requests are always scoped to their authenticated claim owner.
0100 |         """
0101 |         if collection not in {
0102 |             "claims",
0103 |             "claim_documents",
0104 |             "claim_extracted_fields",
0105 |             "claim_processing_jobs",
0106 |             "audit_events",
0107 |         }:
0108 |             raise ValueError("Unsupported collection")
0109 |         user = None if service else self._user()
0110 |         params = params or {}
0111 |
0112 |         def run():
0113 |             query = self.db.collection(collection)
0114 |             for key, expression in params.items():
0115 |                 if key in {"order", "limit", "or"}:
0116 |                     continue
0117 |                 operator, value = expression.split(".", 1)
0118 |                 if operator == "eq":
0119 |                     query = query.where(filter=FieldFilter(key, "==", value))
0120 |                 elif operator == "in":
0121 |                     query = query.where(
0122 |                         filter=FieldFilter(key, "in", value.strip("()").split(","))
0123 |                     )
0124 |                 else:
0125 |                     raise ValueError("Unsupported internal filter")
0126 |             # Scope the database query before reading client documents.
0127 |             if user and collection == "claims":
0128 |                 if user.profile.role == "client":
0129 |                     query = query.where(filter=FieldFilter("client_id", "==", user.id))
0130 |             if user and collection != "claims":
0131 |                 claim_id = params.get("claim_id") or (
0132 |                     json.get("claim_id") if isinstance(json, dict) else None
0133 |                 )
0134 |                 if isinstance(claim_id, str) and claim_id.startswith("eq."):
0135 |                     claim_id = claim_id[3:]
0136 |                 parent = (
0137 |                     self.db.collection("claims").document(claim_id).get()
0138 |                     if claim_id
0139 |                     else None
0140 |                 )
0141 |                 if (
0142 |                     not parent
0143 |                     or not parent.exists
0144 |                     or not can_access_claim(user, parent.to_dict())
0145 |                 ):
0146 |                     raise HTTPException(404, "Claim not found.")
0147 |             if method == "POST":
0148 |                 if user and collection not in {
0149 |                     "claims",
0150 |                     "claim_documents",
0151 |                     "audit_events",
0152 |                 }:
0153 |                     raise HTTPException(403, "Operation not permitted.")
0154 |                 items = json if isinstance(json, list) else [json]
0155 |                 result = []
0156 |                 for item in items:
0157 |                     item = dict(item)
0158 |                     identifier = str(uuid.uuid4())
0159 |                     if collection == "claims" and item.get("request_key") and user:
0160 |                         identifier = str(
0161 |                             uuid.UUID(
0162 |                                 hashlib.sha256(
0163 |                                     (user.id + ":" + item["request_key"]).encode()
0164 |                                 ).hexdigest()[:32]
0165 |                             )
0166 |                         )
0167 |                     item.update(id=identifier, created_at=now())
0168 |                     if collection == "claims":
0169 |                         if user and (
0170 |                             user.profile.role != "client"
0171 |                             or item.get("client_id") != user.id
0172 |                         ):
0173 |                             raise HTTPException(
0174 |                                 403, "Only clients can create their own claims."
0175 |                             )
0176 |                         item.update(
0177 |                             reference="CLM-"
0178 |                             + datetime.now(timezone.utc).strftime("%Y%m%d")
0179 |                             + "-"
0180 |                             + identifier[:8].upper(),
0181 |                             warning_count=0,
0182 |                             claimed_amount=None,
0183 |                             assigned_to=None,
0184 |                         )
0185 |                     if collection == "claim_documents":
0186 |                         item.update(extraction_status="PENDING", include_in_total=False)
0187 |                     ref = self.db.collection(collection).document(identifier)
0188 |                     try:
0189 |                         ref.create(item)
0190 |                     except AlreadyExists:
0191 |                         if collection != "claims" or not item.get("request_key"):
0192 |                             raise
0193 |                         existing = ref.get().to_dict()
0194 |                         if not existing or existing.get("client_id") != user.id:
0195 |                             raise HTTPException(409, "Upload conflict. Please retry.")
0196 |                         return [{**existing, "_reused": True}]
0197 |                     result.append(item)
0198 |                 return result
0199 |             rows = [s.to_dict() for s in query.stream()]
0200 |             if user and collection == "claims":
0201 |                 rows = [row for row in rows if can_access_claim(user, row)]
0202 |             if "or" in params:
0203 |                 term = params["or"].split("*")[1].lower()
0204 |                 rows = [
0205 |                     r
0206 |                     for r in rows
0207 |                     if any(
0208 |                         term in str(r.get(k, "")).lower()
0209 |                         for k in ("reference", "patient_name", "provider_name")
0210 |                     )
0211 |                 ]
0212 |             if "order" in params:
0213 |                 key, direction = params["order"].split(".")
0214 |                 rows.sort(
0215 |                     key=lambda r: str(r.get(key, "")), reverse=direction == "desc"
0216 |                 )
0217 |             if "limit" in params:
0218 |                 rows = rows[: int(params["limit"])]
0219 |             if method == "GET":
0220 |                 return rows
0221 |             if user and method != "DELETE":
0222 |                 raise HTTPException(403, "Operation not permitted.")
0223 |             for row in rows:
0224 |                 ref = self.db.collection(collection).document(row["id"])
0225 |                 if method == "PATCH":
0226 |                     ref.update(json)
0227 |                 elif method == "DELETE":
0228 |                     if user and (
0229 |                         collection != "claims"
0230 |                         or row.get("status") not in {"UPLOADED", "PROCESSING_FAILED"}
0231 |                         or row.get("client_id") != user.id
0232 |                     ):
0233 |                         raise HTTPException(403, "Operation not permitted.")
0234 |                     ref.delete()
0235 |                     if collection == "claims":
0236 |                         for child in (
0237 |                             "claim_documents",
0238 |                             "claim_extracted_fields",
0239 |                             "claim_processing_jobs",
0240 |                             "audit_events",
0241 |                         ):
0242 |                             for document in (
0243 |                                 self.db.collection(child)
0244 |                                 .where(filter=FieldFilter("claim_id", "==", row["id"]))
0245 |                                 .stream()
0246 |                             ):
0247 |                                 document.reference.delete()
0248 |                 else:
0249 |                     raise ValueError("Unsupported method")
0250 |             return rows
0251 |
0252 |         return await asyncio.to_thread(run)
0253 |
0254 |     async def upload(self, path, content, content_type):
0255 |         if not path.startswith(self._user().id + "/"):
0256 |             raise HTTPException(403, "Invalid document path.")
0257 |         await asyncio.to_thread(document_store().upload, path, content, content_type)
0258 |
0259 |     async def download(self, path):
0260 |         return await asyncio.to_thread(document_store().download, path)
0261 |
0262 |     async def delete_objects(self, paths):
0263 |         for path in paths:
0264 |             if not path.startswith(self._user().id + "/"):
0265 |                 raise HTTPException(403, "Invalid document path.")
0266 |             await asyncio.to_thread(document_store().delete, path)
0267 |
0268 |     async def signed_url(self, path, expires_in=300):
0269 |         # Called only after the claim route has authorized access to its documents.
0270 |         return await asyncio.to_thread(document_store().signed_url, path, expires_in)
0271 |
0272 |     async def acquire_processing(self, claim_id):
0273 |         user = self._user()
0274 |         ref = self.db.collection("claims").document(claim_id)
0275 |
0276 |         @firestore.transactional
0277 |         def acquire(transaction):
0278 |             snapshot = ref.get(transaction=transaction)
0279 |             claim = snapshot.to_dict() if snapshot.exists else None
0280 |             if not claim or not can_access_claim(user, claim):
0281 |                 raise HTTPException(404, "Claim not found.")
0282 |             if claim["status"] not in {"UPLOADED", "PROCESSING_FAILED"}:
0283 |                 raise HTTPException(409, "This claim is not available for processing.")
0284 |             if claim.get("upload_complete") is False:
0285 |                 raise HTTPException(409, "The document upload has not finished.")
0286 |             transaction.update(ref, {"status": "PROCESSING"})
0287 |
0288 |         await asyncio.to_thread(acquire, self.db.transaction())
0289 |
0290 |     async def reserve_draft_deletion(self, claim_id):
0291 |         user = self._user()
0292 |         ref = self.db.collection('claims').document(claim_id)
0293 |         @firestore.transactional
0294 |         def reserve(transaction):
0295 |             snapshot = ref.get(transaction=transaction)
0296 |             claim = snapshot.to_dict() if snapshot.exists else {}
0297 |             if user.profile.role != 'client' or claim.get('client_id') != user.id or claim.get('status') not in {'UPLOADED', 'PROCESSING_FAILED'} or claim.get('submitted_at') or claim.get('needs_reconfirmation'):
0298 |                 raise HTTPException(409, 'This draft is no longer available for deletion.')
0299 |             transaction.update(ref, {'status': 'DELETING'})
0300 |             return claim['status']
0301 |         return await asyncio.to_thread(reserve, self.db.transaction())
0302 |
0303 |     async def confirm(self, claim_id, payload):
0304 |         user = self._user()
0305 |         if user.profile.verification_required and not user.profile.email_verified:
0306 |             raise HTTPException(403, "Verify your email before submitting a claim.")
0307 |         from .routers.claim_tools import business_settings
0308 |
0309 |         policy = await business_settings(self)
0310 |         ref = self.db.collection("claims").document(claim_id)
0311 |
0312 |         @firestore.transactional
0313 |         def confirm(transaction):
0314 |             snapshot = ref.get(transaction=transaction)
0315 |             claim = snapshot.to_dict() if snapshot.exists else None
0316 |             if (
0317 |                 not claim
0318 |                 or claim.get("client_id") != user.id
0319 |                 or user.profile.role != "client"
0320 |             ):
0321 |                 raise HTTPException(403, "Only the claim owner can confirm this draft.")
0322 |             if claim['status'] not in {'UPLOADED', 'PROCESSING_FAILED'} or claim.get('needs_reconfirmation') or claim.get('submitted_at'):
0323 |                 raise HTTPException(
0324 |                     409, "This claim has already been submitted or is processing."
0325 |                 )
0326 |             if claim.get("upload_complete") is False:
0327 |                 raise HTTPException(409, "Wait for all documents to finish uploading.")
0328 |             docs = list(
0329 |                 self.db.collection("claim_documents")
0330 |                 .where(filter=FieldFilter("claim_id", "==", claim_id))
0331 |                 .stream(transaction=transaction)
0332 |             )
0333 |             fields = list(
0334 |                 self.db.collection("claim_extracted_fields")
0335 |                 .where(filter=FieldFilter("claim_id", "==", claim_id))
0336 |                 .stream(transaction=transaction)
0337 |             )
0338 |             watchers = [
0339 |                 snapshot.id
0340 |                 for snapshot in self.db.collection("profiles")
0341 |                 .where(
0342 |                     filter=FieldFilter(
0343 |                         "role", "in", ["claims_officer", "supervisor", "administrator"]
0344 |                     )
0345 |                 )
0346 |                 .stream(transaction=transaction)
0347 |                 if snapshot.to_dict().get("status") == "active"
0348 |             ]
0349 |             by_id = {d.id: d for d in docs}
0350 |             information = claim.get("information") or {}
0351 |             if (
0352 |                 policy["require_member_number"]
0353 |                 and not information.get("member_number", "").strip()
0354 |             ):
0355 |                 raise HTTPException(422, "Add your member number before submission.")
0356 |             if (
0357 |                 policy["require_policy_number"]
0358 |                 and not information.get("policy_number", "").strip()
0359 |             ):
0360 |                 raise HTTPException(422, "Add your policy number before submission.")
0361 |             fingerprints = []
0362 |             import hashlib
0363 |
0364 |             for item in payload.documents:
0365 |                 original = by_id.get(item.id)
0366 |                 content_hash = (
0367 |                     original.to_dict().get("content_sha256") if original else None
0368 |                 )
0369 |                 if item.include and content_hash:
0370 |                     fingerprint = self.db.collection("document_fingerprints").document(
0371 |                         hashlib.sha256(
0372 |                             (user.id + ":" + content_hash).encode()
0373 |                         ).hexdigest()
0374 |                     )
0375 |                     previous = fingerprint.get(transaction=transaction)
0376 |                     if (
0377 |                         previous.exists
0378 |                         and previous.to_dict().get("claim_id") != claim_id
0379 |                     ):
0380 |                         raise HTTPException(
0381 |                             409,
0382 |                             "This payable document was already submitted. Check your existing claims or request an appeal.",
0383 |                         )
0384 |                     fingerprints.append(fingerprint)
0385 |             field_ids = {d.id: d for d in fields}
0386 |             if len({d.id for d in payload.documents}) != len(payload.documents) or set(
0387 |                 by_id
0388 |             ) != {d.id for d in payload.documents}:
0389 |                 raise HTTPException(422, "Confirm each document exactly once.")
0390 |             updates = []
0391 |             total = Decimal("0")
0392 |             currencies = set()
0393 |             for item in payload.documents:
0394 |                 source = by_id[item.id].to_dict()
0395 |                 extracted = source.get('extracted_amount')
0396 |                 disputed = bool(item.include and extracted is not None and
0397 |                                 item.amount != Decimal(str(extracted)))
0398 |                 if item.include:
0399 |                     original = by_id[item.id].to_dict()
0400 |                     if (
0401 |                         original.get("duplicate_of")
0402 |                         or item.amount is None
0403 |                         or item.amount <= 0
0404 |                         or item.amount.as_tuple().exponent < -2
0405 |                         or not item.currency
0406 |                         or len(item.currency) != 3
0407 |                         or item.currency.upper() not in policy["allowed_currencies"]
0408 |                     ):
0409 |                         raise HTTPException(
0410 |                             422,
0411 |                             "Included documents need a positive amount, a three-letter currency, and must not be duplicates.",
0412 |                         )
0413 |                     total += item.amount
0414 |                     currencies.add(item.currency.upper())
0415 |                 updates.append(
0416 |                     (
0417 |                         by_id[item.id].reference,
0418 |                         {
0419 |                             "include_in_total": item.include,
0420 |                             "client_proposed_amount": str(item.amount) if item.include else None,
0421 |                             "client_proposed_currency": item.currency.upper() if item.include else None,
0422 |                             "client_reported_incorrect_amount": disputed,
0423 |                             "confirmed_amount": str(item.amount)
0424 |                             if item.include
0425 |                             else None,
0426 |                             "confirmed_currency": item.currency.upper()
0427 |                             if item.include
0428 |                             else None,
0429 |                         },
0430 |                     )
0431 |                 )
0432 |             if total <= 0 or len(currencies) != 1:
0433 |                 raise HTTPException(
0434 |                     422,
0435 |                     "Include at least one payable document; all amounts must use the same currency.",
0436 |                 )
0437 |             if len({str(f.id) for f in payload.fields}) != len(payload.fields):
0438 |                 raise HTTPException(422, "Duplicate corrected fields.")
0439 |             for correction in payload.fields:
0440 |                 if not correction.value.strip():
0441 |                     raise HTTPException(422, "Corrected values cannot be blank.")
0442 |                 field = field_ids.get(str(correction.id))
0443 |                 if not field:
0444 |                     raise HTTPException(
0445 |                         422, "Corrected field does not belong to this claim."
0446 |                     )
0447 |                 updates.append(
0448 |                     (
0449 |                         field.reference,
0450 |                         {
0451 |                             "normalized_value": correction.value.strip(),
0452 |                             "extraction_method": "human_corrected",
0453 |                             "confidence": 0,
0454 |                         },
0455 |                     )
0456 |                 )
0457 |                 audit = self.db.collection("audit_events").document()
0458 |                 transaction.set(
0459 |                     audit,
0460 |                     {
0461 |                         "id": audit.id,
0462 |                         "claim_id": claim_id,
0463 |                         "actor_id": user.id,
0464 |                         "event_type": "FIELD_CORRECTED",
0465 |                         "created_at": now(),
0466 |                         "metadata": {
0467 |                             "previous_value": field.to_dict().get("normalized_value"),
0468 |                             "corrected_value": correction.value.strip(),
0469 |                         },
0470 |                     },
0471 |                 )
0472 |             for target, update in updates:
0473 |                 transaction.update(target, update)
0474 |             transaction.update(
0475 |                 ref,
0476 |                 {
0477 |                     "patient_name": payload.patient_name.strip(),
0478 |                     "provider_name": payload.provider_name.strip(),
0479 |                     "claimed_amount": str(total),
0480 |                     "currency": next(iter(currencies)),
0481 |                     "status": "REVIEW_REQUIRED",
0482 |                     "submitted_at": now(),
0483 |                 },
0484 |             )
0485 |             from .workflow import write_event
0486 |
0487 |             for fingerprint in fingerprints:
0488 |                 transaction.set(
0489 |                     fingerprint,
0490 |                     {"claim_id": claim_id, "client_id": user.id, "created_at": now()},
0491 |                 )
0492 |
0493 |             write_event(
0494 |                 self.db,
0495 |                 transaction,
0496 |                 claim,
0497 |                 user.id,
0498 |                 "CLAIM_CONFIRMED",
0499 |                 {"total": str(total), "disputed_document_ids": [target.id for target, update in updates if update.get('client_reported_incorrect_amount')]},
0500 |                 watchers=watchers,
0501 |             )
0502 |             return "REVIEW_REQUIRED"
0503 |
0504 |         return await asyncio.to_thread(confirm, self.db.transaction())
```

## services/api/app/hardening.py

70 lines. SHA-256: `0c986b0a976aa570dedb2ae7643ccb53290287e0faf44b7265e7043877a666d6`.

Symbols: `consume`: L14–L33; `security_defaults`: L36–L70

```python
0001 | """Request limits and safe response defaults for the single-instance pilot API."""
0002 |
0003 | import asyncio
0004 | import hashlib
0005 | from pathlib import Path
0006 | import sqlite3
0007 | import time
0008 | import uuid
0009 | from fastapi import Request
0010 | from fastapi.responses import JSONResponse
0011 | from .config import get_settings
0012 |
0013 |
0014 | def consume(key, limit, seconds):
0015 |     path = Path(get_settings().document_storage_path) / "request-limits.sqlite3"
0016 |     path.parent.mkdir(parents=True, exist_ok=True)
0017 |     now = time.time()
0018 |     with sqlite3.connect(path, timeout=10) as connection:
0019 |         connection.execute(
0020 |             "CREATE TABLE IF NOT EXISTS limits (key TEXT PRIMARY KEY, count INTEGER, reset REAL)"
0021 |         )
0022 |         connection.execute("BEGIN IMMEDIATE")
0023 |         row = connection.execute(
0024 |             "SELECT count, reset FROM limits WHERE key=?", (key,)
0025 |         ).fetchone()
0026 |         count, reset = row if row and row[1] > now else (0, now + seconds)
0027 |         if count >= limit:
0028 |             return max(1, int(reset - now))
0029 |         connection.execute(
0030 |             "INSERT OR REPLACE INTO limits VALUES (?, ?, ?)", (key, count + 1, reset)
0031 |         )
0032 |         connection.execute("DELETE FROM limits WHERE reset < ?", (now - 3600,))
0033 |     return 0
0034 |
0035 |
0036 | async def security_defaults(request: Request, call_next):
0037 |     route = request.url.path
0038 |     request_id = uuid.uuid4().hex
0039 |     if request.method == "POST" and (
0040 |         route
0041 |         in {
0042 |             "/api/v1/auth/login",
0043 |             "/api/v1/auth/signup",
0044 |             "/api/v1/auth/forgot-password",
0045 |             "/api/v1/auth/mfa/verify",
0046 |             "/api/v1/profile/unlock",
0047 |             "/api/v1/auth/verification-email",
0048 |             "/api/v1/profile/password",
0049 |         }
0050 |         or route.endswith("/password")
0051 |     ):
0052 |         # Forwarded client headers are deliberately not trusted. Production reverse
0053 |         # proxy configuration must supply a trusted client address to the ASGI server.
0054 |         address = request.client.host if request.client else "unknown"
0055 |         key = hashlib.sha256((address + ":" + route).encode()).hexdigest()
0056 |         wait = await asyncio.to_thread(
0057 |             consume, key, 30 if route.endswith("/login") else 10, 60
0058 |         )
0059 |         if wait:
0060 |             return JSONResponse(
0061 |                 {"detail": "Too many attempts. Please wait and try again."},
0062 |                 status_code=429,
0063 |                 headers={"Retry-After": str(wait), "Cache-Control": "no-store"},
0064 |             )
0065 |     response = await call_next(request)
0066 |     response.headers["X-Request-ID"] = request_id
0067 |     response.headers["X-Content-Type-Options"] = "nosniff"
0068 |     response.headers["Referrer-Policy"] = "no-referrer"
0069 |     response.headers["Cache-Control"] = "no-store"
0070 |     return response
```

## services/api/app/jobs.py

128 lines. SHA-256: `cccfe07f870c254b019f392ff0da5222574c9aab34dceed6a5a94c300f63e925`.

Symbols: `queue_record`: L15–L23; `enqueue`: L26–L30; `take_job`: L33–L82; `heartbeat`: L85–L90; `worker_loop`: L93–L128; `acquire`: L44–L77

```python
0001 | """Durable Firestore OCR queue with leases and bounded recovery after a restart."""
0002 |
0003 | import asyncio
0004 | import logging
0005 | import secrets
0006 | import time
0007 | from types import SimpleNamespace
0008 | from firebase_admin import firestore
0009 | from google.cloud.firestore_v1.base_query import FieldFilter
0010 | from .firebase import FirebaseGateway, now
0011 |
0012 | log = logging.getLogger(__name__)
0013 |
0014 |
0015 | def queue_record(claim, actor):
0016 |     return {
0017 |         "claim_id": claim["id"],
0018 |         "actor_id": actor,
0019 |         "state": "QUEUED",
0020 |         "attempts": 0,
0021 |         "lease_until": 0,
0022 |         "created_at": now(),
0023 |     }
0024 |
0025 |
0026 | async def enqueue(gateway, claim, actor):
0027 |     await asyncio.to_thread(
0028 |         gateway.db.collection("processing_queue").document(claim["id"]).set,
0029 |         queue_record(claim, actor),
0030 |     )
0031 |
0032 |
0033 | def take_job(store, worker):
0034 |     candidates = list(
0035 |         store.db.collection("processing_queue")
0036 |         .where(filter=FieldFilter("state", "in", ["QUEUED", "RUNNING"]))
0037 |         .limit(100)
0038 |         .stream()
0039 |     )
0040 |     candidates.sort(key=lambda s: s.to_dict().get("created_at", ""))
0041 |     for candidate in candidates:
0042 |
0043 |         @firestore.transactional
0044 |         def acquire(transaction):
0045 |             record = candidate.reference.get(transaction=transaction).to_dict() or {}
0046 |             if (
0047 |                 record.get("state") not in {"QUEUED", "RUNNING"}
0048 |                 or record.get("lease_until", 0) > time.time()
0049 |             ):
0050 |                 return None
0051 |             ref = store.db.collection("claims").document(record["claim_id"])
0052 |             claim = ref.get(transaction=transaction).to_dict()
0053 |             if not claim:
0054 |                 transaction.update(candidate.reference, {"state": "CANCELLED"})
0055 |                 return None
0056 |             if claim.get("status") != "PROCESSING":
0057 |                 transaction.update(
0058 |                     candidate.reference, {"state": "CANCELLED", "finished_at": now()}
0059 |                 )
0060 |                 return None
0061 |             if record.get("attempts", 0) >= 3:
0062 |                 transaction.update(
0063 |                     candidate.reference, {"state": "FAILED", "finished_at": now()}
0064 |                 )
0065 |                 transaction.update(ref, {"status": "PROCESSING_FAILED"})
0066 |                 return None
0067 |             transaction.update(
0068 |                 candidate.reference,
0069 |                 {
0070 |                     "state": "RUNNING",
0071 |                     "worker": worker,
0072 |                     "lease_until": time.time() + 90,
0073 |                     "attempts": record.get("attempts", 0) + 1,
0074 |                 },
0075 |             )
0076 |             transaction.update(ref, {"status": "PROCESSING"})
0077 |             return {**record, "claim": claim, "reference": candidate.reference}
0078 |
0079 |         job = acquire(store.db.transaction())
0080 |         if job:
0081 |             return job
0082 |     return None
0083 |
0084 |
0085 | async def heartbeat(job):
0086 |     while True:
0087 |         await asyncio.sleep(20)
0088 |         await asyncio.to_thread(
0089 |             job["reference"].update, {"lease_until": time.time() + 90}
0090 |         )
0091 |
0092 |
0093 | async def worker_loop():
0094 |     worker = secrets.token_hex(12)
0095 |     while True:
0096 |         try:
0097 |             store = FirebaseGateway(SimpleNamespace(state=SimpleNamespace()))
0098 |             job = await asyncio.to_thread(take_job, store, worker)
0099 |             if not job:
0100 |                 await asyncio.sleep(5)
0101 |                 continue
0102 |             pulse = asyncio.create_task(heartbeat(job))
0103 |             try:
0104 |                 from .routers.claims import finish_processing
0105 |
0106 |                 await finish_processing(store, job["claim"], job["actor_id"])
0107 |                 await asyncio.to_thread(
0108 |                     job["reference"].update,
0109 |                     {"state": "COMPLETED", "lease_until": 0, "finished_at": now()},
0110 |                 )
0111 |             except asyncio.CancelledError:
0112 |                 raise
0113 |             except Exception:
0114 |                 log.exception(
0115 |                     "OCR job failed for a claim; details are available to authorized reviewers."
0116 |                 )
0117 |                 await asyncio.to_thread(
0118 |                     job["reference"].update,
0119 |                     {"state": "FAILED", "lease_until": 0, "finished_at": now()},
0120 |                 )
0121 |             finally:
0122 |                 pulse.cancel()
0123 |                 await asyncio.gather(pulse, return_exceptions=True)
0124 |         except asyncio.CancelledError:
0125 |             raise
0126 |         except Exception:
0127 |             log.exception("Processing worker unavailable; retrying.")
0128 |             await asyncio.sleep(15)
```

## services/api/app/main.py

97 lines. SHA-256: `7dc6fd15347171d0307d9c2d9d06ad300e543397f2736c88a080f30fb5676c87`.

Symbols: `lifespan`: L23–L46; `validation_error`: L59–L61; `root`: L83–L88; `health_check`: L92–L97

```python
0001 | from contextlib import asynccontextmanager
0002 | import asyncio
0003 | import os
0004 |
0005 | import httpx
0006 | from fastapi import FastAPI
0007 | from fastapi.middleware.cors import CORSMiddleware
0008 | from fastapi.exceptions import RequestValidationError
0009 | from fastapi.responses import JSONResponse
0010 |
0011 | from .config import get_settings
0012 | from .routers import auth, claims, profile, workspace
0013 | from .documents import router as documents_router
0014 | from .routers.claim_tools import router as claim_tools_router
0015 | from .push import router as push_router
0016 |
0017 |
0018 | APP_NAME = "ClaimLens API"
0019 | APP_VERSION = "1.1.0"
0020 |
0021 |
0022 | @asynccontextmanager
0023 | async def lifespan(application: FastAPI):
0024 |     application.state.http = httpx.AsyncClient(timeout=httpx.Timeout(60.0))
0025 |     from .jobs import worker_loop
0026 |
0027 |     worker = (
0028 |         asyncio.create_task(worker_loop())
0029 |         if os.getenv("PROCESSING_WORKER_ENABLED", "true").lower() == "true"
0030 |         else None
0031 |     )
0032 |     from .push import push_loop
0033 |
0034 |     push_worker = (
0035 |         asyncio.create_task(push_loop())
0036 |         if os.getenv("PUSH_WORKER_ENABLED", "true").lower() == "true"
0037 |         else None
0038 |     )
0039 |     yield
0040 |     if worker:
0041 |         worker.cancel()
0042 |         await asyncio.gather(worker, return_exceptions=True)
0043 |     if push_worker:
0044 |         push_worker.cancel()
0045 |         await asyncio.gather(push_worker, return_exceptions=True)
0046 |     await application.state.http.aclose()
0047 |
0048 |
0049 | app = FastAPI(
0050 |     title=APP_NAME,
0051 |     description="Firebase API for ClaimLens",
0052 |     version=APP_VERSION,
0053 |     lifespan=lifespan,
0054 | )
0055 |
0056 | settings = get_settings()
0057 |
0058 | @app.exception_handler(RequestValidationError)
0059 | async def validation_error(request, error):
0060 |     # Do not echo passwords, tokens or medical input in validation errors.
0061 |     return JSONResponse({'detail': [{'loc': list(item['loc']), 'msg': item['msg'], 'type': item['type']} for item in error.errors()]}, status_code=422)
0062 | from .hardening import security_defaults
0063 |
0064 | app.middleware("http")(security_defaults)
0065 | app.add_middleware(
0066 |     CORSMiddleware,
0067 |     allow_origins=settings.cors_origins,
0068 |     allow_credentials=True,
0069 |     allow_methods=["*"],
0070 |     allow_headers=["*"],
0071 | )
0072 |
0073 | app.include_router(auth.router, prefix="/api/v1")
0074 | app.include_router(profile.router, prefix="/api/v1")
0075 | app.include_router(claims.router, prefix="/api/v1")
0076 | app.include_router(documents_router, prefix="/api/v1")
0077 | app.include_router(workspace.router, prefix="/api/v1")
0078 | app.include_router(claim_tools_router, prefix="/api/v1")
0079 | app.include_router(push_router, prefix="/api/v1")
0080 |
0081 |
0082 | @app.get("/", tags=["service"])
0083 | def root() -> dict[str, str]:
0084 |     return {
0085 |         "name": APP_NAME,
0086 |         "version": APP_VERSION,
0087 |         "status": "running",
0088 |     }
0089 |
0090 |
0091 | @app.get("/api/v1/health", tags=["service"])
0092 | def health_check() -> dict[str, str]:
0093 |     return {
0094 |         "status": "healthy",
0095 |         "service": APP_NAME,
0096 |         "version": APP_VERSION,
0097 |     }
```

## services/api/app/ocr.py

54 lines. SHA-256: `690bdcec6ec672a25fa449775fd07741e427ffd6f67ac034829e69e5183e2638`.

Symbols: `_engine`: L13–L25; `extract_image`: L28–L54

```python
0001 | """Lazy, serialized PaddleOCR inference for uploaded images and rasterized PDFs."""
0002 |
0003 | from functools import lru_cache
0004 | import os
0005 | from threading import Lock
0006 |
0007 | from .config import get_settings
0008 |
0009 | _inference_lock = Lock()
0010 |
0011 |
0012 | @lru_cache(maxsize=1)
0013 | def _engine():
0014 |     # Keep text-only PDF/DOCX extraction usable without loading the OCR models.
0015 |     os.environ.setdefault("PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK", "True")
0016 |     from paddleocr import PaddleOCR
0017 |
0018 |     return PaddleOCR(
0019 |         device=get_settings().paddle_device,
0020 |         text_detection_model_name="PP-OCRv5_mobile_det",
0021 |         text_recognition_model_name="en_PP-OCRv5_mobile_rec",
0022 |         use_doc_orientation_classify=False,
0023 |         use_doc_unwarping=False,
0024 |         use_textline_orientation=False,
0025 |     )
0026 |
0027 |
0028 | def extract_image(content: bytes) -> tuple[str, str, float]:
0029 |     from PIL import Image, UnidentifiedImageError
0030 |     from io import BytesIO
0031 |
0032 |     try:
0033 |         with Image.open(BytesIO(content)) as source:
0034 |             if source.width * source.height > 25_000_000:
0035 |                 raise ValueError('This image is too large. Use an image under 25 megapixels.')
0036 |     except (UnidentifiedImageError, Image.DecompressionBombError) as exc:
0037 |         raise ValueError('The image could not be decoded. Upload a JPEG or PNG image.') from exc
0038 |     import cv2
0039 |     import numpy as np
0040 |
0041 |     image = cv2.imdecode(np.frombuffer(content, dtype=np.uint8), cv2.IMREAD_COLOR)
0042 |     if image is None:
0043 |         raise ValueError("The image could not be decoded. Upload a JPEG or PNG image.")
0044 |     # A cached Paddle predictor must not be used by concurrent processing threads.
0045 |     with _inference_lock:
0046 |         results = list(_engine().predict(image))
0047 |     lines: list[str] = []
0048 |     scores: list[float] = []
0049 |     for result in results:
0050 |         for text, score in zip(result["rec_texts"], result["rec_scores"], strict=True):
0051 |             if text.strip():
0052 |                 lines.append(text.strip())
0053 |                 scores.append(float(score))
0054 |     return "\n".join(lines), "paddleocr", sum(scores) / len(scores) if scores else 0.0
```

## services/api/app/permissions.py

41 lines. SHA-256: `c287ac90f515cad4216b062f89a7f6c7e63e3dcfc25576910186fbfe01bcb2f3`.

Symbols: `permissions`: L29–L34; `require`: L37–L41

```python
0001 | """Server-side permissions: administrative access does not imply clinical authority."""
0002 |
0003 | from fastapi import HTTPException
0004 |
0005 | PERMISSIONS = {
0006 |     "claims.review",
0007 |     "claims.assign",
0008 |     "claims.decide",
0009 |     "payments.record",
0010 |     "users.manage",
0011 |     "analytics.view",
0012 |     "audit.view",
0013 | }
0014 | DEFAULTS = {
0015 |     "client": set(),
0016 |     "claims_officer": {"claims.review", "analytics.view", "audit.view"},
0017 |     "supervisor": {
0018 |         "claims.review",
0019 |         "claims.assign",
0020 |         "claims.decide",
0021 |         "analytics.view",
0022 |         "audit.view",
0023 |     },
0024 |     "finance": {"payments.record", "analytics.view", "audit.view"},
0025 |     "administrator": {"users.manage", "claims.assign", "analytics.view", "audit.view"},
0026 | }
0027 |
0028 |
0029 | def permissions(profile):
0030 |     if profile.role == "client":
0031 |         return set()
0032 |     return DEFAULTS.get(profile.role, set()) | (
0033 |         set(getattr(profile, "permissions", [])) & PERMISSIONS
0034 |     )
0035 |
0036 |
0037 | def require(user, permission):
0038 |     if permission not in permissions(user.profile):
0039 |         raise HTTPException(
0040 |             403, "Your account does not have permission for this action."
0041 |         )
```

## services/api/app/processing.py

304 lines. SHA-256: `3fe17432c9e2f17d9821beac5ba452bbcb0277b116cf6db86085ed92d551d07d`.

Symbols: `_extract_docx`: L16–L24; `_ocr_image`: L27–L30; `_extract_pdf`: L33–L54; `extract_document_text`: L57–L67; `process_claim`: L70–L304

```python
0001 | from __future__ import annotations
0002 |
0003 | import asyncio
0004 | import hashlib
0005 | import io
0006 | from datetime import datetime, timezone
0007 | from typing import Any
0008 |
0009 | from fastapi import HTTPException
0010 |
0011 | from .extraction import TextDocument, classify_document, extract_fields
0012 | from .schemas import ProcessResult
0013 | from .firebase import FirebaseGateway
0014 |
0015 |
0016 | def _extract_docx(content: bytes) -> tuple[str, str, float]:
0017 |     from docx import Document
0018 |
0019 |     document = Document(io.BytesIO(content))
0020 |     parts = [paragraph.text for paragraph in document.paragraphs]
0021 |     for table in document.tables:
0022 |         for row in table.rows:
0023 |             parts.append("\t".join(cell.text for cell in row.cells))
0024 |     return "\n".join(value for value in parts if value.strip()), "docx_text", 0.98
0025 |
0026 |
0027 | def _ocr_image(content: bytes) -> tuple[str, str, float]:
0028 |     from .ocr import extract_image
0029 |
0030 |     return extract_image(content)
0031 |
0032 |
0033 | def _extract_pdf(content: bytes) -> tuple[str, str, float]:
0034 |     import pymupdf
0035 |
0036 |     with pymupdf.open(stream=content, filetype="pdf") as document:
0037 |         if document.needs_pass or len(document) > 30:
0038 |             raise ValueError("Use an unprotected PDF with at most 30 pages.")
0039 |         text = "\n".join(page.get_text("text") for page in document).strip()
0040 |         if len(text) >= 40:
0041 |             return text, "pdf_text", 0.99
0042 |         pages: list[str] = []
0043 |         confidences: list[float] = []
0044 |         for page in document:
0045 |             scale = min(2, 2500/max(page.rect.width, page.rect.height, 1))
0046 |             pixmap = page.get_pixmap(matrix=pymupdf.Matrix(scale, scale), alpha=False)
0047 |             page_text, _, confidence = _ocr_image(pixmap.tobytes("png"))
0048 |             pages.append(page_text)
0049 |             confidences.append(confidence)
0050 |         return (
0051 |             "\n".join(pages),
0052 |             "paddleocr",
0053 |             (sum(confidences) / len(confidences) if confidences else 0.55),
0054 |         )
0055 |
0056 |
0057 | def extract_document_text(content: bytes, mime_type: str) -> tuple[str, str, float]:
0058 |     if mime_type == "application/pdf":
0059 |         return _extract_pdf(content)
0060 |     if (
0061 |         mime_type
0062 |         == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
0063 |     ):
0064 |         return _extract_docx(content)
0065 |     if mime_type in {"image/jpeg", "image/png"}:
0066 |         return _ocr_image(content)
0067 |     raise ValueError(f"Unsupported document type: {mime_type}")
0068 |
0069 |
0070 | async def process_claim(
0071 |     gateway: FirebaseGateway,
0072 |     claim: dict[str, Any],
0073 |     actor_id: str,
0074 |     *,
0075 |     return_status: str = "UPLOADED",
0076 | ) -> ProcessResult:
0077 |     claim_id = claim["id"]
0078 |     reference = claim["reference"]
0079 |     now = datetime.now(timezone.utc).isoformat()
0080 |     jobs = await gateway.records(
0081 |         "POST",
0082 |         "claim_processing_jobs",
0083 |         service=True,
0084 |         json={
0085 |             "claim_id": claim_id,
0086 |             "created_by": actor_id,
0087 |             "status": "RUNNING",
0088 |             "attempt_count": 1,
0089 |             "started_at": now,
0090 |         },
0091 |     )
0092 |     job_id = jobs[0]["id"]
0093 |     try:
0094 |         await gateway.records(
0095 |             "PATCH",
0096 |             "claims",
0097 |             service=True,
0098 |             params={"id": f"eq.{claim_id}"},
0099 |             json={"status": "PROCESSING"},
0100 |         )
0101 |         await gateway.records(
0102 |             "POST",
0103 |             "audit_events",
0104 |             service=True,
0105 |             json={
0106 |                 "claim_id": claim_id,
0107 |                 "actor_id": actor_id,
0108 |                 "event_type": "PROCESSING_STARTED",
0109 |             },
0110 |         )
0111 |     except Exception as exc:
0112 |         error = str(exc)[:1000]
0113 |         await gateway.records(
0114 |             "PATCH",
0115 |             "claims",
0116 |             service=True,
0117 |             params={"id": f"eq.{claim_id}"},
0118 |             json={"status": "PROCESSING_FAILED"},
0119 |         )
0120 |         await gateway.records(
0121 |             "PATCH",
0122 |             "claim_processing_jobs",
0123 |             service=True,
0124 |             params={"id": f"eq.{job_id}"},
0125 |             json={
0126 |                 "status": "FAILED",
0127 |                 "last_error": error,
0128 |                 "finished_at": datetime.now(timezone.utc).isoformat(),
0129 |             },
0130 |         )
0131 |         raise HTTPException(status_code=422, detail=error) from exc
0132 |     try:
0133 |         documents = await gateway.records(
0134 |             "GET",
0135 |             "claim_documents",
0136 |             service=True,
0137 |             params={"claim_id": f"eq.{claim_id}", "order": "created_at.asc"},
0138 |         )
0139 |         additional_evidence = return_status == "INFORMATION_RECEIVED"
0140 |         if not additional_evidence:
0141 |             await gateway.records(
0142 |                 "DELETE",
0143 |                 "claim_extracted_fields",
0144 |                 service=True,
0145 |                 params={"claim_id": f"eq.{claim_id}"},
0146 |             )
0147 |         hashes: dict[str, str] = {}
0148 |         field_count = 0
0149 |         warning_count = claim.get("warning_count", 0) if additional_evidence else 0
0150 |         for document in documents:
0151 |             content = await gateway.download(document["storage_path"])
0152 |             digest = hashlib.sha256(content).hexdigest()
0153 |             duplicate_of = hashes.get(digest)
0154 |             hashes.setdefault(digest, document["id"])
0155 |             if additional_evidence and document.get("extraction_status") not in {
0156 |                 "PENDING",
0157 |                 "FAILED",
0158 |             }:
0159 |                 # Previously reviewed evidence and human corrections must survive
0160 |                 # a response containing additional documents.
0161 |                 continue
0162 |             try:
0163 |                 text, method, confidence = await asyncio.to_thread(
0164 |                     extract_document_text, content, document["mime_type"]
0165 |                 )
0166 |                 if not text.strip():
0167 |                     raise ValueError(
0168 |                         "No readable text was found. Upload a clearer image or enter the values manually."
0169 |                     )
0170 |                 document_type, _, payable = classify_document(text)
0171 |                 fields, amount, currency, warnings = extract_fields(
0172 |                     TextDocument(document["id"], text, method, confidence)
0173 |                 )
0174 |                 warning_count += warnings + (1 if duplicate_of else 0)
0175 |                 field_rows = [
0176 |                     {
0177 |                         "claim_id": claim_id,
0178 |                         "document_id": field.document_id,
0179 |                         "field_name": field.field_name,
0180 |                         "raw_value": field.raw_value,
0181 |                         "normalized_value": field.normalized_value,
0182 |                         "confidence": field.confidence,
0183 |                         "extraction_method": field.extraction_method,
0184 |                         "page_number": field.page_number,
0185 |                     }
0186 |                     for field in fields
0187 |                 ]
0188 |                 if field_rows:
0189 |                     await gateway.records(
0190 |                         "POST", "claim_extracted_fields", service=True, json=field_rows
0191 |                     )
0192 |                 field_count += len(field_rows)
0193 |                 amount_field = next(
0194 |                     (field for field in fields if field.field_name == "claimed_amount"),
0195 |                     None,
0196 |                 )
0197 |                 status = "COMPLETED" if amount and currency else "NEEDS_CONFIRMATION"
0198 |                 notes = (
0199 |                     None
0200 |                     if amount
0201 |                     else "No reliable payable total was found; please enter the document amount."
0202 |                 )
0203 |                 await gateway.records(
0204 |                     "PATCH",
0205 |                     "claim_documents",
0206 |                     service=True,
0207 |                     params={"id": f"eq.{document['id']}"},
0208 |                     json={
0209 |                         "document_type": document_type,
0210 |                         "content_sha256": digest,
0211 |                         "extracted_amount": amount,
0212 |                         "extracted_currency": currency,
0213 |                         "amount_confidence": amount_field.confidence
0214 |                         if amount_field
0215 |                         else None,
0216 |                         "include_in_total": bool(
0217 |                             payable and amount and not duplicate_of
0218 |                         ),
0219 |                         "duplicate_of": duplicate_of,
0220 |                         "extraction_status": status,
0221 |                         "extraction_notes": notes,
0222 |                         "extracted_at": now,
0223 |                     },
0224 |                 )
0225 |             except Exception as exc:
0226 |                 warning_count += 1
0227 |                 await gateway.records(
0228 |                     "PATCH",
0229 |                     "claim_documents",
0230 |                     service=True,
0231 |                     params={"id": f"eq.{document['id']}"},
0232 |                     json={
0233 |                         "extraction_status": "FAILED",
0234 |                         "extraction_notes": str(exc)[:500],
0235 |                         "extracted_at": now,
0236 |                     },
0237 |                 )
0238 |
0239 |         await gateway.records(
0240 |             "PATCH",
0241 |             "claims",
0242 |             service=True,
0243 |             params={"id": f"eq.{claim_id}"},
0244 |             json={"status": return_status, "warning_count": warning_count},
0245 |         )
0246 |         await gateway.records(
0247 |             "PATCH",
0248 |             "claim_processing_jobs",
0249 |             service=True,
0250 |             params={"id": f"eq.{job_id}"},
0251 |             json={
0252 |                 "status": "COMPLETED",
0253 |                 "finished_at": datetime.now(timezone.utc).isoformat(),
0254 |             },
0255 |         )
0256 |         await gateway.records(
0257 |             "POST",
0258 |             "audit_events",
0259 |             service=True,
0260 |             json={
0261 |                 "claim_id": claim_id,
0262 |                 "actor_id": actor_id,
0263 |                 "event_type": "PROCESSING_COMPLETED",
0264 |                 "metadata": {"documents": len(documents), "fields": field_count},
0265 |             },
0266 |         )
0267 |         return ProcessResult(
0268 |             claim_reference=reference,
0269 |             status=return_status,
0270 |             document_count=len(documents),
0271 |             extracted_field_count=field_count,
0272 |         )
0273 |     except Exception as exc:
0274 |         error = str(exc)[:1000]
0275 |         await gateway.records(
0276 |             "PATCH",
0277 |             "claims",
0278 |             service=True,
0279 |             params={"id": f"eq.{claim_id}"},
0280 |             json={"status": "PROCESSING_FAILED"},
0281 |         )
0282 |         await gateway.records(
0283 |             "PATCH",
0284 |             "claim_processing_jobs",
0285 |             service=True,
0286 |             params={"id": f"eq.{job_id}"},
0287 |             json={
0288 |                 "status": "FAILED",
0289 |                 "last_error": error,
0290 |                 "finished_at": datetime.now(timezone.utc).isoformat(),
0291 |             },
0292 |         )
0293 |         await gateway.records(
0294 |             "POST",
0295 |             "audit_events",
0296 |             service=True,
0297 |             json={
0298 |                 "claim_id": claim_id,
0299 |                 "actor_id": actor_id,
0300 |                 "event_type": "PROCESSING_FAILED",
0301 |                 "metadata": {"error": error},
0302 |             },
0303 |         )
0304 |         raise HTTPException(status_code=422, detail=error) from exc
```

## services/api/app/provision_staff.py

82 lines. SHA-256: `cee696da81702797c238d0b1e111fcf4709dc7d9e801a08aaf92ef6769d2dd1d`.

Symbols: `main`: L15–L78; `assign`: L43–L59

```python
0001 | """Provision staff from a trusted operator terminal, never from public signup."""
0002 |
0003 | import argparse
0004 | from datetime import datetime, timezone
0005 | import os
0006 | from pathlib import Path
0007 | import re
0008 | import secrets
0009 |
0010 | from firebase_admin import auth, firestore
0011 |
0012 | from .firebase import firebase_app
0013 |
0014 |
0015 | def main():
0016 |     parser = argparse.ArgumentParser(description=__doc__)
0017 |     parser.add_argument("--email", required=True)
0018 |     parser.add_argument(
0019 |         "--role",
0020 |         required=True,
0021 |         choices=["administrator", "claims_officer", "supervisor"],
0022 |     )
0023 |     args = parser.parse_args()
0024 |     email = args.email.strip().lower()
0025 |     if not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", email):
0026 |         parser.error("Enter a valid email.")
0027 |     app = firebase_app()
0028 |     password = None
0029 |     try:
0030 |         user = auth.get_user_by_email(email, app=app)
0031 |     except auth.UserNotFoundError:
0032 |         password = secrets.token_urlsafe(24)
0033 |         user = auth.create_user(
0034 |             email=email,
0035 |             password=password,
0036 |             display_name=args.role.replace("_", " ").title(),
0037 |             app=app,
0038 |         )
0039 |     db = firestore.client(app)
0040 |     ref = db.collection("profiles").document(user.uid)
0041 |
0042 |     @firestore.transactional
0043 |     def assign(transaction):
0044 |         snapshot = ref.get(transaction=transaction)
0045 |         if snapshot.exists:
0046 |             transaction.update(ref, {"role": args.role})
0047 |         else:
0048 |             transaction.set(
0049 |                 ref,
0050 |                 {
0051 |                     "id": user.uid,
0052 |                     "email": email,
0053 |                     "display_name": user.display_name
0054 |                     or args.role.replace("_", " ").title(),
0055 |                     "role": args.role,
0056 |                     "status": "active",
0057 |                     "created_at": datetime.now(timezone.utc).isoformat(),
0058 |                 },
0059 |             )
0060 |
0061 |     assign(db.transaction())
0062 |     if password:
0063 |         private_dir = (
0064 |             Path(os.getenv("LOCALAPPDATA", str(Path.home() / ".local/share")))
0065 |             / "claimelens"
0066 |         )
0067 |         private_dir.mkdir(parents=True, exist_ok=True)
0068 |         output = private_dir / "staff-first-login.txt"
0069 |         descriptor = os.open(output, os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o600)
0070 |         with os.fdopen(descriptor, "a", encoding="utf-8") as stream:
0071 |             stream.write(
0072 |                 f"Account: {email}\nRole: {args.role}\nInitial password: {password}\n\n"
0073 |             )
0074 |         print(f"Created {email} as {args.role}. Initial password saved to {output}")
0075 |     else:
0076 |         print(
0077 |             f"Existing account {email} assigned {args.role}; its password was retained."
0078 |         )
0079 |
0080 |
0081 | if __name__ == "__main__":
0082 |     main()
```

## services/api/app/push.py

117 lines. SHA-256: `d2dac537bf74e791202f8f668ac9bbeda45ed33ad3d432acdd6d3f0ff13eed28`.

Symbols: `Device`: L18–L19; `register`: L23–L33; `unregister`: L37–L48; `deliver_pending`: L51–L105; `push_loop`: L108–L117

```python
0001 | """Private device registration and generic, nonmedical push messages."""
0002 |
0003 | import asyncio
0004 | import hashlib
0005 | import logging
0006 | from types import SimpleNamespace
0007 | from fastapi import APIRouter, Depends, HTTPException, Request
0008 | from firebase_admin import messaging
0009 | from google.cloud.firestore_v1.base_query import FieldFilter
0010 | from pydantic import BaseModel, Field
0011 | from .firebase import FirebaseGateway, now
0012 | from .security import CurrentUser, get_current_user
0013 |
0014 | router = APIRouter(tags=["devices"])
0015 | log = logging.getLogger(__name__)
0016 |
0017 |
0018 | class Device(BaseModel):
0019 |     token: str = Field(min_length=20, max_length=4096)
0020 |
0021 |
0022 | @router.post("/devices")
0023 | async def register(
0024 |     payload: Device, request: Request, user: CurrentUser = Depends(get_current_user)
0025 | ):
0026 |     store = FirebaseGateway(request)
0027 |     ref = store.db.collection("device_tokens").document(
0028 |         hashlib.sha256(payload.token.encode()).hexdigest()
0029 |     )
0030 |     await asyncio.to_thread(
0031 |         ref.set, {"uid": user.id, "token": payload.token, "updated_at": now()}
0032 |     )
0033 |     return {"message": "Device registered."}
0034 |
0035 |
0036 | @router.delete("/devices")
0037 | async def unregister(
0038 |     payload: Device, request: Request, user: CurrentUser = Depends(get_current_user)
0039 | ):
0040 |     store = FirebaseGateway(request)
0041 |     ref = store.db.collection("device_tokens").document(
0042 |         hashlib.sha256(payload.token.encode()).hexdigest()
0043 |     )
0044 |     snapshot = await asyncio.to_thread(ref.get)
0045 |     if snapshot.exists and snapshot.to_dict().get("uid") != user.id:
0046 |         raise HTTPException(404, "Device not found.")
0047 |     await asyncio.to_thread(ref.delete)
0048 |     return {"message": "Device removed."}
0049 |
0050 |
0051 | def deliver_pending(store):
0052 |     for snapshot in (
0053 |         store.db.collection("notifications")
0054 |         .where(filter=FieldFilter("push_state", "==", "PENDING"))
0055 |         .limit(30)
0056 |         .stream()
0057 |     ):
0058 |         notice = snapshot.to_dict()
0059 |         uid = notice["recipient_id"]
0060 |         profile = store.db.collection("profiles").document(uid).get().to_dict() or {}
0061 |         devices = list(
0062 |             store.db.collection("device_tokens")
0063 |             .where(filter=FieldFilter("uid", "==", uid))
0064 |             .stream()
0065 |         )
0066 |         if (
0067 |             profile.get("status") != "active"
0068 |             or not profile.get("notifications_enabled", True)
0069 |             or not devices
0070 |         ):
0071 |             snapshot.reference.update({"push_state": "SKIPPED"})
0072 |             continue
0073 |         try:
0074 |             message = messaging.MulticastMessage(
0075 |                 fids=[s.to_dict()["token"] for s in devices[:100]],
0076 |                 notification=messaging.Notification(
0077 |                     title="ClaimLens update",
0078 |                     body="Open ClaimLens to securely view an update to your workspace.",
0079 |                 ),
0080 |                 data={"reference": notice.get("reference", "")},
0081 |                 android=messaging.AndroidConfig(
0082 |                     notification=messaging.AndroidNotification(visibility="private", tag=snapshot.id, icon="ic_stat_claimlens")
0083 |                 ),
0084 |             )
0085 |             result = messaging.send_each_for_multicast(message, app=store.app)
0086 |             for device, response in zip(devices, result.responses):
0087 |                 if isinstance(response.exception, messaging.UnregisteredError):
0088 |                     device.reference.delete()
0089 |             snapshot.reference.update(
0090 |                 {
0091 |                     "push_state": "SENT" if result.success_count else "FAILED",
0092 |                     "push_completed_at": now(),
0093 |                 }
0094 |             )
0095 |         except Exception:
0096 |             attempts = notice.get("push_attempts", 0) + 1
0097 |             snapshot.reference.update(
0098 |                 {
0099 |                     "push_attempts": attempts,
0100 |                     "push_state": "FAILED" if attempts >= 3 else "PENDING",
0101 |                 }
0102 |             )
0103 |             log.warning(
0104 |                 "A push notification could not be delivered. In-app notifications remain available."
0105 |             )
0106 |
0107 |
0108 | async def push_loop():
0109 |     while True:
0110 |         try:
0111 |             store = FirebaseGateway(SimpleNamespace(state=SimpleNamespace()))
0112 |             await asyncio.to_thread(deliver_pending, store)
0113 |         except asyncio.CancelledError:
0114 |             raise
0115 |         except Exception:
0116 |             log.warning("Push delivery unavailable; retrying later.")
0117 |         await asyncio.sleep(30)
```

## services/api/app/routers/__init__.py

1 lines. SHA-256: `82a6495cd582f6bce793605df2c6865f30dd470905a7eee445ab34807d277670`.

Symbols: Configuration/resource file.

```python
0001 | """HTTP route modules for the mobile gateway."""
```

## services/api/app/routers/auth.py

159 lines. SHA-256: `8a1c673a254a405cf049514b75c34268a38488c9dd574f1317a4783dad8e2c13`.

Symbols: `firebase_request`: L18–L47; `session`: L50–L67; `login`: L71–L81; `refresh`: L85–L92; `signup`: L96–L125; `forgot_password`: L129–L141; `logout`: L145–L147; `send_verification`: L151–L159

```python
0001 | import asyncio
0002 | from fastapi import APIRouter, Depends, HTTPException, Request, Response
0003 | from firebase_admin import auth
0004 | from ..config import get_settings
0005 | from ..firebase import FirebaseGateway, firebase_app
0006 | from ..schemas import (
0007 |     AuthSession,
0008 |     LoginRequest,
0009 |     RefreshRequest,
0010 |     SignupRequest,
0011 |     EmailRequest,
0012 | )
0013 | from ..security import CurrentUser, get_current_user
0014 |
0015 | router = APIRouter(prefix="/auth", tags=["authentication"])
0016 |
0017 |
0018 | async def firebase_request(request, action, payload, *, refresh=False):
0019 |     key = get_settings().firebase_api_key
0020 |     if not key:
0021 |         raise HTTPException(503, "Authentication is not configured on the server.")
0022 |     url = (
0023 |         f"https://securetoken.googleapis.com/v1/token?key={key}"
0024 |         if refresh
0025 |         else f"https://identitytoolkit.googleapis.com/v1/accounts:{action}?key={key}"
0026 |     )
0027 |     response = await request.app.state.http.post(
0028 |         url, **({"data": payload} if refresh else {"json": payload})
0029 |     )
0030 |     if not response.is_success:
0031 |         code = response.json().get("error", {}).get("message", "AUTHENTICATION_FAILED")
0032 |         messages = {
0033 |             "INVALID_LOGIN_CREDENTIALS": "Invalid email or password.",
0034 |             "EMAIL_NOT_FOUND": "Invalid email or password.",
0035 |             "INVALID_PASSWORD": "Invalid email or password.",
0036 |             "EMAIL_EXISTS": "An account already exists. Sign in or reset your password.",
0037 |             "TOO_MANY_ATTEMPTS_TRY_LATER": "Too many attempts. Please try again later.",
0038 |             "OPERATION_NOT_ALLOWED": "Email sign-in is not enabled.",
0039 |             "USER_DISABLED": "This account is disabled.",
0040 |         }
0041 |         raise HTTPException(
0042 |             400,
0043 |             messages.get(
0044 |                 code, "Authentication request could not be completed. Please try again."
0045 |             ),
0046 |         )
0047 |     return response.json()
0048 |
0049 |
0050 | async def session(request, data):
0051 |     token = data.get("idToken") or data.get("id_token")
0052 |     uid = data.get("localId") or data.get("user_id")
0053 |     firebase_user = await asyncio.to_thread(auth.get_user, uid, app=firebase_app())
0054 |     if firebase_user.disabled:
0055 |         raise HTTPException(403, "This account is disabled.")
0056 |     profile = await FirebaseGateway(request).ensure_profile(
0057 |         uid, firebase_user.display_name, firebase_user.email or ""
0058 |     )
0059 |     profile = {**profile, "email_verified": firebase_user.email_verified}
0060 |     if profile.get("status") != "active":
0061 |         raise HTTPException(403, "This account is not active.")
0062 |     return AuthSession(
0063 |         access_token=token,
0064 |         refresh_token=data.get("refreshToken") or data.get("refresh_token"),
0065 |         expires_in=int(data.get("expiresIn") or data.get("expires_in", 3600)),
0066 |         user=profile,
0067 |     )
0068 |
0069 |
0070 | @router.post("/login", response_model=AuthSession)
0071 | async def login(payload: LoginRequest, request: Request):
0072 |     data = await firebase_request(
0073 |         request,
0074 |         "signInWithPassword",
0075 |         {
0076 |             "email": payload.email.strip().lower(),
0077 |             "password": payload.password,
0078 |             "returnSecureToken": True,
0079 |         },
0080 |     )
0081 |     return await session(request, data)
0082 |
0083 |
0084 | @router.post("/refresh", response_model=AuthSession)
0085 | async def refresh(payload: RefreshRequest, request: Request):
0086 |     data = await firebase_request(
0087 |         request,
0088 |         "",
0089 |         {"grant_type": "refresh_token", "refresh_token": payload.refresh_token},
0090 |         refresh=True,
0091 |     )
0092 |     return await session(request, data)
0093 |
0094 |
0095 | @router.post("/signup")
0096 | async def signup(payload: SignupRequest, request: Request):
0097 |     data = await firebase_request(
0098 |         request,
0099 |         "signUp",
0100 |         {
0101 |             "email": payload.email.strip().lower(),
0102 |             "password": payload.password,
0103 |             "displayName": payload.display_name.strip(),
0104 |             "returnSecureToken": True,
0105 |         },
0106 |     )
0107 |     await FirebaseGateway(request).ensure_profile(
0108 |         data["localId"],
0109 |         payload.display_name.strip(),
0110 |         payload.email.strip().lower(),
0111 |         verification_required=True,
0112 |     )
0113 |     try:
0114 |         await firebase_request(
0115 |             request,
0116 |             "sendOobCode",
0117 |             {"requestType": "VERIFY_EMAIL", "idToken": data["idToken"]},
0118 |         )
0119 |     except HTTPException:
0120 |         return {
0121 |             "message": "Account created. You can sign in. The confirmation email could not be sent yet."
0122 |         }
0123 |     return {
0124 |         "message": "Account created. Check your email for confirmation, then sign in."
0125 |     }
0126 |
0127 |
0128 | @router.post("/forgot-password")
0129 | async def forgot_password(payload: EmailRequest, request: Request):
0130 |     try:
0131 |         await firebase_request(
0132 |             request,
0133 |             "sendOobCode",
0134 |             {"requestType": "PASSWORD_RESET", "email": payload.email.strip().lower()},
0135 |         )
0136 |     except HTTPException as error:
0137 |         if error.detail != "Invalid email or password.":
0138 |             raise
0139 |     return {
0140 |         "message": "If an account exists, Firebase will email you a password reset link. Open it to choose a new password, then return here to sign in."
0141 |     }
0142 |
0143 |
0144 | @router.post("/logout", status_code=204)
0145 | async def logout(user: CurrentUser = Depends(get_current_user)):
0146 |     await asyncio.to_thread(auth.revoke_refresh_tokens, user.id, app=firebase_app())
0147 |     return Response(status_code=204)
0148 |
0149 |
0150 | @router.post("/verification-email")
0151 | async def send_verification(
0152 |     request: Request, user: CurrentUser = Depends(get_current_user)
0153 | ):
0154 |     if user.profile.email_verified:
0155 |         return {"message": "Your email is already verified."}
0156 |     await firebase_request(
0157 |         request, "sendOobCode", {"requestType": "VERIFY_EMAIL", "idToken": user.token}
0158 |     )
0159 |     return {"message": "Verification email sent. Check your inbox and spam folder."}
```

## services/api/app/routers/claim_tools.py

321 lines. SHA-256: `459063e2381c9ab5d396956752d1c36ffffef099d615c1232a47bcee72349d87`.

Symbols: `ClaimInformation`: L21–L25; `BusinessSettings`: L28–L45; `business_settings`: L48–L54; `settings`: L58–L59; `edit_settings`: L63–L84; `information`: L88–L117; `Appeal`: L120–L121; `appeal`: L125–L181; `preview`: L185–L253; `receipt`: L257–L298; `receipt_preview`: L302–L321; `save`: L103–L114; `submit`: L139–L178; `render`: L206–L242; `create`: L265–L288; `render`: L307–L315

```python
0001 | """Claim information, source previews, receipts, and controlled appeals."""
0002 |
0003 | import asyncio
0004 | from datetime import date
0005 | from io import BytesIO
0006 |
0007 | from fastapi import APIRouter, Depends, HTTPException, Query, Request
0008 | from fastapi.responses import Response
0009 | from firebase_admin import firestore
0010 | from pydantic import BaseModel, Field
0011 |
0012 | from ..firebase import FirebaseGateway, now
0013 | from ..security import CurrentUser, get_current_user
0014 | from ..workflow import write_event
0015 | from .claims import accessible_claim
0016 | from .workspace import administrator
0017 |
0018 | router = APIRouter(tags=["claim tools"])
0019 |
0020 |
0021 | class ClaimInformation(BaseModel):
0022 |     member_number: str = Field(default="", max_length=80)
0023 |     policy_number: str = Field(default="", max_length=80)
0024 |     treatment_date: date | None = None
0025 |     description: str = Field(default="", max_length=2000)
0026 |
0027 |
0028 | class BusinessSettings(BaseModel):
0029 |     require_member_number: bool = False
0030 |     require_policy_number: bool = False
0031 |     required_documents: list[str] = Field(
0032 |         default_factory=lambda: ["Invoice or receipt", "Supporting medical evidence"],
0033 |         max_length=20,
0034 |     )
0035 |     allowed_currencies: list[str] = Field(
0036 |         default_factory=lambda: ["MUR", "USD", "EUR", "GBP"],
0037 |         min_length=1,
0038 |         max_length=20,
0039 |     )
0040 |     maximum_appeals: int = Field(default=1, ge=0, le=3)
0041 |     support_email: str = Field(default="", max_length=254)
0042 |     privacy_notice: str = Field(
0043 |         default="Use ClaimLens only for claims you are authorized to submit. Uploaded medical evidence is shared with authorized reviewers for claim processing.",
0044 |         max_length=8000,
0045 |     )
0046 |
0047 |
0048 | async def business_settings(store):
0049 |     snapshot = await asyncio.to_thread(
0050 |         store.db.collection("configuration").document("business").get
0051 |     )
0052 |     return BusinessSettings.model_validate(
0053 |         snapshot.to_dict() if snapshot.exists else {}
0054 |     ).model_dump(mode="json")
0055 |
0056 |
0057 | @router.get("/settings")
0058 | async def settings(request: Request, user: CurrentUser = Depends(get_current_user)):
0059 |     return await business_settings(FirebaseGateway(request))
0060 |
0061 |
0062 | @router.put("/settings")
0063 | async def edit_settings(
0064 |     payload: BusinessSettings,
0065 |     request: Request,
0066 |     user: CurrentUser = Depends(get_current_user),
0067 | ):
0068 |     administrator(user)
0069 |     currencies = sorted(set(c.strip().upper() for c in payload.allowed_currencies))
0070 |     if any(len(c) != 3 or not c.isalpha() for c in currencies):
0071 |         raise HTTPException(422, "Currencies must be three-letter codes.")
0072 |     if payload.support_email and (
0073 |         "@" not in payload.support_email or "\n" in payload.support_email
0074 |     ):
0075 |         raise HTTPException(422, "Enter a valid support email.")
0076 |     store = FirebaseGateway(request)
0077 |     values = {**payload.model_dump(mode="json"), "allowed_currencies": currencies}
0078 |     await asyncio.to_thread(
0079 |         store.db.collection("configuration").document("business").set, values
0080 |     )
0081 |     from .workspace import account_event
0082 |
0083 |     await account_event(store, user.id, "BUSINESS_SETTINGS_UPDATED", user.id)
0084 |     return values
0085 |
0086 |
0087 | @router.put("/claims/{reference}/information")
0088 | async def information(
0089 |     reference: str,
0090 |     payload: ClaimInformation,
0091 |     request: Request,
0092 |     user: CurrentUser = Depends(get_current_user),
0093 | ):
0094 |     store = FirebaseGateway(request)
0095 |     claim = await accessible_claim(store, reference)
0096 |     if user.profile.role != "client" or claim.get("client_id") != user.id:
0097 |         raise HTTPException(403, "Only the claim owner can update draft information.")
0098 |     if payload.treatment_date and payload.treatment_date > date.today():
0099 |         raise HTTPException(422, "The treatment date cannot be in the future.")
0100 |     ref = store.db.collection("claims").document(claim["id"])
0101 |
0102 |     @firestore.transactional
0103 |     def save(transaction):
0104 |         current = ref.get(transaction=transaction).to_dict()
0105 |         if current.get("status") not in {
0106 |             "UPLOADED",
0107 |             "PROCESSING_FAILED",
0108 |         } or current.get("needs_reconfirmation"):
0109 |             raise HTTPException(
0110 |                 409, "Submitted claim information cannot be changed as a draft."
0111 |             )
0112 |         transaction.update(
0113 |             ref, {"information": payload.model_dump(mode="json"), "updated_at": now()}
0114 |         )
0115 |
0116 |     await asyncio.to_thread(save, store.db.transaction())
0117 |     return {"message": "Draft information saved."}
0118 |
0119 |
0120 | class Appeal(BaseModel):
0121 |     reason: str = Field(min_length=10, max_length=2000)
0122 |
0123 |
0124 | @router.post("/claims/{reference}/appeal")
0125 | async def appeal(
0126 |     reference: str,
0127 |     payload: Appeal,
0128 |     request: Request,
0129 |     user: CurrentUser = Depends(get_current_user),
0130 | ):
0131 |     store = FirebaseGateway(request)
0132 |     claim = await accessible_claim(store, reference)
0133 |     if user.profile.role != "client" or claim.get("client_id") != user.id:
0134 |         raise HTTPException(403, "Only the claim owner can request an appeal.")
0135 |     policy = await business_settings(store)
0136 |     ref = store.db.collection("claims").document(claim["id"])
0137 |
0138 |     @firestore.transactional
0139 |     def submit(transaction):
0140 |         current = ref.get(transaction=transaction).to_dict()
0141 |         if (
0142 |             current["status"] != "REJECTED"
0143 |             or current.get("appeal_count", 0) >= policy["maximum_appeals"]
0144 |         ):
0145 |             raise HTTPException(409, "An appeal is not available for this claim.")
0146 |         row = store.db.collection("claim_appeals").document()
0147 |         transaction.set(
0148 |             row,
0149 |             {
0150 |                 "id": row.id,
0151 |                 "claim_id": claim["id"],
0152 |                 "reason": payload.reason.strip(),
0153 |                 "previous_decision": current.get("decision_notes"),
0154 |                 "created_at": now(),
0155 |                 "created_by": user.id,
0156 |             },
0157 |         )
0158 |         transaction.update(
0159 |             ref,
0160 |             {
0161 |                 "status": "REVIEW_REQUIRED",
0162 |                 "assigned_to": None,
0163 |                 "verified_by": None,
0164 |                 "verified_at": None,
0165 |                 "decision_notes": None,
0166 |                 "approved_amount": None,
0167 |                 "appeal_count": current.get("appeal_count", 0) + 1,
0168 |                 "updated_at": now(),
0169 |             },
0170 |         )
0171 |         write_event(
0172 |             store.db,
0173 |             transaction,
0174 |             current,
0175 |             user.id,
0176 |             "APPEAL_SUBMITTED",
0177 |             {"reason": payload.reason.strip()},
0178 |         )
0179 |
0180 |     await asyncio.to_thread(submit, store.db.transaction())
0181 |     return {"message": "Appeal submitted to the review queue."}
0182 |
0183 |
0184 | @router.get("/claims/{reference}/documents/{identifier}/preview")
0185 | async def preview(
0186 |     reference: str,
0187 |     identifier: str,
0188 |     request: Request,
0189 |     page: int = Query(default=1, ge=1, le=100),
0190 |     user: CurrentUser = Depends(get_current_user),
0191 | ):
0192 |     if user.profile.role == "finance":
0193 |         raise HTTPException(403, "Medical document access requires review permission.")
0194 |     store = FirebaseGateway(request)
0195 |     claim = await accessible_claim(store, reference)
0196 |     rows = await store.records(
0197 |         "GET",
0198 |         "claim_documents",
0199 |         params={"claim_id": f"eq.{claim['id']}", "id": f"eq.{identifier}"},
0200 |     )
0201 |     if not rows:
0202 |         raise HTTPException(404, "Document not found.")
0203 |     row = rows[0]
0204 |     content = await store.download(row["storage_path"])
0205 |
0206 |     def render():
0207 |         if row["mime_type"] == "application/pdf":
0208 |             import pymupdf
0209 |
0210 |             with pymupdf.open(stream=content, filetype="pdf") as document:
0211 |                 if document.needs_pass or page > len(document):
0212 |                     raise HTTPException(
0213 |                         422,
0214 |                         "This page is unavailable or the document is password protected.",
0215 |                     )
0216 |                 return (
0217 |                     document[page - 1]
0218 |                     .get_pixmap(matrix=pymupdf.Matrix(1.5, 1.5), alpha=False)
0219 |                     .tobytes("png"),
0220 |                     "image/png",
0221 |                     len(document),
0222 |                 )
0223 |         if row["mime_type"].startswith("image/"):
0224 |             from PIL import Image
0225 |
0226 |             with Image.open(BytesIO(content)) as image:
0227 |                 image.thumbnail((2048, 2048))
0228 |                 output = BytesIO()
0229 |                 image.convert("RGB").save(output, format="PNG")
0230 |                 return output.getvalue(), "image/png", 1
0231 |         from docx import Document
0232 |
0233 |         document = Document(BytesIO(content))
0234 |         text = "\n".join(
0235 |             [p.text for p in document.paragraphs]
0236 |             + [
0237 |                 " | ".join(c.text for c in row.cells)
0238 |                 for table in document.tables
0239 |                 for row in table.rows
0240 |             ]
0241 |         )
0242 |         return text.encode(), "text/plain; charset=utf-8", 1
0243 |
0244 |     data, mime, pages = await asyncio.to_thread(render)
0245 |     return Response(
0246 |         data,
0247 |         media_type=mime,
0248 |         headers={
0249 |             "Cache-Control": "private, no-store",
0250 |             "X-Document-Pages": str(pages),
0251 |             "X-Content-Type-Options": "nosniff",
0252 |         },
0253 |     )
0254 |
0255 |
0256 | @router.get("/claims/{reference}/receipt")
0257 | async def receipt(
0258 |     reference: str, request: Request, user: CurrentUser = Depends(get_current_user)
0259 | ):
0260 |     store = FirebaseGateway(request)
0261 |     claim = await accessible_claim(store, reference)
0262 |     if claim["status"] in {"UPLOADED", "PROCESSING", "PROCESSING_FAILED"}:
0263 |         raise HTTPException(409, "A receipt is available after submission.")
0264 |
0265 |     def create():
0266 |         import pymupdf
0267 |
0268 |         document = pymupdf.open()
0269 |         page = document.new_page()
0270 |         lines = [
0271 |             "ClaimLens",
0272 |             "Claim submission receipt",
0273 |             "",
0274 |             f"Reference: {claim['reference']}",
0275 |             f"Patient: {claim.get('patient_name', '')}",
0276 |             f"Provider: {claim.get('provider_name', '')}",
0277 |             f"Claimed: {claim.get('currency', 'MUR')} {claim.get('claimed_amount', '')}",
0278 |             f"Status: {claim['status'].replace('_', ' ')}",
0279 |             f"Submitted: {claim.get('submitted_at', claim['created_at'])[:10]}",
0280 |             "",
0281 |             "This receipt confirms submission. It is not an approval or a promise of payment.",
0282 |         ]
0283 |         page.insert_textbox(
0284 |             pymupdf.Rect(45, 45, 550, 780), "\n".join(lines), fontsize=12
0285 |         )
0286 |         result = document.tobytes()
0287 |         document.close()
0288 |         return result
0289 |
0290 |     data = await asyncio.to_thread(create)
0291 |     return Response(
0292 |         data,
0293 |         media_type="application/pdf",
0294 |         headers={
0295 |             "Content-Disposition": f'attachment; filename="{reference}-receipt.pdf"',
0296 |             "Cache-Control": "private, no-store",
0297 |         },
0298 |     )
0299 |
0300 |
0301 | @router.get("/claims/{reference}/receipt/preview")
0302 | async def receipt_preview(
0303 |     reference: str, request: Request, user: CurrentUser = Depends(get_current_user)
0304 | ):
0305 |     pdf = await receipt(reference, request, user)
0306 |
0307 |     def render():
0308 |         import pymupdf
0309 |
0310 |         with pymupdf.open(stream=pdf.body, filetype="pdf") as document:
0311 |             return (
0312 |                 document[0]
0313 |                 .get_pixmap(matrix=pymupdf.Matrix(1.5, 1.5), alpha=False)
0314 |                 .tobytes("png")
0315 |             )
0316 |
0317 |     return Response(
0318 |         await asyncio.to_thread(render),
0319 |         media_type="image/png",
0320 |         headers={"X-Document-Pages": "1", "Cache-Control": "private, no-store"},
0321 |     )
```

## services/api/app/routers/claims.py

462 lines. SHA-256: `61959e00788960e5430fcca8922b7b6200bda6a6b5fe0d23f5ba0d04b80a9e1a`.

Symbols: `summary`: L51–L52; `valid_signature`: L55–L76; `accessible_claim`: L79–L87; `list_claims`: L91–L132; `dashboard`: L136–L167; `create_claim`: L171–L292; `delete_draft`: L296–L319; `get_claim`: L323–L378; `process`: L382–L418; `finish_processing`: L421–L440; `confirm_claim`: L444–L462

```python
0001 | from __future__ import annotations
0002 |
0003 | import re
0004 | import asyncio
0005 | import uuid
0006 | import zipfile
0007 | import hashlib
0008 | from collections import Counter
0009 | from io import BytesIO
0010 | from pathlib import Path
0011 | from typing import Any
0012 | from typing import Literal
0013 |
0014 | from fastapi import (
0015 |     APIRouter,
0016 |     BackgroundTasks,
0017 |     Depends,
0018 |     File,
0019 |     HTTPException,
0020 |     Query,
0021 |     Request,
0022 |     UploadFile,
0023 |     Header,
0024 | )
0025 |
0026 | from ..processing import process_claim
0027 | from ..schemas import (
0028 |     ClaimDetails,
0029 |     ClaimDocument,
0030 |     ClaimSummary,
0031 |     ConfirmClaimRequest,
0032 |     DashboardSummary,
0033 |     ExtractedField,
0034 |     ProcessResult,
0035 | )
0036 | from ..security import CurrentUser, get_current_user
0037 | from ..firebase import FirebaseGateway
0038 | from ..workflow import workflow_details
0039 |
0040 |
0041 | router = APIRouter(prefix="/claims", tags=["claims"])
0042 | ALLOWED_MIME_TYPES = {
0043 |     "application/pdf": ".pdf",
0044 |     "image/jpeg": ".jpg",
0045 |     "image/png": ".png",
0046 |     "application/vnd.openxmlformats-officedocument.wordprocessingml.document": ".docx",
0047 | }
0048 | CLAIM_SELECT = "id,reference,patient_name,provider_name,claimed_amount,currency,status,warning_count,created_at,assigned_to"
0049 |
0050 |
0051 | def summary(row: dict[str, Any]) -> ClaimSummary:
0052 |     return ClaimSummary(**{key: row.get(key) for key in CLAIM_SELECT.split(",")})
0053 |
0054 |
0055 | def valid_signature(content: bytes, mime_type: str) -> bool:
0056 |     if mime_type == "application/pdf":
0057 |         return content.startswith(b"%PDF-")
0058 |     if mime_type == "image/png":
0059 |         return content.startswith(b"\x89PNG\r\n\x1a\n")
0060 |     if mime_type == "image/jpeg":
0061 |         return content.startswith(b"\xff\xd8\xff")
0062 |     if (
0063 |         mime_type
0064 |         == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
0065 |     ):
0066 |         try:
0067 |             with zipfile.ZipFile(BytesIO(content)) as archive:
0068 |                 items = archive.infolist()
0069 |                 return (
0070 |                     len(items) <= 1024
0071 |                     and sum(item.file_size for item in items) <= 50 * 1024 * 1024
0072 |                     and "word/document.xml" in archive.namelist()
0073 |                 )
0074 |         except zipfile.BadZipFile:
0075 |             return False
0076 |     return False
0077 |
0078 |
0079 | async def accessible_claim(gateway: FirebaseGateway, reference: str) -> dict[str, Any]:
0080 |     rows = await gateway.records(
0081 |         "GET",
0082 |         "claims",
0083 |         params={"reference": f"eq.{reference}", "limit": "1"},
0084 |     )
0085 |     if not rows:
0086 |         raise HTTPException(status_code=404, detail="Claim not found.")
0087 |     return rows[0]
0088 |
0089 |
0090 | @router.get("", response_model=list[ClaimSummary])
0091 | async def list_claims(
0092 |     request: Request,
0093 |     status: str | None = Query(default=None),
0094 |     search: str | None = Query(default=None, max_length=100),
0095 |     scope: Literal["all", "mine", "unassigned"] = "all",
0096 |     view: Literal["all", "review"] = "all",
0097 |     limit: int = Query(default=50, ge=1, le=200),
0098 |     user: CurrentUser = Depends(get_current_user),
0099 | ) -> list[ClaimSummary]:
0100 |     gateway = FirebaseGateway(request)
0101 |     params: dict[str, str] = {"order": "created_at.desc"}
0102 |     if status:
0103 |         params["status"] = f"eq.{status.upper()}"
0104 |     if search and search.strip():
0105 |         safe = re.sub(r"[^\w\s-]", "", search.strip())
0106 |         if safe:
0107 |             params["or"] = (
0108 |                 f"(reference.ilike.*{safe}*,patient_name.ilike.*{safe}*,provider_name.ilike.*{safe}*)"
0109 |             )
0110 |     rows = await gateway.records("GET", "claims", params=params)
0111 |     if scope == "mine" and user.profile.role != "client":
0112 |         rows = [r for r in rows if r.get("assigned_to") == user.id]
0113 |     if scope == "unassigned":
0114 |         rows = [
0115 |             r
0116 |             for r in rows
0117 |             if not r.get("assigned_to")
0118 |             and r["status"] in {"REVIEW_REQUIRED", "INFORMATION_RECEIVED"}
0119 |         ]
0120 |     if view == "review":
0121 |         rows = [
0122 |             r
0123 |             for r in rows
0124 |             if r["status"]
0125 |             in {
0126 |                 "REVIEW_REQUIRED",
0127 |                 "INFORMATION_RECEIVED",
0128 |                 "INFORMATION_REQUIRED",
0129 |                 "VERIFIED",
0130 |             }
0131 |         ]
0132 |     return [summary(row) for row in rows[:limit]]
0133 |
0134 |
0135 | @router.get("/dashboard", response_model=DashboardSummary)
0136 | async def dashboard(
0137 |     request: Request,
0138 |     user: CurrentUser = Depends(get_current_user),
0139 | ) -> DashboardSummary:
0140 |     gateway = FirebaseGateway(request)
0141 |     params: dict[str, str] = {"order": "created_at.desc"}
0142 |     rows = await gateway.records("GET", "claims", params=params)
0143 |     counts = Counter(row["status"] for row in rows)
0144 |     action_statuses = {
0145 |         "client": {"UPLOADED", "INFORMATION_REQUIRED", "PROCESSING_FAILED"},
0146 |         "claims_officer": {"REVIEW_REQUIRED", "INFORMATION_RECEIVED"},
0147 |         "supervisor": {"VERIFIED", "REVIEW_REQUIRED", "INFORMATION_RECEIVED"},
0148 |         "administrator": {"REVIEW_REQUIRED", "INFORMATION_RECEIVED"},
0149 |         "finance": {"APPROVED", "PAYMENT_PENDING"},
0150 |     }.get(user.profile.role, set())
0151 |     return DashboardSummary(
0152 |         action_required_claims=[
0153 |             summary(row) for row in rows if row["status"] in action_statuses
0154 |         ][:5],
0155 |         unassigned=sum(
0156 |             not row.get("assigned_to")
0157 |             and row["status"] in {"REVIEW_REQUIRED", "INFORMATION_RECEIVED"}
0158 |             for row in rows
0159 |         ),
0160 |         by_status=dict(counts),
0161 |         total_claims=len(rows),
0162 |         processing=counts["PROCESSING"],
0163 |         review_required=counts["REVIEW_REQUIRED"],
0164 |         verified=counts["VERIFIED"],
0165 |         processing_failed=counts["PROCESSING_FAILED"],
0166 |         recent_claims=[summary(row) for row in rows[:5]],
0167 |     )
0168 |
0169 |
0170 | @router.post("", response_model=ClaimDetails, status_code=201)
0171 | async def create_claim(
0172 |     request: Request,
0173 |     files: list[UploadFile] = File(...),
0174 |     idempotency_key: str | None = Header(default=None, min_length=16, max_length=100),
0175 |     user: CurrentUser = Depends(get_current_user),
0176 | ) -> ClaimDetails:
0177 |     gateway = FirebaseGateway(request)
0178 |     settings = gateway.settings
0179 |     if not files or len(files) > settings.max_claim_documents:
0180 |         raise HTTPException(
0181 |             status_code=422,
0182 |             detail=f"Upload between 1 and {settings.max_claim_documents} documents.",
0183 |         )
0184 |     prepared: list[tuple[UploadFile, bytes]] = []
0185 |     for upload in files:
0186 |         content = await upload.read(settings.max_file_bytes + 1)
0187 |         if upload.content_type not in ALLOWED_MIME_TYPES:
0188 |             raise HTTPException(
0189 |                 status_code=422,
0190 |                 detail=f"{upload.filename or 'Document'} is not a PDF, PNG, JPEG, or DOCX file.",
0191 |             )
0192 |         if not content or len(content) > settings.max_file_bytes:
0193 |             raise HTTPException(
0194 |                 status_code=422,
0195 |                 detail=f"{upload.filename or 'Document'} must be smaller than {settings.max_file_bytes // (1024 * 1024)} MB.",
0196 |             )
0197 |         if not valid_signature(content, upload.content_type):
0198 |             raise HTTPException(
0199 |                 status_code=422,
0200 |                 detail=f"{upload.filename or 'Document'} does not match its reported file type.",
0201 |             )
0202 |         prepared.append((upload, content))
0203 |
0204 |     rows = await gateway.records(
0205 |         "POST",
0206 |         "claims",
0207 |         json={
0208 |             "created_by": user.id,
0209 |             "client_id": user.id,
0210 |             "patient_name": "",
0211 |             "provider_name": "",
0212 |             "currency": "MUR",
0213 |             "status": "UPLOADED",
0214 |             "request_key": idempotency_key,
0215 |             "upload_complete": False,
0216 |         },
0217 |     )
0218 |     claim = rows[0]
0219 |     if claim.pop("_reused", False):
0220 |         if not claim.get("upload_complete"):
0221 |             raise HTTPException(
0222 |                 409,
0223 |                 "This upload is already being saved. Check your drafts before trying again.",
0224 |             )
0225 |         return await get_claim(claim["reference"], request, user)
0226 |     documents: list[dict[str, Any]] = []
0227 |     uploaded_paths: list[str] = []
0228 |     try:
0229 |         for upload, content in prepared:
0230 |             original = Path(
0231 |                 upload.filename or f"document{ALLOWED_MIME_TYPES[upload.content_type]}"
0232 |             ).name
0233 |             safe_name = re.sub(r"[^A-Za-z0-9._-]", "_", original)[:160]
0234 |             storage_path = f"{user.id}/{claim['id']}/{uuid.uuid4().hex}-{safe_name}"
0235 |             await gateway.upload(storage_path, content, upload.content_type)
0236 |             uploaded_paths.append(storage_path)
0237 |             inserted = await gateway.records(
0238 |                 "POST",
0239 |                 "claim_documents",
0240 |                 json={
0241 |                     "claim_id": claim["id"],
0242 |                     "uploaded_by": user.id,
0243 |                     "document_type": "UNKNOWN",
0244 |                     "original_name": original,
0245 |                     "storage_path": storage_path,
0246 |                     "mime_type": upload.content_type,
0247 |                     "size_bytes": len(content),
0248 |                     "content_sha256": hashlib.sha256(content).hexdigest(),
0249 |                 },
0250 |             )
0251 |             documents.append(inserted[0])
0252 |             await gateway.records(
0253 |                 "POST",
0254 |                 "audit_events",
0255 |                 json={
0256 |                     "claim_id": claim["id"],
0257 |                     "actor_id": user.id,
0258 |                     "event_type": "DOCUMENT_UPLOADED",
0259 |                     "metadata": {"document_id": inserted[0]["id"], "name": original},
0260 |                 },
0261 |             )
0262 |         await gateway.records(
0263 |             "POST",
0264 |             "audit_events",
0265 |             json={
0266 |                 "claim_id": claim["id"],
0267 |                 "actor_id": user.id,
0268 |                 "event_type": "CLAIM_CREATED",
0269 |                 "metadata": {"document_count": len(documents)},
0270 |             },
0271 |         )
0272 |     except Exception:
0273 |         try:
0274 |             await gateway.delete_objects(uploaded_paths)
0275 |             await gateway.records(
0276 |                 "DELETE", "claims", params={"id": f"eq.{claim['id']}"}
0277 |             )
0278 |         except Exception:
0279 |             pass
0280 |         raise
0281 |     await gateway.records(
0282 |         "PATCH",
0283 |         "claims",
0284 |         service=True,
0285 |         params={"id": f"eq.{claim['id']}"},
0286 |         json={"upload_complete": True},
0287 |     )
0288 |     return ClaimDetails(
0289 |         **summary(claim).model_dump(),
0290 |         documents=[ClaimDocument(**document, fields=[]) for document in documents],
0291 |         audit_events=[],
0292 |     )
0293 |
0294 |
0295 | @router.delete("/{reference}")
0296 | async def delete_draft(
0297 |     reference: str, request: Request, user: CurrentUser = Depends(get_current_user)
0298 | ):
0299 |     gateway = FirebaseGateway(request)
0300 |     claim = await accessible_claim(gateway, reference)
0301 |     if (
0302 |         user.profile.role != "client"
0303 |         or claim.get("client_id") != user.id
0304 |         or claim["status"] not in {"UPLOADED", "PROCESSING_FAILED"}
0305 |         or claim.get("submitted_at")
0306 |         or claim.get("needs_reconfirmation")
0307 |     ):
0308 |         raise HTTPException(403, "Only your unsubmitted drafts can be deleted.")
0309 |     documents = await gateway.records(
0310 |         "GET", "claim_documents", params={"claim_id": f"eq.{claim['id']}"}
0311 |     )
0312 |     old_status = await gateway.reserve_draft_deletion(claim['id'])
0313 |     try:
0314 |         await gateway.delete_objects([d["storage_path"] for d in documents])
0315 |         await gateway.records("DELETE", "claims", service=True, params={"id": f"eq.{claim['id']}"})
0316 |     except Exception:
0317 |         await asyncio.to_thread(gateway.db.collection('claims').document(claim['id']).update, {'status': old_status})
0318 |         raise
0319 |     return {"message": "Draft and its documents deleted."}
0320 |
0321 |
0322 | @router.get("/{reference}", response_model=ClaimDetails)
0323 | async def get_claim(
0324 |     reference: str,
0325 |     request: Request,
0326 |     user: CurrentUser = Depends(get_current_user),
0327 | ) -> ClaimDetails:
0328 |     gateway = FirebaseGateway(request)
0329 |     claim = await accessible_claim(gateway, reference)
0330 |     documents = await gateway.records(
0331 |         "GET",
0332 |         "claim_documents",
0333 |         params={"claim_id": f"eq.{claim['id']}", "order": "created_at.asc"},
0334 |     )
0335 |     fields = await gateway.records(
0336 |         "GET",
0337 |         "claim_extracted_fields",
0338 |         params={"claim_id": f"eq.{claim['id']}", "order": "created_at.asc"},
0339 |     )
0340 |     audit = await gateway.records(
0341 |         "GET",
0342 |         "audit_events",
0343 |         params={
0344 |             "claim_id": f"eq.{claim['id']}",
0345 |             "order": "created_at.desc",
0346 |             "limit": "100",
0347 |         },
0348 |     )
0349 |     grouped: dict[str, list[ExtractedField]] = {}
0350 |     for field in fields:
0351 |         grouped.setdefault(field.get("document_id") or "", []).append(
0352 |             ExtractedField(**field)
0353 |         )
0354 |     response_documents = []
0355 |     if user.profile.role == "finance":
0356 |         documents = []
0357 |         audit = [
0358 |             event
0359 |             for event in audit
0360 |             if event.get("event_type")
0361 |             in {"CLAIM_APPROVED", "CLAIM_PAYMENT_PENDING", "CLAIM_PAID"}
0362 |         ]
0363 |     for document in documents:
0364 |         signed_url = await gateway.signed_url(document["storage_path"])
0365 |         response_documents.append(
0366 |             ClaimDocument(
0367 |                 **document,
0368 |                 signed_url=signed_url,
0369 |                 fields=grouped.get(document["id"], []),
0370 |             )
0371 |         )
0372 |     return ClaimDetails(
0373 |         **summary(claim).model_dump(),
0374 |         documents=response_documents,
0375 |         audit_events=audit,
0376 |         **(await workflow_details(gateway, claim)),
0377 |         information=claim.get("information") or {},
0378 |     )
0379 |
0380 |
0381 | @router.post("/{reference}/process", response_model=ProcessResult)
0382 | async def process(
0383 |     reference: str,
0384 |     request: Request,
0385 |     background_tasks: BackgroundTasks,
0386 |     background: bool = False,
0387 |     user: CurrentUser = Depends(get_current_user),
0388 | ) -> ProcessResult:
0389 |     gateway = FirebaseGateway(request)
0390 |     claim = await accessible_claim(gateway, reference)
0391 |     if claim["status"] not in {"UPLOADED", "PROCESSING_FAILED"}:
0392 |         raise HTTPException(
0393 |             status_code=409, detail="This claim is not available for processing."
0394 |         )
0395 |     await gateway.acquire_processing(claim["id"])
0396 |     if background:
0397 |         from ..jobs import enqueue
0398 |
0399 |         try:
0400 |             await enqueue(gateway, claim, user.id)
0401 |         except Exception:
0402 |             await gateway.records(
0403 |                 "PATCH",
0404 |                 "claims",
0405 |                 service=True,
0406 |                 params={"id": f"eq.{claim['id']}"},
0407 |                 json={"status": "PROCESSING_FAILED"},
0408 |             )
0409 |             raise HTTPException(
0410 |                 503, "The processing queue is unavailable. Please retry."
0411 |             )
0412 |         return ProcessResult(
0413 |             claim_reference=reference,
0414 |             status="PROCESSING",
0415 |             document_count=0,
0416 |             extracted_field_count=0,
0417 |         )
0418 |     return await finish_processing(gateway, claim, user.id)
0419 |
0420 |
0421 | async def finish_processing(gateway, claim, actor_id):
0422 |     try:
0423 |         return await process_claim(
0424 |             gateway,
0425 |             claim,
0426 |             actor_id,
0427 |             return_status="INFORMATION_RECEIVED"
0428 |             if claim.get("needs_reconfirmation")
0429 |             else "UPLOADED",
0430 |         )
0431 |     except Exception:
0432 |         # A failure before the processing job is created must release the claim.
0433 |         await gateway.records(
0434 |             "PATCH",
0435 |             "claims",
0436 |             service=True,
0437 |             params={"id": f"eq.{claim['id']}"},
0438 |             json={"status": "PROCESSING_FAILED"},
0439 |         )
0440 |         raise
0441 |
0442 |
0443 | @router.post("/{reference}/confirm")
0444 | async def confirm_claim(
0445 |     reference: str,
0446 |     payload: ConfirmClaimRequest,
0447 |     request: Request,
0448 |     user: CurrentUser = Depends(get_current_user),
0449 | ) -> dict[str, str]:
0450 |     gateway = FirebaseGateway(request)
0451 |     claim = await accessible_claim(gateway, reference)
0452 |     if (
0453 |         user.profile.role != "client"
0454 |         or claim.get("client_id") != user.id
0455 |         or claim.get('status') not in {'UPLOADED', 'PROCESSING_FAILED'}
0456 |         or claim.get('needs_reconfirmation')
0457 |         or claim.get('submitted_at')
0458 |     ):
0459 |         raise HTTPException(
0460 |             status_code=403, detail="Only the claim owner can confirm this draft."
0461 |         )
0462 |     return {"status": await gateway.confirm(claim["id"], payload)}
```

## services/api/app/routers/profile.py

113 lines. SHA-256: `e21e50b55b767fd08d383af25ccf373c58376367bb42b03b92cb976939cb430d`.

Symbols: `profile`: L17–L18; `ProfileEdit`: L21–L25; `edit_profile`: L29–L47; `PasswordEdit`: L50–L52; `UnlockRequest`: L55–L56; `unlock`: L60–L74; `change_password`: L78–L113

```python
0001 | import asyncio
0002 | from typing import Literal
0003 | from fastapi import APIRouter, Depends, Request
0004 | from firebase_admin import auth
0005 | from pydantic import BaseModel, Field
0006 |
0007 | from ..schemas import Profile
0008 | from ..security import CurrentUser, get_current_user
0009 | from ..firebase import FirebaseGateway
0010 | from .auth import firebase_request, session
0011 |
0012 |
0013 | router = APIRouter(tags=["profile"])
0014 |
0015 |
0016 | @router.get("/profile", response_model=Profile)
0017 | async def profile(user: CurrentUser = Depends(get_current_user)) -> Profile:
0018 |     return user.profile
0019 |
0020 |
0021 | class ProfileEdit(BaseModel):
0022 |     display_name: str = Field(min_length=2, max_length=120)
0023 |     phone: str = Field(default="", max_length=32)
0024 |     theme: Literal["system", "light", "dark"] = "system"
0025 |     notifications_enabled: bool = True
0026 |
0027 |
0028 | @router.put("/profile", response_model=Profile)
0029 | async def edit_profile(
0030 |     payload: ProfileEdit,
0031 |     request: Request,
0032 |     user: CurrentUser = Depends(get_current_user),
0033 | ):
0034 |     store = FirebaseGateway(request)
0035 |     update = payload.model_dump()
0036 |     update["display_name"] = payload.display_name.strip()
0037 |     if len(update["display_name"]) < 2:
0038 |         from fastapi import HTTPException
0039 |
0040 |         raise HTTPException(422, "Enter a valid display name.")
0041 |     await asyncio.to_thread(
0042 |         auth.update_user, user.id, display_name=update["display_name"], app=store.app
0043 |     )
0044 |     await asyncio.to_thread(
0045 |         store.db.collection("profiles").document(user.id).update, update
0046 |     )
0047 |     return {**user.profile.model_dump(), **update}
0048 |
0049 |
0050 | class PasswordEdit(BaseModel):
0051 |     current_password: str = Field(min_length=1, max_length=128)
0052 |     new_password: str = Field(min_length=12, max_length=128)
0053 |
0054 |
0055 | class UnlockRequest(BaseModel):
0056 |     password: str = Field(min_length=1, max_length=128)
0057 |
0058 |
0059 | @router.post("/profile/unlock")
0060 | async def unlock(
0061 |     payload: UnlockRequest,
0062 |     request: Request,
0063 |     user: CurrentUser = Depends(get_current_user),
0064 | ):
0065 |     from fastapi import HTTPException
0066 |
0067 |     verified = await firebase_request(
0068 |         request,
0069 |         "signInWithPassword",
0070 |         {"email": user.email, "password": payload.password, "returnSecureToken": True},
0071 |     )
0072 |     if verified.get("localId") != user.id:
0073 |         raise HTTPException(403, "Please sign in again.")
0074 |     return {"message": "Session unlocked."}
0075 |
0076 |
0077 | @router.post("/profile/password")
0078 | async def change_password(
0079 |     payload: PasswordEdit,
0080 |     request: Request,
0081 |     user: CurrentUser = Depends(get_current_user),
0082 | ):
0083 |     if payload.current_password == payload.new_password:
0084 |         from fastapi import HTTPException
0085 |
0086 |         raise HTTPException(
0087 |             422, "Choose a new password different from your current password."
0088 |         )
0089 |     verified = await firebase_request(
0090 |         request,
0091 |         "signInWithPassword",
0092 |         {
0093 |             "email": user.email,
0094 |             "password": payload.current_password,
0095 |             "returnSecureToken": True,
0096 |         },
0097 |     )
0098 |     result = await firebase_request(
0099 |         request,
0100 |         "update",
0101 |         {
0102 |             "idToken": verified["idToken"],
0103 |             "password": payload.new_password,
0104 |             "returnSecureToken": True,
0105 |         },
0106 |     )
0107 |     result["localId"] = user.id
0108 |     store = FirebaseGateway(request)
0109 |     await asyncio.to_thread(
0110 |         store.db.collection("profiles").document(user.id).update,
0111 |         {"must_change_password": False},
0112 |     )
0113 |     return await session(request, result)
```

## services/api/app/routers/workspace.py

592 lines. SHA-256: `59421ad5c8d440683db45575a4d5cd7d9f305be366131854c630872d7e5b19df`.

Symbols: `staff`: L34–L36; `administrator`: L39–L41; `officers`: L45–L62; `claim_action`: L66–L76; `information_response`: L80–L225; `finish_information_processing`: L228–L235; `notifications`: L239–L253; `read_notice`: L257–L270; `audit`: L274–L302; `analytics`: L306–L346; `UserCreate`: L349–L362; `UserEdit`: L365–L379; `users`: L383–L395; `create_user`: L399–L432; `account_event`: L435–L446; `change_user`: L449–L500; `edit_user`: L504–L513; `delete_user`: L517–L527; `user_reset`: L531–L544; `AdminPassword`: L547–L549; `set_user_password`: L553–L592; `load`: L49–L60; `load`: L244–L251; `mark`: L262–L267; `load`: L282–L300; `valid_permissions`: L357–L362; `valid_name`: L376–L379; `change`: L453–L498; `submit`: L138–L199

```python
0001 | import asyncio
0002 | from collections import Counter, defaultdict
0003 | from datetime import date
0004 | from decimal import Decimal
0005 | from pathlib import Path
0006 | from typing import Literal
0007 | import re
0008 | import uuid
0009 |
0010 | from fastapi import (
0011 |     APIRouter,
0012 |     BackgroundTasks,
0013 |     Depends,
0014 |     File,
0015 |     Form,
0016 |     HTTPException,
0017 |     Request,
0018 |     UploadFile,
0019 | )
0020 | from firebase_admin import auth, firestore
0021 | from google.cloud.firestore_v1.base_query import FieldFilter
0022 | from pydantic import BaseModel, Field, field_validator
0023 |
0024 | from ..firebase import FirebaseGateway, now
0025 | from ..schemas import SignupRequest
0026 | from ..permissions import PERMISSIONS, require
0027 | from ..security import CurrentUser, get_current_user
0028 | from ..workflow import WorkflowInput, apply_action, write_event, STAFF
0029 | from .claims import accessible_claim, valid_signature, ALLOWED_MIME_TYPES
0030 |
0031 | router = APIRouter(tags=["workspace"])
0032 |
0033 |
0034 | def staff(user):
0035 |     if user.profile.role not in STAFF:
0036 |         raise HTTPException(403, "Staff permission required.")
0037 |
0038 |
0039 | def administrator(user):
0040 |     if user.profile.role != "administrator":
0041 |         raise HTTPException(403, "Administrator permission required.")
0042 |
0043 |
0044 | @router.get("/workspace/officers")
0045 | async def officers(request: Request, user: CurrentUser = Depends(get_current_user)):
0046 |     staff(user)
0047 |     store = FirebaseGateway(request)
0048 |
0049 |     def load():
0050 |         rows = [
0051 |             s.to_dict()
0052 |             for s in store.db.collection("profiles")
0053 |             .where(filter=FieldFilter("role", "==", "claims_officer"))
0054 |             .stream()
0055 |         ]
0056 |         return [
0057 |             {"id": r["id"], "display_name": r["display_name"]}
0058 |             for r in rows
0059 |             if r.get("status") == "active"
0060 |         ]
0061 |
0062 |     return await asyncio.to_thread(load)
0063 |
0064 |
0065 | @router.post("/claims/{reference}/actions/{action}")
0066 | async def claim_action(
0067 |     reference: str,
0068 |     action: str,
0069 |     payload: WorkflowInput,
0070 |     request: Request,
0071 |     user: CurrentUser = Depends(get_current_user),
0072 | ):
0073 |     store = FirebaseGateway(request)
0074 |     claim = await accessible_claim(store, reference)
0075 |     updated = await apply_action(store, claim["id"], action, payload)
0076 |     return {"status": updated["status"], "message": "Claim updated successfully."}
0077 |
0078 |
0079 | @router.post("/claims/{reference}/information/{request_id}/respond")
0080 | async def information_response(
0081 |     reference: str,
0082 |     request_id: str,
0083 |     request: Request,
0084 |     background_tasks: BackgroundTasks,
0085 |     background: bool = Form(default=False),
0086 |     response_text: str = Form(default="", max_length=4000),
0087 |     files: list[UploadFile] = File(default=[]),
0088 |     user: CurrentUser = Depends(get_current_user),
0089 | ):
0090 |     store = FirebaseGateway(request)
0091 |     claim = await accessible_claim(store, reference)
0092 |     if (
0093 |         user.profile.role != "client"
0094 |         or claim.get("client_id") != user.id
0095 |         or claim["status"] != "INFORMATION_REQUIRED"
0096 |     ):
0097 |         raise HTTPException(
0098 |             403, "Only the claim owner can respond to this information request."
0099 |         )
0100 |     if not response_text.strip() and not files:
0101 |         raise HTTPException(422, "Enter a response or attach supporting documents.")
0102 |     if len(files) > store.settings.max_claim_documents:
0103 |         raise HTTPException(422, "Too many documents in this response.")
0104 |     existing = await store.records(
0105 |         "GET", "claim_documents", params={"claim_id": f"eq.{claim['id']}"}
0106 |     )
0107 |     if len(existing) + len(files) > store.settings.max_claim_documents:
0108 |         raise HTTPException(422, "A claim can have at most ten documents.")
0109 |     prepared = []
0110 |     for upload in files:
0111 |         content = await upload.read(store.settings.max_file_bytes + 1)
0112 |         if (
0113 |             upload.content_type not in ALLOWED_MIME_TYPES
0114 |             or not content
0115 |             or len(content) > store.settings.max_file_bytes
0116 |             or not valid_signature(content, upload.content_type)
0117 |         ):
0118 |             raise HTTPException(
0119 |                 422, "Attach valid PDF, Word, PNG, or JPEG files under 10 MB."
0120 |             )
0121 |         name = re.sub(
0122 |             r"[^A-Za-z0-9._-]", "_", Path(upload.filename or "document").name
0123 |         )[:160]
0124 |         path = f"{user.id}/{claim['id']}/{uuid.uuid4().hex}-{name}"
0125 |         prepared.append((path, content, upload.content_type, name, str(uuid.uuid4())))
0126 |     uploaded = []
0127 |     committed = False
0128 |     try:
0129 |         for path, content, mime, _, _ in prepared:
0130 |             await store.upload(path, content, mime)
0131 |             uploaded.append(path)
0132 |         ref = store.db.collection("claims").document(claim["id"])
0133 |         info_ref = store.db.collection("claim_information_requests").document(
0134 |             request_id
0135 |         )
0136 |
0137 |         @firestore.transactional
0138 |         def submit(transaction):
0139 |             current = ref.get(transaction=transaction).to_dict()
0140 |             info = info_ref.get(transaction=transaction)
0141 |             if (
0142 |                 not current
0143 |                 or current.get("client_id") != user.id
0144 |                 or current["status"] != "INFORMATION_REQUIRED"
0145 |                 or not info.exists
0146 |                 or info.to_dict().get("claim_id") != claim["id"]
0147 |                 or info.to_dict().get("status") != "OPEN"
0148 |             ):
0149 |                 raise HTTPException(409, "This information request is no longer open.")
0150 |             transaction.update(
0151 |                 info_ref,
0152 |                 {
0153 |                     "status": "ANSWERED",
0154 |                     "response_text": response_text.strip(),
0155 |                     "responded_at": now(),
0156 |                     "document_count": len(prepared),
0157 |                 },
0158 |             )
0159 |             transaction.update(
0160 |                 ref,
0161 |                 {
0162 |                     "status": "PROCESSING" if prepared else "INFORMATION_RECEIVED",
0163 |                     "needs_reconfirmation": bool(prepared),
0164 |                     "updated_at": now(),
0165 |                 },
0166 |             )
0167 |             for path, content, mime, name, identifier in prepared:
0168 |                 transaction.set(
0169 |                     store.db.collection("claim_documents").document(identifier),
0170 |                     {
0171 |                         "id": identifier,
0172 |                         "claim_id": claim["id"],
0173 |                         "uploaded_by": user.id,
0174 |                         "information_request_id": request_id,
0175 |                         "original_name": name,
0176 |                         "storage_path": path,
0177 |                         "mime_type": mime,
0178 |                         "size_bytes": len(content),
0179 |                         "document_type": "UNKNOWN",
0180 |                         "extraction_status": "PENDING",
0181 |                         "include_in_total": False,
0182 |                         "created_at": now(),
0183 |                     },
0184 |                 )
0185 |             write_event(
0186 |                 store.db,
0187 |                 transaction,
0188 |                 current,
0189 |                 user.id,
0190 |                 "INFORMATION_RECEIVED",
0191 |                 {"document_count": len(prepared)},
0192 |             )
0193 |             if prepared and background:
0194 |                 from ..jobs import queue_record
0195 |
0196 |                 transaction.set(
0197 |                     store.db.collection("processing_queue").document(claim["id"]),
0198 |                     queue_record({**current, "needs_reconfirmation": True}, user.id),
0199 |                 )
0200 |
0201 |         await asyncio.to_thread(submit, store.db.transaction())
0202 |         committed = True
0203 |         if prepared:
0204 |             if background:
0205 |                 return {
0206 |                     "message": "Your response was submitted. Supporting documents are being processed."
0207 |                 }
0208 |             # Process the added evidence without returning the submitted claim to draft.
0209 |             from ..processing import process_claim
0210 |
0211 |             try:
0212 |                 await process_claim(
0213 |                     store, claim, user.id, return_status="INFORMATION_RECEIVED"
0214 |                 )
0215 |             except Exception:
0216 |                 await asyncio.to_thread(
0217 |                     ref.update, {"status": "PROCESSING_FAILED", "updated_at": now()}
0218 |                 )
0219 |                 return {
0220 |                     "message": "Your response was saved. Document processing needs a retry from the claim page."
0221 |                 }
0222 |         return {"message": "Your response was submitted to the review team."}
0223 |     finally:
0224 |         if not committed and uploaded:
0225 |             await store.delete_objects(uploaded)
0226 |
0227 |
0228 | async def finish_information_processing(store, claim, actor):
0229 |     from .claims import finish_processing
0230 |
0231 |     try:
0232 |         await finish_processing(store, {**claim, "needs_reconfirmation": True}, actor)
0233 |     except Exception:
0234 |         # finish_processing records PROCESSING_FAILED; the response remains saved.
0235 |         pass
0236 |
0237 |
0238 | @router.get("/notifications")
0239 | async def notifications(
0240 |     request: Request, user: CurrentUser = Depends(get_current_user)
0241 | ):
0242 |     store = FirebaseGateway(request)
0243 |
0244 |     def load():
0245 |         rows = [
0246 |             s.to_dict()
0247 |             for s in store.db.collection("notifications")
0248 |             .where(filter=FieldFilter("recipient_id", "==", user.id))
0249 |             .stream()
0250 |         ]
0251 |         return sorted(rows, key=lambda r: r.get("created_at", ""), reverse=True)[:100]
0252 |
0253 |     return await asyncio.to_thread(load)
0254 |
0255 |
0256 | @router.post("/notifications/{identifier}/read")
0257 | async def read_notice(
0258 |     identifier: str, request: Request, user: CurrentUser = Depends(get_current_user)
0259 | ):
0260 |     store = FirebaseGateway(request)
0261 |
0262 |     def mark():
0263 |         ref = store.db.collection("notifications").document(identifier)
0264 |         snapshot = ref.get()
0265 |         if not snapshot.exists or snapshot.to_dict().get("recipient_id") != user.id:
0266 |             raise HTTPException(404, "Notification not found.")
0267 |         ref.update({"read": True})
0268 |
0269 |     await asyncio.to_thread(mark)
0270 |     return {"message": "Notification marked as read."}
0271 |
0272 |
0273 | @router.get("/workspace/audit")
0274 | async def audit(
0275 |     request: Request, search: str = "", user: CurrentUser = Depends(get_current_user)
0276 | ):
0277 |     require(user, "audit.view")
0278 |     store = FirebaseGateway(request)
0279 |     claims = await store.records("GET", "claims")
0280 |     allowed = {c["id"]: c["reference"] for c in claims}
0281 |
0282 |     def load():
0283 |         rows = []
0284 |         for snapshot in store.db.collection("audit_events").stream():
0285 |             value = snapshot.to_dict()
0286 |             if value.get("claim_id") in allowed or (
0287 |                 user.profile.role == "administrator" and not value.get("claim_id")
0288 |             ):
0289 |                 value["reference"] = allowed.get(
0290 |                     value.get("claim_id"), "Account administration"
0291 |                 )
0292 |                 if (
0293 |                     not search
0294 |                     or search.lower()
0295 |                     in (value["reference"] + " " + value["event_type"]).lower()
0296 |                 ):
0297 |                     rows.append(value)
0298 |         return sorted(rows, key=lambda row: row.get("created_at", ""), reverse=True)[
0299 |             :200
0300 |         ]
0301 |
0302 |     return await asyncio.to_thread(load)
0303 |
0304 |
0305 | @router.get("/workspace/analytics")
0306 | async def analytics(
0307 |     request: Request,
0308 |     from_date: date | None = None,
0309 |     to_date: date | None = None,
0310 |     user: CurrentUser = Depends(get_current_user),
0311 | ):
0312 |     require(user, "analytics.view")
0313 |     if from_date and to_date and from_date > to_date:
0314 |         raise HTTPException(422, "Start date must be before the end date.")
0315 |     rows = await FirebaseGateway(request).records("GET", "claims")
0316 |     rows = [
0317 |         r
0318 |         for r in rows
0319 |         if (not from_date or r["created_at"][:10] >= from_date.isoformat())
0320 |         and (not to_date or r["created_at"][:10] <= to_date.isoformat())
0321 |     ]
0322 |     totals = defaultdict(
0323 |         lambda: {"claimed": Decimal(0), "approved": Decimal(0), "paid": Decimal(0)}
0324 |     )
0325 |     for row in rows:
0326 |         currency = row.get("currency", "MUR")
0327 |         totals[currency]["claimed"] += Decimal(str(row.get("claimed_amount") or 0))
0328 |         totals[currency]["approved"] += Decimal(str(row.get("approved_amount") or 0))
0329 |         if row["status"] == "PAID":
0330 |             totals[currency]["paid"] += Decimal(str(row.get("approved_amount") or 0))
0331 |     return {
0332 |         "total": len(rows),
0333 |         "by_status": dict(Counter(r["status"] for r in rows)),
0334 |         "monthly": dict(sorted(Counter(r["created_at"][:7] for r in rows).items())),
0335 |         "amounts": {
0336 |             k: {n: str(v) for n, v in amounts.items()} for k, amounts in totals.items()
0337 |         },
0338 |         "unassigned": sum(
0339 |             not r.get("assigned_to")
0340 |             and r["status"] in {"REVIEW_REQUIRED", "INFORMATION_RECEIVED"}
0341 |             for r in rows
0342 |         ),
0343 |         "scope": "Assigned and unassigned review claims"
0344 |         if user.profile.role == "claims_officer"
0345 |         else "All accessible claims",
0346 |     }
0347 |
0348 |
0349 | class UserCreate(SignupRequest):
0350 |     role: Literal[
0351 |         "client", "claims_officer", "supervisor", "administrator", "finance"
0352 |     ] = "client"
0353 |     permissions: list[str] = Field(default_factory=list, max_length=7)
0354 |
0355 |     @field_validator("permissions")
0356 |     @classmethod
0357 |     def valid_permissions(cls, values):
0358 |         if set(values) - PERMISSIONS or "users.manage" in values:
0359 |             raise ValueError(
0360 |                 "Choose valid claim, finance, analytics or audit permissions. User administration requires the administrator role."
0361 |             )
0362 |         return sorted(set(values))
0363 |
0364 |
0365 | class UserEdit(BaseModel):
0366 |     display_name: str = Field(min_length=2, max_length=120)
0367 |     role: Literal["client", "claims_officer", "supervisor", "administrator", "finance"]
0368 |     permissions: list[str] = Field(default_factory=list, max_length=7)
0369 |     valid_permissions = field_validator("permissions")(
0370 |         UserCreate.valid_permissions.__func__
0371 |     )
0372 |     status: Literal["active", "inactive"]
0373 |
0374 |     @field_validator("display_name")
0375 |     @classmethod
0376 |     def valid_name(cls, value):
0377 |         if len(value.strip()) < 2:
0378 |             raise ValueError("Enter a name with at least two characters.")
0379 |         return value.strip()
0380 |
0381 |
0382 | @router.get("/users")
0383 | async def users(request: Request, user: CurrentUser = Depends(get_current_user)):
0384 |     administrator(user)
0385 |     store = FirebaseGateway(request)
0386 |     return await asyncio.to_thread(
0387 |         lambda: sorted(
0388 |             [
0389 |                 s.to_dict()
0390 |                 for s in store.db.collection("profiles").stream()
0391 |                 if not s.to_dict().get("deleted")
0392 |             ],
0393 |             key=lambda row: row.get("display_name", "").lower(),
0394 |         )
0395 |     )
0396 |
0397 |
0398 | @router.post("/users", status_code=201)
0399 | async def create_user(
0400 |     payload: UserCreate, request: Request, user: CurrentUser = Depends(get_current_user)
0401 | ):
0402 |     administrator(user)
0403 |     store = FirebaseGateway(request)
0404 |     try:
0405 |         created = await asyncio.to_thread(
0406 |             auth.create_user,
0407 |             email=payload.email.strip().lower(),
0408 |             password=payload.password,
0409 |             display_name=payload.display_name.strip(),
0410 |             app=store.app,
0411 |         )
0412 |     except auth.EmailAlreadyExistsError:
0413 |         raise HTTPException(409, "This email already has an account.")
0414 |     try:
0415 |         record = {
0416 |             "id": created.uid,
0417 |             "display_name": payload.display_name.strip(),
0418 |             "email": payload.email.strip().lower(),
0419 |             "role": payload.role,
0420 |             "status": "active",
0421 |             "created_at": now(),
0422 |             "permissions": [] if payload.role == "client" else payload.permissions,
0423 |             "must_change_password": True,
0424 |         }
0425 |         await asyncio.to_thread(
0426 |             store.db.collection("profiles").document(created.uid).create, record
0427 |         )
0428 |     except Exception:
0429 |         await asyncio.to_thread(auth.delete_user, created.uid, app=store.app)
0430 |         raise
0431 |     await account_event(store, user.id, "USER_CREATED", created.uid)
0432 |     return record
0433 |
0434 |
0435 | async def account_event(store, actor, event, target):
0436 |     ref = store.db.collection("audit_events").document()
0437 |     await asyncio.to_thread(
0438 |         ref.set,
0439 |         {
0440 |             "id": ref.id,
0441 |             "actor_id": actor,
0442 |             "event_type": event,
0443 |             "metadata": {"target_user_id": target},
0444 |             "created_at": now(),
0445 |         },
0446 |     )
0447 |
0448 |
0449 | async def change_user(store, user, uid, payload, delete=False):
0450 |     ref = store.db.collection("profiles").document(uid)
0451 |
0452 |     @firestore.transactional
0453 |     def change(transaction):
0454 |         snapshot = ref.get(transaction=transaction)
0455 |         if not snapshot.exists:
0456 |             raise HTTPException(404, "User not found.")
0457 |         old = snapshot.to_dict()
0458 |         if uid == user.id and (
0459 |             delete or payload.role != "administrator" or payload.status != "active"
0460 |         ):
0461 |             raise HTTPException(
0462 |                 422,
0463 |                 "You cannot disable, delete, or demote your own administrator account.",
0464 |             )
0465 |         admins = list(
0466 |             store.db.collection("profiles")
0467 |             .where(filter=FieldFilter("role", "==", "administrator"))
0468 |             .stream(transaction=transaction)
0469 |         )
0470 |         if (
0471 |             old.get("role") == "administrator"
0472 |             and old.get("status") == "active"
0473 |             and (
0474 |                 delete or payload.role != "administrator" or payload.status != "active"
0475 |             )
0476 |             and sum(a.to_dict().get("status") == "active" for a in admins) <= 1
0477 |         ):
0478 |             raise HTTPException(422, "At least one active administrator must remain.")
0479 |         update = (
0480 |             {"status": "inactive", "deleted": True} if delete else payload.model_dump()
0481 |         )
0482 |         transaction.update(ref, update)
0483 |         event = store.db.collection("audit_events").document()
0484 |         transaction.set(
0485 |             event,
0486 |             {
0487 |                 "id": event.id,
0488 |                 "actor_id": user.id,
0489 |                 "event_type": "USER_DELETED" if delete else "USER_ACCESS_UPDATED",
0490 |                 "metadata": {
0491 |                     "target_user_id": uid,
0492 |                     "previous_role": old.get("role"),
0493 |                     "new_role": update.get("role", old.get("role")),
0494 |                     "status": update["status"],
0495 |                 },
0496 |                 "created_at": now(),
0497 |             },
0498 |         )
0499 |
0500 |     await asyncio.to_thread(change, store.db.transaction())
0501 |
0502 |
0503 | @router.put("/users/{uid}")
0504 | async def edit_user(
0505 |     uid: str,
0506 |     payload: UserEdit,
0507 |     request: Request,
0508 |     user: CurrentUser = Depends(get_current_user),
0509 | ):
0510 |     administrator(user)
0511 |     store = FirebaseGateway(request)
0512 |     await change_user(store, user, uid, payload)
0513 |     return {"message": "User access updated."}
0514 |
0515 |
0516 | @router.delete("/users/{uid}")
0517 | async def delete_user(
0518 |     uid: str, request: Request, user: CurrentUser = Depends(get_current_user)
0519 | ):
0520 |     administrator(user)
0521 |     store = FirebaseGateway(request)
0522 |     await change_user(store, user, uid, None, delete=True)
0523 |     try:
0524 |         await asyncio.to_thread(auth.delete_user, uid, app=store.app)
0525 |     except auth.UserNotFoundError:
0526 |         pass
0527 |     return {"message": "Login account deleted. Claim and audit records are retained."}
0528 |
0529 |
0530 | @router.post("/users/{uid}/password-reset")
0531 | async def user_reset(
0532 |     uid: str, request: Request, user: CurrentUser = Depends(get_current_user)
0533 | ):
0534 |     administrator(user)
0535 |     store = FirebaseGateway(request)
0536 |     target = await asyncio.to_thread(auth.get_user, uid, app=store.app)
0537 |     link = await asyncio.to_thread(
0538 |         auth.generate_password_reset_link, target.email, app=store.app
0539 |     )
0540 |     await account_event(store, user.id, "PASSWORD_RECOVERY_CREATED", uid)
0541 |     return {
0542 |         "link": link,
0543 |         "message": "Share this recovery link privately with the account owner.",
0544 |     }
0545 |
0546 |
0547 | class AdminPassword(BaseModel):
0548 |     new_password: str = Field(min_length=12, max_length=128)
0549 |     admin_password: str = Field(min_length=1, max_length=128)
0550 |
0551 |
0552 | @router.post("/users/{uid}/password")
0553 | async def set_user_password(
0554 |     uid: str,
0555 |     payload: AdminPassword,
0556 |     request: Request,
0557 |     user: CurrentUser = Depends(get_current_user),
0558 | ):
0559 |     administrator(user)
0560 |     if uid == user.id:
0561 |         raise HTTPException(422, "Use Account → Change password for your own account.")
0562 |     from .auth import firebase_request
0563 |
0564 |     verified = await firebase_request(
0565 |         request,
0566 |         "signInWithPassword",
0567 |         {
0568 |             "email": user.email,
0569 |             "password": payload.admin_password,
0570 |             "returnSecureToken": True,
0571 |         },
0572 |     )
0573 |     if verified.get("localId") != user.id:
0574 |         raise HTTPException(403, "Administrator authentication failed.")
0575 |     store = FirebaseGateway(request)
0576 |     profile = await store.profile(uid)
0577 |     if not profile or profile.get("deleted"):
0578 |         raise HTTPException(404, "User not found.")
0579 |     await asyncio.to_thread(
0580 |         auth.update_user, uid, password=payload.new_password, app=store.app
0581 |     )
0582 |     # Firebase invalidates existing refresh tokens when the password changes.
0583 |     # Avoid a second, local-clock revocation after the update: clock skew could
0584 |     # otherwise invalidate a user's immediate sign-in with the new password.
0585 |     await asyncio.to_thread(
0586 |         store.db.collection("profiles").document(uid).update,
0587 |         {"must_change_password": True},
0588 |     )
0589 |     await account_event(store, user.id, "TEMPORARY_PASSWORD_SET", uid)
0590 |     return {
0591 |         "message": "Temporary password set. The user must change it when they sign in."
0592 |     }
```

## services/api/app/schemas.py

154 lines. SHA-256: `30238fcaf60f8994549a83aff518d20c2347023112cb3a0f6541f63e35f78b52`.

Symbols: `Profile`: L14–L26; `LoginRequest`: L29–L31; `RefreshRequest`: L34–L35; `AuthSession`: L38–L43; `ExtractedField`: L46–L54; `ClaimDocument`: L57–L76; `ClaimSummary`: L79–L89; `ClaimDetails`: L92–L98; `DocumentConfirmation`: L101–L105; `FieldCorrection`: L108–L110; `ConfirmClaimRequest`: L113–L117; `ProcessResult`: L120–L124; `DashboardSummary`: L127–L136; `EmailRequest`: L139–L142; `SignupRequest`: L145–L154; `valid_name`: L151–L154

```python
0001 | from __future__ import annotations
0002 |
0003 | from datetime import datetime
0004 | from decimal import Decimal
0005 | from typing import Any, Literal
0006 | from uuid import UUID
0007 |
0008 | from pydantic import BaseModel, Field, field_validator
0009 |
0010 |
0011 | Role = Literal["client", "claims_officer", "supervisor", "administrator", "finance"]
0012 |
0013 |
0014 | class Profile(BaseModel):
0015 |     id: str
0016 |     display_name: str
0017 |     role: Role
0018 |     status: str
0019 |     email: str | None = None
0020 |     phone: str = ""
0021 |     theme: Literal["system", "light", "dark"] = "system"
0022 |     notifications_enabled: bool = True
0023 |     permissions: list[str] = Field(default_factory=list)
0024 |     email_verified: bool = False
0025 |     must_change_password: bool = False
0026 |     verification_required: bool = False
0027 |
0028 |
0029 | class LoginRequest(BaseModel):
0030 |     email: str = Field(min_length=3)
0031 |     password: str = Field(min_length=1)
0032 |
0033 |
0034 | class RefreshRequest(BaseModel):
0035 |     refresh_token: str = Field(min_length=1)
0036 |
0037 |
0038 | class AuthSession(BaseModel):
0039 |     access_token: str
0040 |     refresh_token: str
0041 |     expires_in: int
0042 |     token_type: str = "bearer"
0043 |     user: Profile
0044 |
0045 |
0046 | class ExtractedField(BaseModel):
0047 |     id: str | None = None
0048 |     document_id: str | None = None
0049 |     field_name: str
0050 |     raw_value: str
0051 |     normalized_value: str
0052 |     confidence: float
0053 |     extraction_method: str
0054 |     page_number: int = 1
0055 |
0056 |
0057 | class ClaimDocument(BaseModel):
0058 |     id: str
0059 |     original_name: str
0060 |     document_type: str
0061 |     mime_type: str
0062 |     size_bytes: int
0063 |     extraction_status: str
0064 |     extracted_amount: Decimal | None = None
0065 |     extracted_currency: str | None = None
0066 |     confirmed_amount: Decimal | None = None
0067 |     confirmed_currency: str | None = None
0068 |     client_proposed_amount: Decimal | None = None
0069 |     client_proposed_currency: str | None = None
0070 |     client_reported_incorrect_amount: bool = False
0071 |     amount_confidence: float | None = None
0072 |     include_in_total: bool = False
0073 |     duplicate_of: str | None = None
0074 |     extraction_notes: str | None = None
0075 |     signed_url: str | None = None
0076 |     fields: list[ExtractedField] = Field(default_factory=list)
0077 |
0078 |
0079 | class ClaimSummary(BaseModel):
0080 |     id: str
0081 |     reference: str
0082 |     patient_name: str
0083 |     provider_name: str
0084 |     claimed_amount: Decimal | None = None
0085 |     currency: str
0086 |     status: str
0087 |     warning_count: int = 0
0088 |     created_at: datetime
0089 |     assigned_to: str | None = None
0090 |
0091 |
0092 | class ClaimDetails(ClaimSummary):
0093 |     information: dict[str, Any] = Field(default_factory=dict)
0094 |     documents: list[ClaimDocument] = Field(default_factory=list)
0095 |     audit_events: list[dict[str, Any]] = Field(default_factory=list)
0096 |     available_actions: list[str] = Field(default_factory=list)
0097 |     information_requests: list[dict[str, Any]] = Field(default_factory=list)
0098 |     workflow: dict[str, Any] = Field(default_factory=dict)
0099 |
0100 |
0101 | class DocumentConfirmation(BaseModel):
0102 |     id: str
0103 |     include: bool
0104 |     amount: Decimal | None = None
0105 |     currency: str | None = None
0106 |
0107 |
0108 | class FieldCorrection(BaseModel):
0109 |     id: UUID
0110 |     value: str = Field(min_length=1, max_length=500)
0111 |
0112 |
0113 | class ConfirmClaimRequest(BaseModel):
0114 |     patient_name: str = Field(min_length=2, max_length=200)
0115 |     provider_name: str = Field(min_length=2, max_length=200)
0116 |     documents: list[DocumentConfirmation]
0117 |     fields: list[FieldCorrection] = Field(default_factory=list)
0118 |
0119 |
0120 | class ProcessResult(BaseModel):
0121 |     claim_reference: str
0122 |     status: str
0123 |     document_count: int
0124 |     extracted_field_count: int
0125 |
0126 |
0127 | class DashboardSummary(BaseModel):
0128 |     action_required_claims: list[ClaimSummary] = Field(default_factory=list)
0129 |     unassigned: int = 0
0130 |     by_status: dict[str, int] = Field(default_factory=dict)
0131 |     total_claims: int
0132 |     processing: int
0133 |     review_required: int
0134 |     verified: int
0135 |     processing_failed: int
0136 |     recent_claims: list[ClaimSummary]
0137 |
0138 |
0139 | class EmailRequest(BaseModel):
0140 |     email: str = Field(
0141 |         min_length=3, max_length=254, pattern=r"^[^\s@]+@[^\s@]+\.[^\s@]+$"
0142 |     )
0143 |
0144 |
0145 | class SignupRequest(EmailRequest):
0146 |     display_name: str = Field(min_length=2, max_length=120)
0147 |     password: str = Field(min_length=12, max_length=128)
0148 |
0149 |     @field_validator("display_name")
0150 |     @classmethod
0151 |     def valid_name(cls, value):
0152 |         if len(value.strip()) < 2:
0153 |             raise ValueError("Enter a name with at least two characters.")
0154 |         return value.strip()
```

## services/api/app/security.py

65 lines. SHA-256: `5d4bffbf70e9f2ae4afe412e54234788dbdfb6cc0515c8cb40f748e17a05e554`.

Symbols: `CurrentUser`: L18–L22; `get_current_user`: L25–L65

```python
0001 | from __future__ import annotations
0002 |
0003 | from dataclasses import dataclass
0004 | import asyncio
0005 | from firebase_admin import auth
0006 |
0007 | from fastapi import Depends, HTTPException, Request, status
0008 | from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
0009 |
0010 | from .schemas import Profile
0011 | from .firebase import FirebaseGateway, firebase_app
0012 |
0013 |
0014 | bearer = HTTPBearer(auto_error=False)
0015 |
0016 |
0017 | @dataclass(frozen=True)
0018 | class CurrentUser:
0019 |     id: str
0020 |     email: str | None
0021 |     token: str
0022 |     profile: Profile
0023 |
0024 |
0025 | async def get_current_user(
0026 |     request: Request,
0027 |     credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
0028 | ) -> CurrentUser:
0029 |     if not credentials or credentials.scheme.lower() != "bearer":
0030 |         raise HTTPException(
0031 |             status_code=status.HTTP_401_UNAUTHORIZED, detail="Authentication required."
0032 |         )
0033 |
0034 |     try:
0035 |         user = await asyncio.to_thread(
0036 |             auth.verify_id_token,
0037 |             credentials.credentials,
0038 |             app=firebase_app(),
0039 |             check_revoked=True,
0040 |         )
0041 |     except (auth.InvalidIdTokenError, auth.UserNotFoundError, ValueError):
0042 |         raise HTTPException(401, "Your session has expired. Please sign in again.")
0043 |     gateway = FirebaseGateway(request)
0044 |     record = await gateway.profile(user["uid"])
0045 |     if not record or record.get("status") != "active":
0046 |         raise HTTPException(
0047 |             status_code=status.HTTP_403_FORBIDDEN, detail="This account is not active."
0048 |         )
0049 |     profile = Profile(**record)
0050 |     profile.email_verified = bool(user.get("email_verified", False))
0051 |     if profile.must_change_password and request.url.path not in {
0052 |         "/api/v1/profile",
0053 |         "/api/v1/profile/password",
0054 |         "/api/v1/profile/unlock",
0055 |         "/api/v1/auth/logout",
0056 |     }:
0057 |         raise HTTPException(403, "Change your temporary password before continuing.")
0058 |     current = CurrentUser(
0059 |         id=user["uid"],
0060 |         email=user.get("email"),
0061 |         token=credentials.credentials,
0062 |         profile=profile,
0063 |     )
0064 |     request.state.current_user = current
0065 |     return current
```

## services/api/app/serve.py

24 lines. SHA-256: `bcb29a8e265c85cabc38886980b3ec81f6dab179603f08d12925e1db8c8772de`.

Symbols: `main`: L11–L20

```python
0001 | """Start the mobile API after PaddleOCR models are ready."""
0002 |
0003 | import argparse
0004 | import logging
0005 |
0006 | import uvicorn
0007 |
0008 | from .ocr import _engine
0009 |
0010 |
0011 | def main() -> None:
0012 |     parser = argparse.ArgumentParser(description=__doc__)
0013 |     parser.add_argument("--host", default="127.0.0.1")
0014 |     parser.add_argument("--port", type=int, default=8000)
0015 |     args = parser.parse_args()
0016 |     logging.basicConfig(level=logging.INFO)
0017 |     logging.info("Loading PaddleOCR models before accepting uploads...")
0018 |     _engine()
0019 |     logging.info("PaddleOCR models are ready.")
0020 |     uvicorn.run("app.main:app", host=args.host, port=args.port)
0021 |
0022 |
0023 | if __name__ == "__main__":
0024 |     main()
```

## services/api/app/workflow.py

451 lines. SHA-256: `c885f03abca87848505e687e7d7edd665706e1d1ca41e4b688a654016b19474a`.

Symbols: `WorkflowInput`: L22–L54; `available_actions`: L57–L88; `workflow_patch`: L91–L187; `write_event`: L190–L222; `apply_action`: L225–L396; `workflow_details`: L399–L451; `checked_documents`: L42–L46; `checked_fields`: L50–L54; `run`: L231–L394; `load`: L400–L449

```python
0001 | """Role-aware claim workflow shared by the API and its regression tests."""
0002 |
0003 | import asyncio
0004 | from datetime import date, datetime
0005 | from decimal import Decimal
0006 | from zoneinfo import ZoneInfo
0007 |
0008 | from fastapi import HTTPException
0009 | from firebase_admin import firestore
0010 | from google.cloud.firestore_v1.base_query import FieldFilter
0011 | from pydantic import BaseModel, Field, field_validator
0012 | from .schemas import DocumentConfirmation, FieldCorrection
0013 |
0014 | from .firebase import can_access_claim, now
0015 | from .permissions import permissions
0016 |
0017 | STAFF = {"claims_officer", "supervisor", "administrator", "finance"}
0018 | MANAGEMENT = {"supervisor", "administrator"}
0019 | REVIEWABLE = {"REVIEW_REQUIRED", "INFORMATION_RECEIVED"}
0020 |
0021 |
0022 | class WorkflowInput(BaseModel):
0023 |     assignee: str | None = None
0024 |     notes: str = Field(default="", max_length=2000)
0025 |     approved_amount: Decimal | None = Field(
0026 |         default=None, gt=0, max_digits=14, decimal_places=2
0027 |     )
0028 |     patient_name: str | None = Field(default=None, min_length=2, max_length=200)
0029 |     provider_name: str | None = Field(default=None, min_length=2, max_length=200)
0030 |     reason: str = Field(default="", max_length=500)
0031 |     questions: str = Field(default="", max_length=2000)
0032 |     required_documents: str = Field(default="", max_length=1000)
0033 |     response_deadline: date | None = None
0034 |     internal_note: str = Field(default="", max_length=2000)
0035 |     documents: list[dict] = Field(default_factory=list, max_length=10)
0036 |     fields: list[dict] = Field(default_factory=list, max_length=100)
0037 |     payment_reference: str = Field(default="", max_length=120)
0038 |     payment_method: str = Field(default="", max_length=60)
0039 |
0040 |     @field_validator("documents", mode="before")
0041 |     @classmethod
0042 |     def checked_documents(cls, values):
0043 |         return [
0044 |             DocumentConfirmation.model_validate(value).model_dump(mode="json")
0045 |             for value in values
0046 |         ]
0047 |
0048 |     @field_validator("fields", mode="before")
0049 |     @classmethod
0050 |     def checked_fields(cls, values):
0051 |         return [
0052 |             FieldCorrection.model_validate(value).model_dump(mode="json")
0053 |             for value in values
0054 |         ]
0055 |
0056 |
0057 | def available_actions(user, claim):
0058 |     role = user.profile.role
0059 |     status = claim["status"]
0060 |     result = []
0061 |     if role == "client":
0062 |         if status == "INFORMATION_REQUIRED":
0063 |             result.append("respond")
0064 |         return result
0065 |     if role not in STAFF:
0066 |         return result
0067 |     assigned = claim.get("assigned_to")
0068 |     rights = permissions(user.profile)
0069 |     if status in REVIEWABLE:
0070 |         if "claims.assign" in rights:
0071 |             result.append("assign")
0072 |         elif assigned is None and "claims.review" in rights:
0073 |             result.append("claim")
0074 |         if "claims.review" in rights and (
0075 |             role != "claims_officer" or assigned == user.id
0076 |         ):
0077 |             result += ["correct", "verify", "request-information"]
0078 |     if (
0079 |         "claims.decide" in rights
0080 |         and status == "VERIFIED"
0081 |         and claim.get("verified_by") != user.id
0082 |     ):
0083 |         result += ["approve", "reject"]
0084 |     if "payments.record" in rights and status == "APPROVED":
0085 |         result.append("payment-pending")
0086 |     if "payments.record" in rights and status == "PAYMENT_PENDING":
0087 |         result.append("paid")
0088 |     return result
0089 |
0090 |
0091 | def workflow_patch(user, claim, action, payload):
0092 |     if action not in available_actions(user, claim):
0093 |         raise HTTPException(
0094 |             403,
0095 |             "This action is not available for your role or the current claim status.",
0096 |         )
0097 |     patch = {"updated_at": now()}
0098 |     event = ""
0099 |     if action in {"assign", "claim"}:
0100 |         assignee = user.id if action == "claim" else payload.assignee
0101 |         if not assignee:
0102 |             raise HTTPException(422, "Choose an active claims officer.")
0103 |         patch["assigned_to"] = assignee
0104 |         event = "CLAIM_ASSIGNED"
0105 |     elif action == "correct":
0106 |         if (
0107 |             not payload.patient_name
0108 |             or not payload.patient_name.strip()
0109 |             or not payload.provider_name
0110 |             or not payload.provider_name.strip()
0111 |         ):
0112 |             raise HTTPException(422, "Enter patient and provider names.")
0113 |         patch.update(
0114 |             patient_name=payload.patient_name.strip(),
0115 |             provider_name=payload.provider_name.strip(),
0116 |             needs_reconfirmation=False,
0117 |             status="REVIEW_REQUIRED",
0118 |         )
0119 |         event = "CLAIM_CORRECTED"
0120 |     elif action == "verify":
0121 |         if (
0122 |             not claim.get("patient_name")
0123 |             or not claim.get("provider_name")
0124 |             or Decimal(str(claim.get("claimed_amount") or 0)) <= 0
0125 |             or claim.get("needs_reconfirmation")
0126 |         ):
0127 |             raise HTTPException(
0128 |                 422,
0129 |                 "Review the patient, provider, and document amounts before verifying.",
0130 |             )
0131 |         patch.update(status="VERIFIED", verified_by=user.id, verified_at=now())
0132 |         event = "CLAIM_VERIFIED"
0133 |     elif action in {"approve", "reject"}:
0134 |         if len(payload.notes.strip()) < 5:
0135 |             raise HTTPException(422, "Enter decision notes of at least 5 characters.")
0136 |         if action == "approve" and (
0137 |             payload.approved_amount is None
0138 |             or payload.approved_amount > Decimal(str(claim.get("claimed_amount") or 0))
0139 |         ):
0140 |             raise HTTPException(
0141 |                 422,
0142 |                 "Approved amount must be positive and no greater than the claim total.",
0143 |             )
0144 |         patch.update(
0145 |             status="APPROVED" if action == "approve" else "REJECTED",
0146 |             decision_notes=payload.notes.strip(),
0147 |             approved_amount=str(payload.approved_amount)
0148 |             if action == "approve"
0149 |             else None,
0150 |             decided_by=user.id,
0151 |             decided_at=now(),
0152 |         )
0153 |         event = "CLAIM_" + patch["status"]
0154 |     elif action in {"payment-pending", "paid"}:
0155 |         if action == "paid" and (
0156 |             len(payload.payment_reference.strip()) < 3
0157 |             or not payload.payment_method.strip()
0158 |         ):
0159 |             raise HTTPException(
0160 |                 422,
0161 |                 "Enter a payment reference and payment method before recording settlement.",
0162 |             )
0163 |         patch.update(
0164 |             status="PAYMENT_PENDING" if action == "payment-pending" else "PAID"
0165 |         )
0166 |         if action == "paid":
0167 |             patch["paid_at"] = now()
0168 |             patch.update(
0169 |                 payment_reference=payload.payment_reference.strip(),
0170 |                 payment_method=payload.payment_method.strip(),
0171 |                 paid_by=user.id,
0172 |             )
0173 |         event = "CLAIM_" + patch["status"]
0174 |     elif action == "request-information":
0175 |         if len(payload.reason.strip()) < 5 or len(payload.questions.strip()) < 5:
0176 |             raise HTTPException(
0177 |                 422, "Enter a clear reason and questions of at least 5 characters."
0178 |             )
0179 |         if (
0180 |             payload.response_deadline
0181 |             and payload.response_deadline
0182 |             < datetime.now(ZoneInfo("Indian/Mauritius")).date()
0183 |         ):
0184 |             raise HTTPException(422, "The response deadline cannot be in the past.")
0185 |         patch.update(status="INFORMATION_REQUIRED")
0186 |         event = "INFORMATION_REQUESTED"
0187 |     return patch, event
0188 |
0189 |
0190 | def write_event(db, transaction, claim, actor, event, metadata=None, watchers=()):
0191 |     ref = db.collection("audit_events").document()
0192 |     transaction.set(
0193 |         ref,
0194 |         {
0195 |             "id": ref.id,
0196 |             "claim_id": claim["id"],
0197 |             "actor_id": actor,
0198 |             "event_type": event,
0199 |             "metadata": metadata or {},
0200 |             "created_at": now(),
0201 |         },
0202 |     )
0203 |     for uid in (
0204 |         ({claim.get("client_id"), claim.get("assigned_to"), *watchers} - {None})
0205 |         if event != "FIELD_CORRECTED"
0206 |         else []
0207 |     ):
0208 |         notice = db.collection("notifications").document()
0209 |         transaction.set(
0210 |             notice,
0211 |             {
0212 |                 "id": notice.id,
0213 |                 "recipient_id": uid,
0214 |                 "claim_id": claim["id"],
0215 |                 "reference": claim["reference"],
0216 |                 "title": event.replace("_", " ").title(),
0217 |                 "body": f"{claim['reference']} has an update. Open the claim to see the details.",
0218 |                 "read": False,
0219 |                 "push_state": "PENDING",
0220 |                 "created_at": now(),
0221 |             },
0222 |         )
0223 |
0224 |
0225 | async def apply_action(gateway, claim_id, action, payload):
0226 |     user = gateway._user()
0227 |     db = gateway.db
0228 |     ref = db.collection("claims").document(claim_id)
0229 |
0230 |     @firestore.transactional
0231 |     def run(transaction):
0232 |         snapshot = ref.get(transaction=transaction)
0233 |         claim = snapshot.to_dict() if snapshot.exists else None
0234 |         if not claim or not can_access_claim(user, claim):
0235 |             raise HTTPException(404, "Claim not found.")
0236 |         patch, event = workflow_patch(user, claim, action, payload)
0237 |         watchers = []
0238 |         if action == "verify":
0239 |             watchers = [
0240 |                 snapshot.id
0241 |                 for snapshot in db.collection("profiles")
0242 |                 .where(
0243 |                     filter=FieldFilter("role", "in", ["supervisor", "administrator"])
0244 |                 )
0245 |                 .stream(transaction=transaction)
0246 |                 if snapshot.to_dict().get("status") == "active"
0247 |             ]
0248 |         docs = []
0249 |         fields = []
0250 |         if action in {"assign", "claim"}:
0251 |             assignee = (
0252 |                 db.collection("profiles")
0253 |                 .document(patch["assigned_to"])
0254 |                 .get(transaction=transaction)
0255 |             )
0256 |             if (
0257 |                 not assignee.exists
0258 |                 or assignee.to_dict().get("role") != "claims_officer"
0259 |                 or assignee.to_dict().get("status") != "active"
0260 |             ):
0261 |                 raise HTTPException(422, "Choose an active claims officer.")
0262 |         if action == "correct":
0263 |             docs = list(
0264 |                 db.collection("claim_documents")
0265 |                 .where(filter=FieldFilter("claim_id", "==", claim_id))
0266 |                 .stream(transaction=transaction)
0267 |             )
0268 |             fields = list(
0269 |                 db.collection("claim_extracted_fields")
0270 |                 .where(filter=FieldFilter("claim_id", "==", claim_id))
0271 |                 .stream(transaction=transaction)
0272 |             )
0273 |             if payload.documents:
0274 |                 by_id = {d.id: d for d in docs}
0275 |                 if len(payload.documents) != len(by_id) or {
0276 |                     d.get("id") for d in payload.documents
0277 |                 } != set(by_id):
0278 |                     raise HTTPException(422, "Review every document exactly once.")
0279 |                 total = Decimal("0")
0280 |                 currencies = set()
0281 |                 for item in payload.documents:
0282 |                     if item.get("include") is True:
0283 |                         try:
0284 |                             amount = Decimal(str(item.get("amount")))
0285 |                         except Exception:
0286 |                             raise HTTPException(422, "Enter valid document amounts.")
0287 |                         currency = str(item.get("currency", "")).upper()
0288 |                         if (
0289 |                             not amount.is_finite()
0290 |                             or amount <= 0
0291 |                             or amount.as_tuple().exponent < -2
0292 |                             or len(currency) != 3
0293 |                             or by_id[item["id"]].to_dict().get("duplicate_of")
0294 |                         ):
0295 |                             raise HTTPException(
0296 |                                 422,
0297 |                                 "Included documents need valid amounts, currencies, and must not be duplicates.",
0298 |                             )
0299 |                         total += amount
0300 |                         currencies.add(currency)
0301 |                 if total <= 0 or len(currencies) != 1:
0302 |                     raise HTTPException(
0303 |                         422, "Include payable documents in one currency."
0304 |                     )
0305 |                 patch.update(claimed_amount=str(total), currency=next(iter(currencies)))
0306 |             elif claim.get("needs_reconfirmation"):
0307 |                 raise HTTPException(
0308 |                     422,
0309 |                     "Review every document amount after additional files were received.",
0310 |                 )
0311 |             by_field = {f.id: f for f in fields}
0312 |             if len({f.get("id") for f in payload.fields}) != len(payload.fields):
0313 |                 raise HTTPException(422, "Duplicate corrected fields.")
0314 |             for item in payload.fields:
0315 |                 if (
0316 |                     item.get("id") not in by_field
0317 |                     or not str(item.get("value", "")).strip()
0318 |                 ):
0319 |                     raise HTTPException(
0320 |                         422,
0321 |                         "Corrected field does not belong to this claim or has an empty value.",
0322 |                     )
0323 |         if action == "correct":
0324 |             for item in payload.documents:
0325 |                 document = next(d for d in docs if d.id == item["id"])
0326 |                 transaction.update(
0327 |                     document.reference,
0328 |                     {
0329 |                         "include_in_total": item.get("include") is True,
0330 |                         "confirmed_amount": str(item["amount"])
0331 |                         if item.get("include") is True
0332 |                         else None,
0333 |                         "confirmed_currency": str(item.get("currency", "")).upper()
0334 |                         if item.get("include") is True
0335 |                         else None,
0336 |                     },
0337 |                 )
0338 |             by_field = {f.id: f for f in fields}
0339 |             for item in payload.fields:
0340 |                 old = by_field[item["id"]]
0341 |                 transaction.update(
0342 |                     old.reference,
0343 |                     {
0344 |                         "normalized_value": str(item["value"]).strip(),
0345 |                         "confidence": 0,
0346 |                         "extraction_method": "staff_corrected",
0347 |                     },
0348 |                 )
0349 |                 write_event(
0350 |                     db,
0351 |                     transaction,
0352 |                     claim,
0353 |                     user.id,
0354 |                     "FIELD_CORRECTED",
0355 |                     {
0356 |                         "field_name": old.to_dict().get("field_name"),
0357 |                         "previous_value": old.to_dict().get("normalized_value"),
0358 |                         "corrected_value": str(item["value"]).strip(),
0359 |                     },
0360 |                 )
0361 |         if action == "request-information":
0362 |             info = db.collection("claim_information_requests").document()
0363 |             transaction.set(
0364 |                 info,
0365 |                 {
0366 |                     "id": info.id,
0367 |                     "claim_id": claim_id,
0368 |                     "requested_by": user.id,
0369 |                     "reason": payload.reason.strip(),
0370 |                     "questions": payload.questions.strip(),
0371 |                     "required_documents": payload.required_documents.strip(),
0372 |                     "response_deadline": payload.response_deadline.isoformat()
0373 |                     if payload.response_deadline
0374 |                     else None,
0375 |                     "internal_note": payload.internal_note.strip(),
0376 |                     "status": "OPEN",
0377 |                     "created_at": now(),
0378 |                 },
0379 |             )
0380 |         transaction.update(ref, patch)
0381 |         write_event(
0382 |             db,
0383 |             transaction,
0384 |             {**claim, **patch},
0385 |             user.id,
0386 |             event,
0387 |             {
0388 |                 "notes": payload.notes.strip(),
0389 |                 "assignee": patch.get("assigned_to"),
0390 |                 "approved_amount": patch.get("approved_amount"),
0391 |             },
0392 |             watchers=watchers,
0393 |         )
0394 |         return {**claim, **patch}
0395 |
0396 |     return await asyncio.to_thread(run, db.transaction())
0397 |
0398 |
0399 | async def workflow_details(gateway, claim):
0400 |     def load():
0401 |         rows = [
0402 |             s.to_dict()
0403 |             for s in gateway.db.collection("claim_information_requests")
0404 |             .where(filter=FieldFilter("claim_id", "==", claim["id"]))
0405 |             .stream()
0406 |         ]
0407 |         rows.sort(key=lambda row: row.get("created_at", ""), reverse=True)
0408 |         if gateway._user().profile.role == "finance":
0409 |             rows = []
0410 |         if gateway._user().profile.role == "client":
0411 |             for row in rows:
0412 |                 row.pop("internal_note", None)
0413 |         workflow = {
0414 |             key: claim.get(key)
0415 |             for key in (
0416 |                 "client_id",
0417 |                 "assigned_to",
0418 |                 "verified_by",
0419 |                 "verified_at",
0420 |                 "decision_notes",
0421 |                 "approved_amount",
0422 |                 "decided_at",
0423 |                 "paid_at",
0424 |                 "needs_reconfirmation",
0425 |                 "payment_reference",
0426 |                 "payment_method",
0427 |                 "appeal_count",
0428 |                 "submitted_at",
0429 |             )
0430 |         }
0431 |         for key, label in [
0432 |             ("client_id", "client_name"),
0433 |             ("assigned_to", "assigned_officer_name"),
0434 |         ]:
0435 |             profile = (
0436 |                 gateway.db.collection("profiles").document(claim[key]).get()
0437 |                 if claim.get(key)
0438 |                 else None
0439 |             )
0440 |             workflow[label] = (
0441 |                 profile.to_dict().get("display_name")
0442 |                 if profile and profile.exists
0443 |                 else None
0444 |             )
0445 |         return {
0446 |             "available_actions": available_actions(gateway._user(), claim),
0447 |             "information_requests": rows,
0448 |             "workflow": workflow,
0449 |         }
0450 |
0451 |     return await asyncio.to_thread(load)
```

## services/api/requirements.txt

15 lines. SHA-256: `762318c3d6b661691f3d137f629e1381380a9a9189293dc370ef721b6cb682e0`.

Symbols: Configuration/resource file.

```text
0001 | fastapi==0.141.1
0002 | uvicorn==0.52.1
0003 | httpx==0.28.1
0004 | python-dotenv==1.2.2
0005 | python-multipart==0.0.32
0006 | PyMuPDF==1.28.2
0007 | numpy==1.26.4
0008 | opencv-contrib-python==4.10.0.84
0009 | paddlepaddle==3.2.2
0010 | paddleocr==3.7.0
0011 | Pillow==12.1.1
0012 | python-docx==1.2.0
0013 | firebase-admin==7.8.0
0014 |
0015 | cryptography==50.0.2
```

## Test-file inventory

- `mobile/claimlens_mobile/test/account_forms_test.dart`
- `mobile/claimlens_mobile/test/claim_model_test.dart`
- `mobile/claimlens_mobile/test/dashboard_layout_test.dart`
- `mobile/claimlens_mobile/test/extraction_workflow_test.dart`
- `mobile/claimlens_mobile/test/logo_layout_test.dart`
- `mobile/claimlens_mobile/test/network_recovery_test.dart`
- `mobile/claimlens_mobile/test/readiness_ui_test.dart`
- `mobile/claimlens_mobile/test/server_configuration_test.dart`
- `mobile/claimlens_mobile/test/signup_navigation_test.dart`
- `mobile/claimlens_mobile/test/workspace_navigation_test.dart`
- `services/api/tests/conftest.py`
- `services/api/tests/test_auth_guard.py`
- `services/api/tests/test_extraction.py`
- `services/api/tests/test_firebase_auth.py`
- `services/api/tests/test_firebase_live.py`
- `services/api/tests/test_health.py`
- `services/api/tests/test_internet_live.py`
- `services/api/tests/test_job_recovery.py`
- `services/api/tests/test_local_documents.py`
- `services/api/tests/test_multi_expense_live.py`
- `services/api/tests/test_paddle_integration.py`
- `services/api/tests/test_paddle_ocr.py`
- `services/api/tests/test_queue_live.py`
- `services/api/tests/test_readiness.py`
- `services/api/tests/test_workflow.py`
- `services/api/tests/test_workspace_accounts_live.py`
