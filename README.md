KYC - Know Your Campus 
is a Flutter-based mobile application designed to serve as a virtual assistant for colleges and other educational institutions. The app aims to streamline daily campus activities, enhance communication, and improve access to essential resources for students, faculty, and administration.

## Firebase Authentication Setup (Detailed Guide)

Follow these steps to link this Flutter project with Firebase for authentication (Email/Password and Google Sign-In). The guide covers Android, iOS, and Web.

### 1) Prerequisites
- Flutter SDK installed and on PATH
- A Google account
- Android Studio / Xcode (as applicable)
- For Android: Java 17, Android SDK

### 2) Create a Firebase project
1. Go to the Firebase Console: `https://console.firebase.google.com`
2. Click Add project → enter a name (e.g., CampusAI) → continue with defaults.
3. Disable Google Analytics if you don't need it or leave enabled as you prefer.

### 3) Add Firebase to Android app
1. In Firebase Console, open your project → Build → Authentication → Get started.
2. Click the Android icon to add an app.
3. Android package name: use the applicationId from `android/app/build.gradle` → `com.bhumiqai.voice_chatbot_assistant`.
4. App nickname: optional.
5. Register app → download `google-services.json`.
6. Place `google-services.json` into `android/app/`.
7. In `android/settings.gradle`, Flutter may warn your Android Gradle Plugin (AGP) is old. Update later to 8.3.0+ when convenient.
8. In `android/app/build.gradle`, ensure:
   - `minSdk = 23` (already set)
   - Apply Google services plugin. Either in the plugins block:
     ```gradle
     plugins {
         id "com.android.application"
         id "kotlin-android"
         id "com.google.gms.google-services"
         id "dev.flutter.flutter-gradle-plugin"
     }
     ```
     or at the bottom of the file:
     ```gradle
     apply plugin: "com.google.gms.google-services"
     ```
9. If your build uses an old `buildscript` block in `android/build.gradle`, add:
   ```gradle
   classpath "com.google.gms:google-services:4.4.2"
   ```

### 4) Enable auth providers in Firebase Console
1. Go to Build → Authentication → Sign-in method.
2. Enable Email/Password.
3. Enable Google and set your support email.

### 5) Add Flutter dependencies
Ensure these in `pubspec.yaml` (use latest compatible versions):
```yaml
dependencies:
  firebase_core: ^3.4.0
  firebase_auth: ^5.1.4
  google_sign_in: ^6.2.1
```
Then run:
```bash
flutter pub get
```

### 6) Initialize Firebase in Flutter
Initialize before using auth:
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
```
If you use the FlutterFire CLI, it generates `firebase_options.dart`:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
Then:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### 7) Android Google Sign-In config
1. Generate SHA-1/SHA-256 and add in Firebase Console → Project settings → Android app:
   - Android Studio: Gradle panel → Tasks → android → signingReport
   - Or terminal in `android/`: `./gradlew signingReport`
2. Download updated `google-services.json` if prompted and replace the old file.

### 8) iOS setup
1. Add iOS app with Bundle ID from `ios/Runner/Info.plist`.
2. Add `GoogleService-Info.plist` to `ios/Runner/` in Xcode (Runner target).
3. For Google Sign-In, add REVERSED_CLIENT_ID in URL Types (from `GoogleService-Info.plist`).

### 9) Web setup (optional)
1. Register a web app in Firebase Console.
2. Use config in `web/index.html` or FlutterFire `firebase_options.dart`.
3. Add your domain in Authentication → Settings → Authorized domains.

### 10) Using `firebase_auth` in code
```dart
import 'package:firebase_auth/firebase_auth.dart';

final auth = FirebaseAuth.instance;

// Email sign up
await auth.createUserWithEmailAndPassword(email: email, password: password);

// Email sign in
await auth.signInWithEmailAndPassword(email: email, password: password);

// Google sign in (mobile)
final googleUser = await GoogleSignIn().signIn();
final googleAuth = await googleUser!.authentication;
final credential = GoogleAuthProvider.credential(
  accessToken: googleAuth.accessToken,
  idToken: googleAuth.idToken,
);
await auth.signInWithCredential(credential);
```

### 11) Common pitfalls
- Keep `minSdk >= 23` for latest Firebase Android SDKs.
- If you raise AGP (8.3.0+), ensure Gradle wrapper is compatible per Android docs.
- On manifest merge errors, run `flutter clean` then rebuild.
- After adding SHA keys, re-download `google-services.json`.

### 12) Build and run
```bash
flutter clean
flutter pub get
flutter run
```
