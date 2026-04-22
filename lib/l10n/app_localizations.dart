import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_rw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('rw')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Banana Health AI'**
  String get appTitle;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @advisory.
  ///
  /// In en, this message translates to:
  /// **'Advisory'**
  String get advisory;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthy;

  /// No description provided for @diseased.
  ///
  /// In en, this message translates to:
  /// **'Diseased'**
  String get diseased;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @scanDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan a banana leaf to detect diseases'**
  String get scanDescription;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @treatment.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get treatment;

  /// No description provided for @prevention.
  ///
  /// In en, this message translates to:
  /// **'Prevention'**
  String get prevention;

  /// No description provided for @viewDictionary.
  ///
  /// In en, this message translates to:
  /// **'View Dictionary'**
  String get viewDictionary;

  /// No description provided for @noDiseaseDetected.
  ///
  /// In en, this message translates to:
  /// **'No disease detected'**
  String get noDiseaseDetected;

  /// No description provided for @diseaseDetected.
  ///
  /// In en, this message translates to:
  /// **'Disease detected'**
  String get diseaseDetected;

  /// No description provided for @consultExpert.
  ///
  /// In en, this message translates to:
  /// **'Consult an expert'**
  String get consultExpert;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get addContact;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @weatherAdvisory.
  ///
  /// In en, this message translates to:
  /// **'Weather Advisory'**
  String get weatherAdvisory;

  /// No description provided for @plantingAdvice.
  ///
  /// In en, this message translates to:
  /// **'Planting Advice'**
  String get plantingAdvice;

  /// No description provided for @harvestingAdvice.
  ///
  /// In en, this message translates to:
  /// **'Harvesting Advice'**
  String get harvestingAdvice;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// No description provided for @aiGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello! I am your Banana Health AI.'**
  String get aiGreeting;

  /// No description provided for @aiHowCanIHelp.
  ///
  /// In en, this message translates to:
  /// **'How can I help you today?'**
  String get aiHowCanIHelp;

  /// No description provided for @askAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI...'**
  String get askAi;

  /// No description provided for @currentDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Current Diagnosis'**
  String get currentDiagnosis;

  /// No description provided for @scanHistory.
  ///
  /// In en, this message translates to:
  /// **'Scan History'**
  String get scanHistory;

  /// No description provided for @goToScan.
  ///
  /// In en, this message translates to:
  /// **'Go to Scan'**
  String get goToScan;

  /// No description provided for @scanInstruction.
  ///
  /// In en, this message translates to:
  /// **'Scan a leaf to get treatment recommendations'**
  String get scanInstruction;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history found'**
  String get noHistory;

  /// No description provided for @aiDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'AI Diagnosis'**
  String get aiDiagnosis;

  /// No description provided for @aiReady.
  ///
  /// In en, this message translates to:
  /// **'AI Ready'**
  String get aiReady;

  /// No description provided for @alignLeaf.
  ///
  /// In en, this message translates to:
  /// **'Align the leaf within the frame'**
  String get alignLeaf;

  /// No description provided for @daylightTip.
  ///
  /// In en, this message translates to:
  /// **'Works best in natural daylight'**
  String get daylightTip;

  /// No description provided for @realTimeDetection.
  ///
  /// In en, this message translates to:
  /// **'Real-Time Detection'**
  String get realTimeDetection;

  /// No description provided for @focusTip.
  ///
  /// In en, this message translates to:
  /// **'Front side / Good light / In focus'**
  String get focusTip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @joinThousands.
  ///
  /// In en, this message translates to:
  /// **'Join thousands of farmers'**
  String get joinThousands;

  /// No description provided for @diagnoseAndProtect.
  ///
  /// In en, this message translates to:
  /// **'Diagnose disease. Protect your harvest.'**
  String get diagnoseAndProtect;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get dontHaveAccount;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created! Sign in to continue.'**
  String get accountCreated;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @verificationCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent!'**
  String get verificationCodeSent;

  /// No description provided for @invalidCodeTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Invalid code. Please try again.'**
  String get invalidCodeTryAgain;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(String error);

  /// No description provided for @changePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Change Phone Number'**
  String get changePhoneNumber;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'Or'**
  String get or;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @signInWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Phone'**
  String get signInWithPhone;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @initializingCamera.
  ///
  /// In en, this message translates to:
  /// **'Initializing camera...'**
  String get initializingCamera;

  /// No description provided for @pointCameraAtLeaves.
  ///
  /// In en, this message translates to:
  /// **'Point camera at banana leaves for automatic detection'**
  String get pointCameraAtLeaves;

  /// No description provided for @goodLight.
  ///
  /// In en, this message translates to:
  /// **'Good light'**
  String get goodLight;

  /// No description provided for @inFocus.
  ///
  /// In en, this message translates to:
  /// **'In focus'**
  String get inFocus;

  /// No description provided for @frontSide.
  ///
  /// In en, this message translates to:
  /// **'Front side'**
  String get frontSide;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required for real-time detection'**
  String get cameraPermissionRequired;

  /// No description provided for @noCamerasAvailable.
  ///
  /// In en, this message translates to:
  /// **'No cameras available on this device'**
  String get noCamerasAvailable;

  /// No description provided for @noCropDetected.
  ///
  /// In en, this message translates to:
  /// **'No Crop Detected'**
  String get noCropDetected;

  /// No description provided for @scanResult.
  ///
  /// In en, this message translates to:
  /// **'Scan Result'**
  String get scanResult;

  /// No description provided for @seeTreatmentOptions.
  ///
  /// In en, this message translates to:
  /// **'See Treatment Options'**
  String get seeTreatmentOptions;

  /// No description provided for @viewTreatment.
  ///
  /// In en, this message translates to:
  /// **'View Treatment'**
  String get viewTreatment;

  /// No description provided for @recommendedManagementPlan.
  ///
  /// In en, this message translates to:
  /// **'Recommended management plan'**
  String get recommendedManagementPlan;

  /// No description provided for @maintainPlantHealth.
  ///
  /// In en, this message translates to:
  /// **'Maintain your plant health'**
  String get maintainPlantHealth;

  /// No description provided for @recommendedActions.
  ///
  /// In en, this message translates to:
  /// **'Recommended Actions'**
  String get recommendedActions;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority: {priority}'**
  String priority(String priority);

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @wasDiagnosisAccurate.
  ///
  /// In en, this message translates to:
  /// **'Was this diagnosis accurate?'**
  String get wasDiagnosisAccurate;

  /// No description provided for @yesCorrect.
  ///
  /// In en, this message translates to:
  /// **'Yes, correct'**
  String get yesCorrect;

  /// No description provided for @noWrong.
  ///
  /// In en, this message translates to:
  /// **'No, wrong'**
  String get noWrong;

  /// No description provided for @helpUsImprove.
  ///
  /// In en, this message translates to:
  /// **'Help us improve'**
  String get helpUsImprove;

  /// No description provided for @correctDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'What is the correct diagnosis?'**
  String get correctDiagnosis;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @thankYouFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get thankYouFeedback;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @myFarms.
  ///
  /// In en, this message translates to:
  /// **'My Farms'**
  String get myFarms;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @averageAcrossPlots.
  ///
  /// In en, this message translates to:
  /// **'Average across plots'**
  String get averageAcrossPlots;

  /// No description provided for @applyIn3Days.
  ///
  /// In en, this message translates to:
  /// **'Apply in 3 days'**
  String get applyIn3Days;

  /// No description provided for @dictionary.
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get dictionary;

  /// No description provided for @sendSms.
  ///
  /// In en, this message translates to:
  /// **'Send SMS'**
  String get sendSms;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @enterPhoneForVerification.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to receive a verification code'**
  String get enterPhoneForVerification;

  /// No description provided for @enterCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to your phone'**
  String get enterCodeSent;

  /// No description provided for @digitCode.
  ///
  /// In en, this message translates to:
  /// **'6-Digit Code'**
  String get digitCode;

  /// No description provided for @verifyOTP.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOTP;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authenticationFailed;

  /// No description provided for @noAccountFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for this phone number'**
  String get noAccountFound;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPassword;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @billingRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone verification requires Firebase Blaze plan or test numbers. Please use a registered test number.'**
  String get billingRequired;

  /// No description provided for @operationRestricted.
  ///
  /// In en, this message translates to:
  /// **'Operation restricted. Ensure Phone Sign-in is enabled in Firebase Console.'**
  String get operationRestricted;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed'**
  String get googleSignInFailed;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// No description provided for @signInFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please try again.'**
  String get signInFailedTryAgain;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'rw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'rw':
      return AppLocalizationsRw();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
