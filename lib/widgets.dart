import 'package:flutter/material.dart';
import 'theme.dart';

class ProgressRing extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final double size;
  final String label;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 64,
    this.label = '',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 8,
            backgroundColor: AppColors.bg,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
            ],
          )
        ],
      ),
    );
  }
}

class SmallCard extends StatelessWidget {
  final String? title;
  final String? value;
  final Color? accent;
  final IconData? icon;
  final Widget? child;

  const SmallCard({
    super.key,
    this.title,
    this.value,
    this.accent,
    this.icon,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: child ?? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) Icon(icon, color: accent ?? AppColors.primary, size: 20),
          if (icon != null) const SizedBox(height: 8),
          if (title != null) Text(title!, style: Theme.of(context).textTheme.bodySmall),
          if (value != null) Text(value!, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: accent)),
        ],
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const InfoChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class GreenButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool fullWidth;

  const GreenButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 18),
          ],
        ],
      ),
    );

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

class LeafPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;

  LeafPatternPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Draw some stylized leaf shapes
    final path = Path();
    
    // Simple leaf shape
    path.moveTo(0, 0);
    path.quadraticBezierTo(20, 0, 40, 40);
    path.quadraticBezierTo(0, 20, 0, 0);
    path.close();

    for (var i = 0; i < 5; i++) {
      for (var j = 0; j < 5; j++) {
        canvas.save();
        canvas.translate(i * size.width / 4, j * size.height / 4);
        canvas.rotate(0.5 + (i + j) * 0.2);
        canvas.scale(1.5);
        canvas.drawPath(path, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
