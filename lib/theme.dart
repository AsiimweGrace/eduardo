import 'package:flutter/material.dart';

class AppColors {
  // Core palette
  static const Color primary = Color(0xFF52B788);
  static const Color primaryDark = Color(0xFF2D6A4F);
  static const Color primaryDeep = Color(0xFF1B4332);
  static const Color primaryLight = Color(0xFF95D5B2);
  static const Color primaryPale = Color(0xFFD8F3DC);

  // Accent
  static const Color accent = Color(0xFFFFD166);
  static const Color accentWarm = Color(0xFFF4A261);

  // Neutrals
  static const Color bg = Color(0xFFF8FAF8);
  static const Color bgDark = Color(0xFFEDF7EF);
  static const Color card = Colors.white;
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color borderDark = Color(0xFFC9E2D0);
  static const Color muted = Color(0xFF95B8A0);
  static const Color mutedDark = Color(0xFF6B8F71);

  // Text
  static const Color textPrimary = Color(0xFF1B2E22);
  static const Color textSecondary = Color(0xFF4A6651);
  static const Color textMuted = Color(0xFF8FA897);

  // Status colors
  static const Color success = Color(0xFF40916C);
  static const Color warning = Color(0xFFFFB703);
  static const Color danger = Color(0xFFE63946);
  static const Color info = Color(0xFF4CC9F0);

  // Gradient stops
  static const List<Color> heroGradient = [
    Color(0xFF1B4332),
    Color(0xFF2D6A4F),
    Color(0xFF52B788),
  ];

  static const List<Color> cardGradient = [
    Color(0xFFD8F3DC),
    Color(0xFFB7E4C7),
  ];

  static const List<Color> bgGradient = [
    Color(0xFFEDF7EF),
    Color(0xFFF8FAF8),
  ];
}

const TextTheme appTextTheme = TextTheme(
  displayLarge: TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.1,
    letterSpacing: -0.5,
  ),
  displayMedium: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.3,
  ),
  headlineLarge: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  ),
  headlineMedium: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  ),
  headlineSmall: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  ),
  titleLarge: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  ),
  titleMedium: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  ),
  titleSmall: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  ),
  bodyLarge: TextStyle(
    fontSize: 15,
    color: AppColors.textSecondary,
    height: 1.6,
  ),
  bodyMedium: TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.5,
  ),
  bodySmall: TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
    height: 1.5,
    letterSpacing: 0.2,
  ),
  labelLarge: TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.8,
  ),
);

// Added styles for Advisory page compatibility
class AppTextStyles {
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyRegular = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  static const TextStyle subtitleSemiBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
  );
}

//  Decorations 
class AppDecorations {
  static BoxDecoration get card => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get cardElevated => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.10),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      );

  static BoxDecoration get greenCard => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.cardGradient,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static InputDecoration inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.mutedDark,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.primaryPale.withValues(alpha: 0.4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primaryLight.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
      );
}

//  Reusable Button Styles 
class AppButtons {
  static ButtonStyle get primaryStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        padding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );

  static Widget primary({required String label, required VoidCallback onTap}) =>
      ElevatedButton(
        onPressed: onTap,
        style: primaryStyle,
        child: Text(label),
      );

  static ButtonStyle get ghost => OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );
}

//  AppScaffold 
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final bool showBottomNav;
  final int currentIndex;
  final ValueChanged<int>? onTabChanged;
  final List<Widget>? actions;
  final bool extendBodyBehindAppBar;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.showBottomNav = true,
    this.currentIndex = 0,
    this.onTabChanged,
    this.actions,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: title != null
          ? AppBar(
              title: Text(title!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              backgroundColor:
                  extendBodyBehindAppBar ? Colors.transparent : Colors.white,
              elevation: 0,
              centerTitle: true,
              iconTheme:
                  const IconThemeData(color: AppColors.textPrimary),
              actions: actions,
              surfaceTintColor: Colors.transparent,
            )
          : null,
      body: body,
      bottomNavigationBar: showBottomNav ? _buildNav(context) : null,
    );
  }

  Widget _buildNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.document_scanner_outlined, activeIcon: Icons.document_scanner, label: 'Scan', index: 0, currentIndex: currentIndex, onTap: (i) => _navigate(context, i)),
              _NavItem(icon: Icons.local_florist_outlined, activeIcon: Icons.local_florist, label: 'Advisory', index: 1, currentIndex: currentIndex, onTap: (i) => _navigate(context, i)),
              _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Experts', index: 2, currentIndex: currentIndex, onTap: (i) => _navigate(context, i)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    if (onTabChanged != null) {
      onTabChanged!(index);
      return;
    }
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/scan');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/advisory');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/contacts');
        break;
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryDark.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive ? AppColors.primaryDark : AppColors.textMuted,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
