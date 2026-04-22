import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'services/language_service.dart';
import 'l10n/app_localizations.dart';
import 'l10n/fallback_localizations.dart';
import 'pages/splash_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'pages/scan_page.dart';
import 'pages/advisory_page.dart';
import 'pages/contacts_page.dart';
import 'pages/realtime_page.dart';
import 'pages/calendar_page.dart';
import 'pages/dictionary_page.dart';
import 'services/ego_sms_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await LanguageService.init();
  
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization failed: ');
  }

  try {
    await EgoSmsService.instance.configureWithDefaults();
  } catch (e) {
    debugPrint('SMS configuration failed: ');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const BananaHealthApp());
}

class BananaHealthApp extends StatefulWidget {
  const BananaHealthApp({super.key});

  @override
  State<BananaHealthApp> createState() => _BananaHealthAppState();
}

class _BananaHealthAppState extends State<BananaHealthApp> {
  Locale _locale = LanguageService.locale;

  @override
  void initState() {
    super.initState();
    LanguageService.registerLocaleCallback((locale) {
      if (!mounted) return;
      setState(() => _locale = locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banana Health AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.bg,
        textTheme: appTextTheme,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
      ),
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        ...AppLocalizations.localizationsDelegates,
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const HomePage(),
        '/scan': (context) => const ScanPage(),
        '/advisory': (context) => const AdvisoryPage(),
        '/contacts': (context) => const ContactsPage(),
        '/realtime': (context) => const RealtimePage(),
        '/calendar': (context) => const CalendarPage(),
        '/dictionary': (context) => const DictionaryPage(),
      },
    );
  }
}