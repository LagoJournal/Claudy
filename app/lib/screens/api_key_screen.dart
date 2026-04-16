import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/colors.dart';
import 'hub_screen.dart';

class ApiKeyScreen extends StatefulWidget {
  /// When true, navigates back on success instead of replacing the route.
  final bool isUpdate;
  const ApiKeyScreen({super.key, this.isUpdate = false});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen>
    with SingleTickerProviderStateMixin {
  final _keyCtrl    = TextEditingController();
  bool    _obscured = true;
  bool    _loading  = false;
  bool    _pressed  = false;
  String? _error;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  static const _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveKey() async {
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'KEY_CANNOT_BE_EMPTY');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await _storage.write(key: 'anthropic_api_key', value: key);
    if (!mounted) return;
    if (widget.isUpdate) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, anim, secondary) => const HubScreen(),
          transitionsBuilder: (context, anim, secondary, child) =>
            FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CL.background,
      body: Stack(
        children: [
          // ── Dot grid background ──
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),

          // ── Bottom gradient overlay ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: 160,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [CL.primaryContainer, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40, left: -40,
            child: IgnorePointer(
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CL.secondary.withValues(alpha:0.08),
                ),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status bar
                _StatusBar(pulseAnim: _pulseAnim),

                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 32),

                            // ── Heading ──
                            Text('API_KEY_SETUP',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: CL.primary,
                                letterSpacing: -1,
                                shadows: const [
                                  Shadow(
                                    color: CL.primaryContainer,
                                    offset: Offset(4, 4),
                                  ),
                                ],
                              )),
                            const SizedBox(height: 16),

                            // ── Subtitle ──
                            Text(
                              'Enter your Anthropic API key to enable advanced brain functions.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: CL.onSurfaceVariant,
                                height: 1.5,
                              )),
                            const SizedBox(height: 32),

                            // ── Decorative divider ──
                            SizedBox(
                              height: 4,
                              child: Stack(
                                children: [
                                  Container(color: CL.surfaceContainerHigh),
                                  FractionallySizedBox(
                                    widthFactor: 0.33,
                                    child: Container(
                                      color: CL.primary.withValues(alpha:0.5)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),

                            // ── Input group ──
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('INPUT_KEY_STRING',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: CL.secondary,
                                  letterSpacing: 4,
                                )),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(1),
                              decoration: const BoxDecoration(
                                color: CL.surfaceContainerLowest,
                                boxShadow: [BoxShadow(
                                  color: CL.surfaceContainerLowest,
                                  offset: Offset(4, 4),
                                )],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _keyCtrl,
                                      obscureText: _obscured,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.deny(
                                          RegExp(r'[\r\n\t\s]')),
                                      ],
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 18,
                                        color: CL.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '••••••••••••••••••••••••••••••',
                                        hintStyle: GoogleFonts.spaceGrotesk(
                                          fontSize: 18,
                                          color: CL.surfaceContainerHighest,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 20),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _obscured = !_obscured),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Icon(
                                        _obscured ? Icons.vpn_key : Icons.visibility,
                                        color: CL.surfaceContainerHighest,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('ENCRYPTION_LAYER: ACTIVE (AES-256)',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10,
                                  color: CL.outline,
                                  letterSpacing: 2,
                                )),
                            ),

                            // ── Error ──
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: CL.surfaceContainerLowest,
                                  border: Border.all(
                                    color: CL.secondary, width: 2),
                                ),
                                child: Text(_error!,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    color: CL.secondary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  )),
                              ),
                            ],

                            const SizedBox(height: 32),

                            // ── SAVE_KEY button with press animation ──
                            GestureDetector(
                              onTapDown: (_) => setState(() => _pressed = true),
                              onTapUp: (_) {
                                setState(() => _pressed = false);
                                if (!_loading) _saveKey();
                              },
                              onTapCancel: () => setState(() => _pressed = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 80),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                transform: Matrix4.translationValues(
                                  _pressed ? 4 : 0,
                                  _pressed ? 4 : 0,
                                  0,
                                ),
                                decoration: BoxDecoration(
                                  color: _loading
                                    ? CL.primaryContainer
                                    : CL.primary,
                                  boxShadow: _pressed
                                    ? []
                                    : const [BoxShadow(
                                        color: CL.surfaceContainerLowest,
                                        offset: Offset(4, 4),
                                      )],
                                ),
                                child: _loading
                                  ? const Center(
                                      child: SizedBox(
                                        width: 28, height: 28,
                                        child: CircularProgressIndicator(
                                          color: CL.onPrimary,
                                          strokeWidth: 3,
                                        )))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('SAVE_KEY',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: CL.onPrimary,
                                            letterSpacing: 2,
                                          )),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.arrow_forward,
                                          color: CL.onPrimary, size: 28),
                                      ],
                                    ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── GET KEY link ──
                            GestureDetector(
                              onTap: () {},
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.open_in_new,
                                    color: CL.outline, size: 16),
                                  const SizedBox(width: 8),
                                  Text('GET_KEY_FROM_ANTHROPIC',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: CL.outline,
                                      letterSpacing: 3,
                                    )),
                                ],
                              ),
                            ),

                            const SizedBox(height: 64),

                            // ── Decorative footer grid ──
                            Opacity(
                              opacity: 0.4,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 64,
                                      decoration: const BoxDecoration(
                                        color: CL.surfaceContainer,
                                        boxShadow: [BoxShadow(
                                          color: CL.surfaceContainerLowest,
                                          offset: Offset(4, 4),
                                        )],
                                      ),
                                      child: const Icon(Icons.grid_view,
                                        color: CL.surfaceContainerHighest),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      height: 64,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            CL.background,
                                            CL.surfaceContainerLow,
                                            CL.background,
                                            CL.surfaceContainerLow,
                                          ],
                                          stops: const [0.25, 0.25, 0.75, 0.75],
                                        ),
                                        boxShadow: const [BoxShadow(
                                          color: CL.surfaceContainerLowest,
                                          offset: Offset(4, 4),
                                        )],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      height: 64,
                                      decoration: const BoxDecoration(
                                        color: CL.surfaceContainer,
                                        boxShadow: [BoxShadow(
                                          color: CL.surfaceContainerLowest,
                                          offset: Offset(4, 4),
                                        )],
                                      ),
                                      child: const Icon(Icons.terminal,
                                        color: CL.surfaceContainerHighest),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top status bar ────────────────────────────────────────────────────────────
class _StatusBar extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _StatusBar({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: CL.background,
        boxShadow: [BoxShadow(
          color: CL.surfaceContainerLowest, offset: Offset(4, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.memory, color: CL.primary, size: 22),
          const SizedBox(width: 10),
          Text('CORE_CONFIG',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: CL.primary, letterSpacing: -0.5,
            )),
          const Spacer(),
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (ctx, child) => Opacity(
              opacity: pulseAnim.value,
              child: Container(
                width: 8, height: 8,
                color: CL.secondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('STATUS: WAITING_FOR_INPUT',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: CL.outline, letterSpacing: 1,
            )),
        ],
      ),
    );
  }
}

// ── Dot grid background painter ───────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 24.0;
    final paint = Paint()
      ..color = const Color(0xFFD9B9FF).withValues(alpha:0.05)
      ..strokeWidth = 1;

    for (double x = 2; x < size.width; x += spacing) {
      for (double y = 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
