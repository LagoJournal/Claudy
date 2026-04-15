<div align="center">

# Claudy 😶‍🌫️

### Your own AI home assistant, powered by Claude.

<br/>

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter)](https://flutter.dev)
[![Claude](https://img.shields.io/badge/Powered%20by-Claude-orange)](https://anthropic.com)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

---

Hey! Welcome to Claudy's repo. My end goal with this is to turn any spare phone you have laying around into an always on AI home assistant (powered by Claude). Plug it into a wall, connect it to your home and talk to it to run commands, even control it from a web dashboard anywhere in the world!

This should be a self hosted, privacy secure alternative to market home hubs. You own the hardware, the software & your own API key.

---

## How it will work

```
┌─────────────────────────────────────┐
│           Android phone             │
│  ┌─────────────────────────────┐    │
│  │     Flutter app (launcher)  │    │
│  │  • Claude chat UI           │    │
│  │  • Voice listener           │    │
│  │  • WebSocket server         │    │
│  │  • Hardware tools           │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │   Cloudflare Tunnel         │    │
│  │   (via Termux)              │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
              │ WSS
              ▼
┌─────────────────────────────────────┐
│         Firebase                    │
│  • Auth (login/signup)              │
│  • Firestore (stores tunnel URL)    │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│      Web Dashboard (any browser)    │
│      Hosted on GitHub Pages         │
│  • Logs in with Firebase Auth       │
│  • Auto-connects to your phone      │
│  • Chat, camera, controls           │
└─────────────────────────────────────┘
```

The phone will be the brain. It runs Claude, stores your API key locally, and executes all actions. The web dashboard is a thin client that connects to it, no data passes through any server except what you send to Anthropic directly.

---

## 🔒 Privacy first

- Your Anthropic API key is stored **on your phone only**, it never touches any external server
- Firebase stores only your tunnel URL, linked to your account UID
- All communication between dashboard and phone is end-to-end encrypted via Cloudflare Tunnel (WSS)
- Currently thinking on how you can selfhost the entire Firebase layer if you prefer zero third-party dependency 🤔

---

## Requirements

**Phone (server)**
- Any Android phone running Android 5.0 will be enough
- Termux installed
- Always on power source recommended (plugged into wall)
- An Anthropic API key

**Secondary devices** *(for remote use, not necessary)*
- Any browser! No install required

---

## Intended tech stack

| Layer | Technology |
|---|---|
| Phone app | Flutter (Dart) |
| Auth | Firebase Authentication |
| Pairing | Cloud Firestore |
| Tunnel | Cloudflare Tunnel (free) |
| Web dashboard | Next.js |
| AI | Anthropic Claude API |

---

## Roadmap

- [ ] Architecture design
- [ ] Flutter app scaffold + Android launcher
- [ ] Firebase Auth + onboarding
- [ ] Claude chat UI with streaming
- [ ] WebSocket server + Cloudflare Tunnel
- [ ] Web dashboard (GitHub Pages)
- [ ] Voice wake word + speech-to-text
- [ ] Smart home (MQTT / Home Assistant)
- [ ] Spotify integration
- [ ] Google Calendar integration
- [ ] Camera streaming to dashboard
- [ ] SMS integration
- [ ] Motion detection alerts
- [ ] Multi-user / family access
- [ ] Plugin system for community extensions

---

## Contributing

I'm starting Claudy to build & learn. Every capability planned (Spotify, smart home, calendar management, camera use) will be a tool module that Claude can call. Adding a new integration means writing one new tool — and I'm hoping for contributions to make this project grow!

Licensed under MIT, so anyone can do whatever they want with it. If you build something cool on top, consider opening a PR. 🙌

