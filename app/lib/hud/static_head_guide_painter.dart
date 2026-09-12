// static_head_guide_painter.dart — SAFE//SPIT

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StaticHeadGuidePainter extends CustomPainter {
  final Color color;

  StaticHeadGuidePainter({
    this.color = AppColors.acidGreen, // Tactical green default
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    
    // Head oval dimensions (roughly a generic head size in the center)
    final double ovalWidth = size.width * 0.45;
    final double ovalHeight = size.height * 0.35;

    final Rect ovalRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: ovalWidth,
      height: ovalHeight,
    );

    final Paint borderPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw dashed oval using path metrics or simple continuous oval
    // A solid semi-transparent oval is cleaner and high performance
    canvas.drawOval(ovalRect, borderPaint);
    
    // Corner marks for the face bounding box
    // FIXED: was hardcoded 20.0 — now proportional to canvas width (~5%)
    final double cornerLength = size.width * 0.05;
    final Paint cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Top Left
    canvas.drawLine(Offset(ovalRect.left, ovalRect.top + cornerLength), Offset(ovalRect.left, ovalRect.top), cornerPaint);
    canvas.drawLine(Offset(ovalRect.left, ovalRect.top), Offset(ovalRect.left + cornerLength, ovalRect.top), cornerPaint);
    
    // Top Right
    canvas.drawLine(Offset(ovalRect.right, ovalRect.top + cornerLength), Offset(ovalRect.right, ovalRect.top), cornerPaint);
    canvas.drawLine(Offset(ovalRect.right, ovalRect.top), Offset(ovalRect.right - cornerLength, ovalRect.top), cornerPaint);
    
    // Bottom Left
    canvas.drawLine(Offset(ovalRect.left, ovalRect.bottom - cornerLength), Offset(ovalRect.left, ovalRect.bottom), cornerPaint);
    canvas.drawLine(Offset(ovalRect.left, ovalRect.bottom), Offset(ovalRect.left + cornerLength, ovalRect.bottom), cornerPaint);
    
    // Bottom Right
    canvas.drawLine(Offset(ovalRect.right, ovalRect.bottom - cornerLength), Offset(ovalRect.right, ovalRect.bottom), cornerPaint);
    canvas.drawLine(Offset(ovalRect.right, ovalRect.bottom), Offset(ovalRect.right - cornerLength, ovalRect.bottom), cornerPaint);

    // Text guidance
    final textSpan = TextSpan(
      text: 'ALIGN HEAD HERE',
      style: AppTextStyles.technicalLabel.copyWith(
        color: color.withValues(alpha: 0.7),
        // FIXED: was hardcoded 12 — now proportional to canvas width (~3%)
        fontSize: (size.width * 0.03).clamp(10.0, 16.0),
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Position text just below the oval
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, ovalRect.bottom + 16),
    );
  }

  @override
  bool shouldRepaint(covariant StaticHeadGuidePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
