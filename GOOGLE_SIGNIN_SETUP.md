# Google Sign-In Setup Guide

## Current SHA Fingerprints

Your app is configured with the following SHA fingerprints:

### Debug Build (Development)
- **SHA1**: `68:95:A2:1C:20:E0:E3:15:F6:4C:FE:B3:28:47:05:C2:BD:B5:33:ED`
- **SHA256**: `10:D8:00:76:17:E5:3E:42:AD:61:75:8F:E1:6B:46:6E:9B:AA:91:EB:8C:9A:B8:39:3F:77:80:34:C0:E3:04:38`

### Package Name
- **com.bhumiqai.voice_chatbot_assistant**

## Steps to Fix Google Sign-In

### 1. Firebase Console Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `aiassistant-f1260`
3. Go to **Project Settings** (gear icon)
4. Click on **Your apps** tab
5. Select your Android app: `com.bhumiqai.voice_chatbot_assistant`
6. Click **Add fingerprint** button
7. Add both SHA1 and SHA256 fingerprints:

#### SHA1 Fingerprint
```
68:95:A2:1C:20:E0:E3:15:F6:4C:FE:B3:28:47:05:C2:BD:B5:33:ED
```

#### SHA256 Fingerprint
```
10:D8:00:76:17:E5:3E:42:AD:61:75:8F:E1:6B:46:6E:9B:AA:91:EB:8C:9A:B8:39:3F:77:80:34:C0:E3:04:38
```

### 2. Google Cloud Console Configuration

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: `aiassistant-f1260`
3. Go to **APIs & Services** > **Credentials**
4. Find your OAuth 2.0 Client ID for Android
5. Click on the client ID to edit
6. Add the SHA1 fingerprint in the **Package name and SHA-1 certificate fingerprint** section:
   - Package name: `com.bhumiqai.voice_chatbot_assistant`
   - SHA-1: `68:95:A2:1C:20:E0:E3:15:F6:4C:FE:B3:28:47:05:C2:BD:B5:33:ED`

### 3. Download Updated google-services.json

After adding the fingerprints in Firebase Console:
1. Download the updated `google-services.json` file
2. Replace the existing file in `android/app/google-services.json`

### 4. Clean and Rebuild

Run these commands to clean and rebuild your app:

```bash
flutter clean
flutter pub get
flutter run
```

### 5. For Release Build

When you're ready to release your app, you'll need to:

1. Generate a release keystore:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Get the release SHA fingerprints:
```bash
keytool -list -v -keystore ~/upload-keystore.jks -alias upload
```

3. Add the release SHA fingerprints to Firebase Console and Google Cloud Console

4. Update your `android/app/build.gradle` to use the release keystore

## Troubleshooting

### Common Issues:

1. **"Check SHA-1/SHA-256" Error**: 
   - Ensure both SHA1 and SHA256 are added to Firebase Console
   - Make sure the package name matches exactly
   - Wait 5-10 minutes after adding fingerprints (Google's servers need time to propagate)

2. **"Network Error"**:
   - Check your internet connection
   - Ensure Google Play Services is up to date on your device

3. **"Sign-in failed"**:
   - Clear app data and cache
   - Uninstall and reinstall the app
   - Try signing out of Google account on device and signing back in

### Testing:

1. Test on a physical device (not emulator)
2. Ensure Google Play Services is installed and updated
3. Make sure you're signed into a Google account on the device

## Web Platform Setup (Google Sign-In)

For Google Sign-In to work on web, you need to configure the OAuth 2.0 Client ID:

### Steps to Get Web OAuth Client ID:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: `aiassistant-f1260`
3. Navigate to **APIs & Services** > **Credentials**
4. Find the **OAuth 2.0 Client ID** with type **Web application**
5. Copy the **Client ID** (format: `PROJECT_NUMBER-xxxxx.apps.googleusercontent.com`)

### Update Configuration:

1. **Update `web/index.html`:**
   - Find the meta tag: `<meta name="google-signin-client_id" content="...">`
   - Replace the content value with your Web OAuth Client ID

2. **Update `lib/services/auth_service.dart`:**
   - Find the constant: `static const String _webClientId = '...';`
   - Replace the value with your Web OAuth Client ID

### Current Web Client ID (verify this is correct):
- **Client ID**: `745225092320-hkpsuerr53jav9u0eobfrifsk0tn5lop.apps.googleusercontent.com`
- ⚠️ **Note**: This is from google-services.json (client_type 3). Verify this matches your Web OAuth Client ID in Google Cloud Console.

## Current Configuration Status

✅ **SHA1 Fingerprint**: Already configured correctly  
✅ **SHA256 Fingerprint**: Added to google-services.json  
✅ **Package Name**: Matches correctly  
✅ **Android OAuth Client ID**: Configured in google-services.json  
⚠️ **Web OAuth Client ID**: Needs verification from Google Cloud Console
