import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ClaudyApp());
}

// ── Colour tokens ─────────────────────────────────────────────────────────────
class CL {
  static const background               = Color(0xFF131313);
  static const surface                  = Color(0xFF131313);
  static const surfaceContainer         = Color(0xFF20201F);
  static const surfaceContainerLow      = Color(0xFF1C1B1B);
  static const surfaceContainerHigh     = Color(0xFF2A2A2A);
  static const surfaceContainerHighest  = Color(0xFF353535);
  static const surfaceContainerLowest   = Color(0xFF0E0E0E);
  static const primary                  = Color(0xFFD9B9FF);
  static const onPrimary                = Color(0xFF431279);
  static const primaryContainer         = Color(0xFF774DAF);
  static const secondary                = Color(0xFFFFB77D);
  static const onSecondary              = Color(0xFF4D2600);
  static const outline                  = Color(0xFF948E9E);
  static const outlineVariant           = Color(0xFF494552);
  static const onSurface                = Color(0xFFE5E2E1);
  static const onSurfaceVariant         = Color(0xFFCAC4D4);
  static const error                    = Color(0xFFFFB4AB);
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
    // Fires when keyboard appears/disappears — restore fullscreen each time
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

// ── Auth gate — watches Firebase auth state and routes accordingly ─────────────
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: CL.background,
            body: Center(
              child: CircularProgressIndicator(color: CL.primary),
            ),
          );
        }
        if (snapshot.hasData) return const HubScreen();
        return const LoginScreen();
      },
    );
  }
}

// ── Shared pixel-shadow decoration ───────────────────────────────────────────
BoxDecoration pixelBox({
  Color bg = CL.surfaceContainer,
  Color? border,
  double borderWidth = 0,
}) =>
    BoxDecoration(
      color: bg,
      border: border != null
          ? Border.all(color: border, width: borderWidth)
          : null,
      boxShadow: const [
        BoxShadow(color: CL.surfaceContainerLowest, offset: Offset(4, 4))
      ],
    );

