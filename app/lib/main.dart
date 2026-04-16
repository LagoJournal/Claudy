import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/colors.dart';
import 'screens/login_screen.dart';
import 'screens/hub_screen.dart';
import 'screens/api_key_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ClaudyApp());
}

// ── Fullscreen helper ─────────────────────────────────────────────────────────
void _restoreFullscreen() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

class ClaudyApp extends StatelessWidget {
  const ClaudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Claudy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: CL.background,
        colorScheme: const ColorScheme.dark(
          primary: CL.primary,
          onPrimary: CL.onPrimary,
          secondary: CL.secondary,
          onSecondary: CL.onSecondary,
          surface: CL.surface,
          onSurface: CL.onSurface,
          error: CL.error,
        ),
      ),
      home: const _FullscreenWrapper(child: AuthGate()),
    );
  }
}

// ── Fullscreen wrapper — restores immersive mode after keyboard dismissal ─────
class _FullscreenWrapper extends StatefulWidget {
  final Widget child;
  const _FullscreenWrapper({required this.child});

  @override
  State<_FullscreenWrapper> createState() => _FullscreenWrapperState();
}

class _FullscreenWrapperState extends State<_FullscreenWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _restoreFullscreen();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _restoreFullscreen();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── Auth gate — watches Firebase auth state, checks API key, routes ───────────
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  static Widget _loading() => const Scaffold(
    backgroundColor: CL.background,
    body: Center(child: CircularProgressIndicator(color: CL.primary)),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loading();
        }
        if (snapshot.hasData) {
          // User is logged in — check if API key has been configured
          return FutureBuilder<String?>(
            future: const FlutterSecureStorage().read(key: 'anthropic_api_key'),
            builder: (context, keySnap) {
              if (keySnap.connectionState == ConnectionState.waiting) {
                return _loading();
              }
              if (keySnap.data != null && keySnap.data!.isNotEmpty) {
                return const HubScreen();
              }
              return const ApiKeyScreen();
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}
