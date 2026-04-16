import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/colors.dart';
import '../core/widgets.dart';
import 'api_key_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _storage = FlutterSecureStorage();
  String _maskedKey = '••••••••????';

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await _storage.read(key: 'anthropic_api_key');
    if (!mounted) return;
    if (key != null && key.length >= 4) {
      setState(() => _maskedKey = '••••••••${key.substring(key.length - 4)}');
    }
  }

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
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back,
                      color: CL.outline, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Text('SETTINGS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: CL.secondary, letterSpacing: 4,
                    )),
                ],
              ),
              Container(
                height: 4, color: CL.surfaceContainerHigh,
                margin: const EdgeInsets.only(top: 8, bottom: 32)),

              // ── API Key section ──
              Text('API KEY',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: CL.onSurfaceVariant, letterSpacing: 4,
                )),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: CL.surfaceContainer,
                  boxShadow: [BoxShadow(
                    color: CL.surfaceContainerLowest, offset: Offset(4, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ANTHROPIC_API_KEY',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: CL.outline, letterSpacing: 3,
                      )),
                    const SizedBox(height: 8),
                    Text(_maskedKey,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20, fontWeight: FontWeight.w900,
                        color: CL.primary, letterSpacing: 2,
                      )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PixelButton(
                bg: CL.primaryContainer,
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (ctx, anim, sec) =>
                        const ApiKeyScreen(isUpdate: true),
                      transitionsBuilder: (ctx, anim, sec, child) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeInOut,
                        )),
                        child: child,
                      ),
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  ).then((_) => _loadKey());
                },
                child: Text('UPDATE KEY',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16, fontWeight: FontWeight.w900,
                    color: Colors.white, letterSpacing: 3,
                  )),
              ),

              const SizedBox(height: 40),

              // ── Sign out ──
              Container(
                height: 2, color: CL.surfaceContainerHigh,
                margin: const EdgeInsets.only(bottom: 24)),
              PixelButton(
                bg: CL.surfaceContainerHigh,
                onTap: () => FirebaseAuth.instance.signOut(),
                child: Text('SIGN OUT',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16, fontWeight: FontWeight.w900,
                    color: CL.outline, letterSpacing: 3,
                  )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
