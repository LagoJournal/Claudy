import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/colors.dart';
import '../core/widgets.dart';

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
                  PixelField(
                    controller: _emailCtrl,
                    label: 'COMMS_CHANNEL_EMAIL',
                    placeholder: 'USER@CLOUD.NET',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),

                  // Password
                  PixelField(
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
                  PixelButton(
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
