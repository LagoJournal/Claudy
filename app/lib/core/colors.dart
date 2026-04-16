import 'package:flutter/material.dart';

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
