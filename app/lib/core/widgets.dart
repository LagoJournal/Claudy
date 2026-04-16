import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

// ── Pixel-style full-width button ─────────────────────────────────────────────
class PixelButton extends StatelessWidget {
  final Widget child;
  final Color bg;
  final VoidCallback? onTap;
  const PixelButton({super.key, required this.child, required this.bg, this.onTap});

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

// ── Labeled text input with pixel border ─────────────────────────────────────
class PixelField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  const PixelField({
    super.key,
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
                color: CL.outline.withValues(alpha: 0.4), fontSize: 16),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Quick-action grid tile ────────────────────────────────────────────────────
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  const ActionTile({
    super.key,
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
              fontSize: 14, fontWeight: FontWeight.w900,
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
