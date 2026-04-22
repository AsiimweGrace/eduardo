import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  int _page = 0;
  late PageController _pageController;
  late AnimationController _itemController;
  late Animation<double> _itemFade;
  late Animation<Offset> _itemSlide;

  final _pages = [
    _OnboardData(
      icon: Icons.document_scanner_outlined,
      accentIcon: Icons.camera_enhance,
      color: AppColors.primary,
      tag: 'INSTANT RESULTS',
      title: 'Scan & Diagnose',
      description:
          'Point your camera at any banana leaf. Our AI identifies diseases in seconds with lab-grade accuracy.',
      features: ['Black Sigatoka', 'Fusarium Wilt', 'Bunchy Top', 'Panama Disease'],
    ),
    _OnboardData(
      icon: Icons.local_florist_outlined,
      accentIcon: Icons.health_and_safety,
      color: AppColors.success,
      tag: 'PERSONALIZED PLANS',
      title: 'Expert Advisory',
      description:
          'Get tailored treatment plans, seasonal best practices, and step-by-step care protocols.',
      features: ['Treatment Plans', 'Seasonal Tips', 'Fertilizer Guides', 'Harvest Timing'],
    ),
    _OnboardData(
      icon: Icons.people_outline,
      accentIcon: Icons.support_agent,
      color: AppColors.primaryDark,
      tag: 'LOCAL NETWORK',
      title: 'Connect & Grow',
      description:
          'Reach certified agronomists, extension officers and pest-control experts in your region.',
      features: ['Verified Experts', 'Video Calls', 'Farm Visits', 'Agri-Clinics'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _itemController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _itemFade = CurvedAnimation(parent: _itemController, curve: Curves.easeOut);
    _itemSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _itemController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_page < _pages.length - 1) {
      setState(() => _page++);
      _pageController.animateToPage(
        _page,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
      _itemController.reset();
      _itemController.forward();
    } else {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _pages[_page];
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  data.color.withValues(alpha: 0.08),
                  AppColors.bg,
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: LeafPatternPainter(
                color: data.color,
                opacity: 0.04,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      if (_page > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                          onPressed: () {
                            setState(() => _page--);
                            _pageController.animateToPage(
                              _page,
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeInOutCubic,
                            );
                          },
                          color: AppColors.textPrimary,
                        )
                      else
                        const SizedBox(width: 48),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/auth'),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _buildPageContent(_pages[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _page == i ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _page == i
                                  ? data.color
                                  : AppColors.primaryPale,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      GreenButton(
                        label: _page < _pages.length - 1 ? 'Continue' : 'Get Started',
                        icon: _page < _pages.length - 1
                            ? Icons.arrow_forward_rounded
                            : Icons.eco,
                        onPressed: _nextPage,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(_OnboardData data) {
    return SlideTransition(
      position: _itemSlide,
      child: FadeTransition(
        opacity: _itemFade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      data.color.withValues(alpha: 0.15),
                      data.color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: data.color.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      data.accentIcon,
                      size: 100,
                      color: data.color.withValues(alpha: 0.15),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: data.color.withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(data.icon, size: 36, color: data.color),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data.tag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: data.color,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.description,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.features
                    .map<Widget>((f) => InfoChip(
                          label: f,
                          icon: Icons.check_circle_outline,
                          color: data.color,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardData {
  final IconData icon;
  final IconData accentIcon;
  final Color color;
  final String tag;
  final String title;
  final String description;
  final List<String> features;

  const _OnboardData({
    required this.icon,
    required this.accentIcon,
    required this.color,
    required this.tag,
    required this.title,
    required this.description,
    required this.features,
  });
}
