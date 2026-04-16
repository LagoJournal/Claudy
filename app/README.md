<div align="center">

# Claudy — Flutter App 😶‍🌫️

### The Android launcher that puts Claude brains on your home screen.

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Auth-Firebase-FFCA28?logo=firebase)](https://firebase.google.com)
[![Claude](https://img.shields.io/badge/Powered%20by-Claude-orange)](https://anthropic.com)

</div>

---

This is the Android app that runs permanently on the phone. It replaces the home screen launcher, handles authentication, stores your Anthropic API key locally, and runs a full voice interaction: push-to-talk → Claude streaming → TTS playback.

---

## What I have achieved so far

- **Android launcher** — app declared as a home screen launcher, pressing home opens Claudy in fullscreen
- **Firebase Auth** — login and signup with Google or email/password
- **API key onboarding** — enter and store the Anthropic key securely with `flutter_secure_storage`
- **Voice interaction** — push-to-talk STT (`speech_to_text`) → Claude streaming (`claude-haiku-4-5-20251001`) → TTS playback (`flutter_tts`); state machine cycles idle → listening → thinking → speaking

---

## File structure

```
lib/
  main.dart                    # main(), ClaudyApp, AuthGate (with nested API-key check)
  core/
    colors.dart                # color tokens + pixelBox() decoration helper
    widgets.dart               # PixelButton, PixelField, ActionTile
  screens/
    login_screen.dart          # Firebase email/password + Google Sign-In
    register_screen.dart       # Firebase registration
    hub_screen.dart            # main voice interaction loop
    api_key_screen.dart        # API key onboarding / update
    settings_screen.dart       # masked key display, update, sign-out
  services/
    claude_service.dart        # Anthropic SSE streaming service
```

---

## Running locally

**Requirements:** Flutter 3.41.6, Android Studio, ADB, an Android phone with USB debugging enabled.

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build APK for sideloading
flutter build apk --release

# Regenerate icons after changing app_icon.png
dart run flutter_launcher_icons
```

Make sure your `google-services.json` from Firebase is placed at `android/app/google-services.json` before building.

> **API keys** are obtained from [platform.claude.com](https://platform.claude.com) → API Keys. Use the **Default workspace** key — new workspaces may not use org credits, idk why but i went crazy debugging this.

---

## What's next

- Voice wake word
- Screen dim to ~5% brightness when idle
- WebSocket server on the phone
- Cloudflare Tunnel via Termux
- Spotify integration
- Smart home, I currently use Tuya's smart app so planning to integrate it using their SDK
