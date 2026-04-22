import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _leafController;

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _leafAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _leafController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _scaleAnim = CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _leafAnim = CurvedAnimation(parent: _leafController, curve: Curves.linear);

    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
      _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _leafController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          //  Deep forest gradient background 
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D2818),
                  Color(0xFF1B4332),
                  Color(0xFF2D6A4F),
                ],
              ),
            ),
          ),

          //  Decorative circles 
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.08),
              ),
            ),
          ),

          //  Animated leaf pattern 
          AnimatedBuilder(
            animation: _leafAnim,
            builder: (context, child) {
              return CustomPaint(
                painter: _SplashLeafPainter(animation: _leafAnim.value),
                size: MediaQuery.of(context).size,
              );
            },
          ),

          //  Content 
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 8),
                          // Logo
                          ScaleTransition(
                            scale: _scaleAnim,
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: _buildLogo(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Text
                          SlideTransition(
                            position: _slideAnim,
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: _buildText(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // CTA
                          SlideTransition(
                            position: _slideAnim,
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: _buildCTA(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Hexagonal logo container
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow ring
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              const Icon(
                Icons.eco,
                size: 48,
                color: Colors.white,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Version tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: const Text(
            'AI-POWERED',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Feature icons row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFeatureIcon(Icons.camera_alt_outlined, 'Scan'),
            const SizedBox(width: 24),
            _buildFeatureIcon(Icons.psychology_outlined, 'AI'),
            const SizedBox(width: 24),
            _buildFeatureIcon(Icons.eco_outlined, 'Health'),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildText() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(
          l10n?.appTitle ?? 'Banana\nHealth AI',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n?.diagnoseAndProtect ?? 'Diagnose disease. Protect your harvest.\nConnect with expert agronomists.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 15,
            color: Colors.white.withValues(alpha: 0.70),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildCTA() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // Language Selection (Integrated)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Text(
                l10n?.selectLanguage ?? 'Select Language',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildLangChip('English', 'en'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLangChip('Runyankole', 'rw'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Primary CTA
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushReplacementNamed(context, '/auth'),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n?.getStarted ?? 'Get Started',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Sign in
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
          child: Text(
            l10n?.alreadyHaveAccount ?? 'Already have an account? Sign in',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.60),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLangChip(String label, String code) {
    bool isSelected = LanguageService.locale.languageCode == code;
    return GestureDetector(
      onTap: () async {
        await LanguageService.setLocale(Locale(code));
        if (mounted) {
          setState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : Colors.white24,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashLeafPainter extends CustomPainter {
  final double animation;
  _SplashLeafPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    final leaves = [
      [0.1, 0.15, 0.8, 0.0],
      [0.85, 0.25, 1.2, math.pi * 0.6],
      [0.2, 0.7, 0.6, math.pi * 1.2],
      [0.75, 0.8, 1.0, math.pi * 0.3],
      [0.5, 0.4, 0.5, math.pi * 1.7],
    ];

    for (final leaf in leaves) {
      final x = leaf[0] * size.width;
      final y = leaf[1] * size.height;
      final scale = leaf[2];
      final baseAngle = leaf[3];
      final drift = math.sin(animation * math.pi * 2 + baseAngle) * 0.1;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(baseAngle + drift);
      canvas.scale(scale * 40);

      final path = Path()
        ..moveTo(0, -1.2)
        ..cubicTo(0.6, -0.8, 0.8, 0.2, 0, 0.8)
        ..cubicTo(-0.8, 0.2, -0.6, -0.8, 0, -1.2);

      canvas.drawPath(path, paint);

      final strokePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.02)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.05;
      canvas.drawLine(const Offset(0, -1.1), const Offset(0, 0.7), strokePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SplashLeafPainter old) => old.animation != animation;
}