// ── LOGIN SCREEN ──────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool    _loading = false;
  String? _error;
  bool    _showCreatePrompt = false;

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; _showCreatePrompt = false; });
    try {
      final user = await GoogleSignIn(scopes: ['email']).signIn();
      if (user == null) { setState(() => _loading = false); return; }
      final auth = await user.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(cred);
      // AuthGate stream handles navigation automatically
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _emailSignIn() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in both fields.');
      return;
    }
    setState(() { _loading = true; _error = null; _showCreatePrompt = false; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      // AuthGate stream handles navigation automatically
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        setState(() {
          _loading = false;
          _error = 'No account found with that email.';
          _showCreatePrompt = true;
        });
      } else if (e.code == 'wrong-password') {
        setState(() {
          _loading = false;
          _error = 'Incorrect password.';
        });
      } else {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  Future<void> _createAccountWithCurrentCredentials() async {
    setState(() { _loading = true; _error = null; _showCreatePrompt = false; });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      // AuthGate stream handles navigation automatically
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CL.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  // ── Logo ──
                  Container(
                    width: 96, height: 96,
                    decoration: pixelBox(bg: CL.primary),
                    child: const Icon(Icons.cloud, color: CL.onPrimary, size: 60),
                  ),
                  const SizedBox(height: 16),
                  Text('CLOUDY',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 56, fontWeight: FontWeight.w900,
                      color: CL.primary, letterSpacing: -2,
                    )),
                  Text('ANALOG FUTURIST HOME',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: CL.secondary, letterSpacing: 4,
                    )),
                  const SizedBox(height: 40),

                  // ── Auth container ──
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: pixelBox(bg: CL.surfaceContainer),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Google button
                        _PixelButton(
                          onTap: _loading ? null : _googleSignIn,
                          bg: CL.onSurface,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GoogleIcon(),
                              const SizedBox(width: 12),
                              Text('SIGN IN WITH GOOGLE',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: CL.background,
                                )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider
                        Row(children: [
                          Expanded(child: Container(height: 2, color: CL.surfaceContainerHigh)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR USE EMAIL',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: CL.outline, letterSpacing: 3,
                              )),
                          ),
                          Expanded(child: Container(height: 2, color: CL.surfaceContainerHigh)),
                        ]),
                        const SizedBox(height: 24),

                        // Email field
                        _PixelField(
                          controller: _emailCtrl,
                          label: 'USER IDENTIFIER',
                          placeholder: 'pixel.pioneer@cloudy.home',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        _PixelField(
                          controller: _passwordCtrl,
                          label: 'ACCESS KEY',
                          placeholder: '••••••••••••',
                          obscure: true,
                          onSubmitted: (_) => _emailSignIn(),
                        ),
                        const SizedBox(height: 16),

                        // Error message
                        if (_error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CL.surfaceContainerLowest,
                              border: Border.all(color: CL.error, width: 2),
                            ),
                            child: Text(_error!,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12, color: CL.error,
                                fontWeight: FontWeight.w600,
                              )),
                          ),

                        // Create account prompt
                        if (_showCreatePrompt) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: CL.surfaceContainerLowest,
                              border: Border.all(color: CL.primary, width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CREATE ACCOUNT?',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13, fontWeight: FontWeight.w900,
                                    color: CL.primary, letterSpacing: 2,
                                  )),
                                const SizedBox(height: 4),
                                Text(
                                  'No account found for ${_emailCtrl.text.trim()}. Create one with this email and password?',
                                  style: GoogleFonts.inter(
                                    fontSize: 12, color: CL.onSurfaceVariant,
                                  )),
                                const SizedBox(height: 16),
                                Row(children: [
                                  Expanded(
                                    child: _PixelButton(
                                      onTap: _loading ? null : _createAccountWithCurrentCredentials,
                                      bg: CL.primary,
                                      child: Text('YES, CREATE',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13, fontWeight: FontWeight.w900,
                                          color: CL.onPrimary,
                                        )),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _PixelButton(
                                      onTap: () => setState(() {
                                        _showCreatePrompt = false;
                                        _error = null;
                                      }),
                                      bg: CL.surfaceContainerHigh,
                                      child: Text('CANCEL',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13, fontWeight: FontWeight.w900,
                                          color: CL.onSurface,
                                        )),
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Login button
                        _PixelButton(
                          onTap: _loading ? null : _emailSignIn,
                          bg: CL.primary,
                          child: _loading
                            ? const CircularProgressIndicator(color: CL.onPrimary)
                            : Text('LOG IN',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 20, fontWeight: FontWeight.w900,
                                  color: CL.onPrimary, letterSpacing: 2,
                                )),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer link
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text('CREATE AN ACCOUNT',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: CL.secondary, letterSpacing: 3,
                      )),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── REGISTER SCREEN ───────────────────────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool    _loading = false;
  String? _error;

  Future<void> _register() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in both fields.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      // Pop back to root so AuthGate stream picks up the new user and shows HubScreen
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CL.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Branding
                  Text('CLOUDY',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 56, fontWeight: FontWeight.w900,
                      color: CL.primary, letterSpacing: -2,
                    )),
                  Container(width: 48, height: 4, color: CL.secondary),
                  const SizedBox(height: 32),

                  Text('CREATE ACCOUNT',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32, fontWeight: FontWeight.w700,
                      color: CL.onSurface, letterSpacing: -1,
                    )),
                  const SizedBox(height: 4),
                  Text('Welcome to the future of tactile control.',
                    style: GoogleFonts.inter(
                      fontSize: 16, color: CL.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    )),
                  const SizedBox(height: 40),

                  // Email
                  _PixelField(
                    controller: _emailCtrl,
                    label: 'COMMS_CHANNEL_EMAIL',
                    placeholder: 'USER@CLOUD.NET',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),

                  // Password
                  _PixelField(
                    controller: _passwordCtrl,
                    label: 'ENCRYPTION_KEY_PASS',
                    placeholder: '••••••••',
                    obscure: true,
                    onSubmitted: (_) => _register(),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CL.surfaceContainerLowest,
                        border: Border.all(color: CL.error, width: 2),
                      ),
                      child: Text(_error!,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12, color: CL.error,
                          fontWeight: FontWeight.w600,
                        )),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Register button
                  _PixelButton(
                    onTap: _loading ? null : _register,
                    bg: CL.primary,
                    child: _loading
                      ? const CircularProgressIndicator(color: CL.onPrimary)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('REGISTER',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 22, fontWeight: FontWeight.w900,
                                color: CL.onPrimary, letterSpacing: 3,
                              )),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_forward, color: CL.onPrimary),
                          ],
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Back link
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back, color: CL.outline, size: 16),
                        const SizedBox(width: 8),
                        Text('BACK TO LOGIN_PORTAL',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: CL.outline, letterSpacing: 3,
                          )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── HUB SCREEN ────────────────────────────────────────────────────────────────
