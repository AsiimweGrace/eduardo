import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        _buildLogo(),
                        const SizedBox(height: 48),
                        _buildTitle(context, l10n),
                        const SizedBox(height: 48),
                        _buildLanguageButtons(context, l10n),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
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
    );
  }

  Widget _buildTitle(BuildContext context, AppLocalizations? l10n) {
    return Column(
      children: [
        const Text(
          'Banana\nHealth AI',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n?.selectLanguage ?? 'Select Language',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

    Widget _buildLanguageButtons(BuildContext context, AppLocalizations? l10n) {
    return Column(
      children: [
        _buildLanguageButton(
          context,
          'English',
          'English',
          () => _selectLanguage(context, 'en'),
        ),
        const SizedBox(height: 16),
        _buildLanguageButton(
          context,
          'Runyankole',
          'Runyankole',
          () => _selectLanguage(context, 'rw'),
        ),
      ],
    );
  }

  Widget _buildLanguageButton(
    BuildContext context,
    String englishName,
    String localName,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.language, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        englishName,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        localName,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.60),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _selectLanguage(BuildContext context, String languageCode) async {
    await LanguageService.setLocale(Locale(languageCode));
    if (context.mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
      }
    }
  }
}


