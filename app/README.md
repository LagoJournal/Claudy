<div align="center">

# Claudy — Flutter App 😶‍🌫️

### The Android launcher that puts Claudy brains on your home.

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Auth-Firebase-FFCA28?logo=firebase)](https://firebase.google.com)
[![Claude](https://img.shields.io/badge/Powered%20by-Claude-orange)](https://anthropic.com)

</div>

---

This is the Android app that is intended to be always runing on the phone. It replaces the home screen launcher, handles authentication and will store your Anthropic API key locally to talk directly with Claude.

---

## What's built so far

- **Android launcher** — app declared as a home screen launcher, pressing the home button opens Claudy
- **Firebase Auth** — login and signup with Google or email/password
- **Hub screen** — the main home screen with the _currently static_ Claudy UI

---

## What's next

- [ ] API key onboarding screen — enter and store the Anthropic key securely with `flutter_secure_storage`
- [ ] Claude interaction — chat with Claudy, streaming responses from the Anthropic API
- [ ] Multi-turn conversation context
- [ ] Voice input wired to the LISTEN button
- [ ] WebSocket server for web dashboard connection
- [ ] Cloudflare Tunnel integration via Termux

---

## Running locally

**Requirements:** Flutter 3.x, Android Studio, ADB, an Android phone with USB debugging enabled.

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build APK for sideloading
flutter build apk --release
```

Make sure your `google-services.json` from Firebase is placed at `android/app/google-services.json` before building.
