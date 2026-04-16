import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/colors.dart';
import '../core/widgets.dart';
import 'register_screen.dart';

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
                        PixelButton(
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
                        PixelField(
                          controller: _emailCtrl,
                          label: 'USER IDENTIFIER',
                          placeholder: 'pixel.pioneer@cloudy.home',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        PixelField(
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
                                    child: PixelButton(
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
                                    child: PixelButton(
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
                        PixelButton(
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

// ── Google icon (custom painted) ──────────────────────────────────────────────
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