class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CL.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text('SYSTEM STATUS: OPTIMAL',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: CL.secondary, letterSpacing: 4,
                )),
              Container(
                height: 4, color: CL.surfaceContainerHigh,
                margin: const EdgeInsets.only(top: 8, bottom: 32)),

              // ASCII face + response
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                decoration: BoxDecoration(
                  color: CL.surfaceContainer,
                  border: Border.all(color: CL.primary, width: 8),
                  boxShadow: const [BoxShadow(
                    color: CL.surfaceContainerLowest, offset: Offset(6, 6))],
                ),
                child: Column(
                  children: [
                    Text('( ^ _ ^ )',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 48, fontWeight: FontWeight.w900,
                        color: CL.primary, letterSpacing: 4,
                      )),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: CL.background,
                        border: Border.all(color: CL.primary, width: 2),
                        boxShadow: const [BoxShadow(
                          color: CL.surfaceContainerLowest, offset: Offset(4, 4))],
                      ),
                      child: Text(
                        '"ALL SYSTEMS ARE STABLE. WOULD YOU LIKE ME TO BREW SOME COFFEE?"',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18, fontWeight: FontWeight.w900,
                          color: CL.onSurface, letterSpacing: 1,
                        )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Listen button
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: CL.primaryContainer,
                    border: Border.all(color: CL.primary, width: 4),
                    boxShadow: const [BoxShadow(
                      color: CL.surfaceContainerLowest, offset: Offset(10, 10))],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.mic, color: Colors.white, size: 64),
                      const SizedBox(height: 12),
                      Text('LISTEN',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 32, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: 8,
                        )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick action grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: const [
                  _ActionTile(icon: Icons.lightbulb,
                    label: 'LIGHTS', sub: '6 DEVICES ON', color: CL.secondary),
                  _ActionTile(icon: Icons.thermostat,
                    label: 'TEMP', sub: 'SET TO 68.0°', color: CL.primary),
                  _ActionTile(icon: Icons.music_note,
                    label: 'MUSIC', sub: 'LO-FI RADIO', color: CL.primary),
                  _ActionTile(icon: Icons.settings_input_component,
                    label: 'SCENES', sub: '3 ACTIVE', color: CL.outline),
                ],
              ),
              const SizedBox(height: 32),

              // Sign out
              GestureDetector(
                onTap: () => FirebaseAuth.instance.signOut(),
                child: Center(
                  child: Text('SIGN OUT',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: CL.outline, letterSpacing: 3,
                    )),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  const _ActionTile({
    required this.icon, required this.label,
    required this.sub, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: pixelBox(bg: CL.surfaceContainerHigh),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 12),
          Text(label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.w900,
              color: CL.onSurface,
            )),
          const SizedBox(height: 4),
          Text(sub,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: CL.outline, letterSpacing: 2,
            )),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────
class _PixelButton extends StatelessWidget {
  final Widget child;
  final Color bg;
  final VoidCallback? onTap;
  const _PixelButton({required this.child, required this.bg, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 64,
        decoration: BoxDecoration(
          color: bg,
          boxShadow: const [BoxShadow(
            color: CL.surfaceContainerLowest, offset: Offset(4, 4))],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _PixelField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  const _PixelField({
    required this.controller, required this.label,
    required this.placeholder, this.obscure = false,
    this.keyboardType, this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10, fontWeight: FontWeight.w700,
            color: CL.onSurfaceVariant, letterSpacing: 3,
          )),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: CL.surfaceContainerLowest,
            border: Border.all(color: CL.outlineVariant, width: 2),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            onSubmitted: onSubmitted,
            textInputAction: onSubmitted != null
                ? TextInputAction.done
                : TextInputAction.next,
            style: GoogleFonts.inter(color: CL.onSurface, fontSize: 16),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: GoogleFonts.inter(
                color: CL.outline.withOpacity(0.4), fontSize: 16),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24, height: 24,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
      -1.57, 1.57, true, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
      0, 1.57, true, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
      1.57, 1.57, true, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
      3.14, 1.57, true, paint);
    paint.color = Colors.black;
    canvas.drawCircle(center, radius * 0.55, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}