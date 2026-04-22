import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import '../theme.dart';
import '../widgets.dart';
import '../l10n/app_localizations.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isOTPSent = false;
  String? _verificationId;

  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    _passController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _toggle() {
    _animController.reset();
    setState(() => _isSignUp = !_isSignUp);
    _animController.forward();
  }

  Future<void> _saveUserData(User user, String? name,
      {String? phoneNumber}) async {
    Map<String, dynamic> userData = {
      'name': name ?? user.displayName ?? 'Farmer',
      'createdAt': ServerValue.timestamp,
    };
    if (user.email != null) userData['email'] = user.email;
    if (phoneNumber != null) userData['phone'] = phoneNumber;

    await _dbRef.child('users').child(user.uid).update(userData);
  }

  Future<void> _handleAuth() async {
    String phoneText = _phoneController.text.trim();
    String password = _passController.text.trim();

    final l10n = AppLocalizations.of(context);
    if (phoneText.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(l10n?.pleaseFillAllFields ?? 'Please fill in all fields')));
      return;
    }

    if (_isSignUp && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n?.pleaseEnterName ?? 'Please enter your name')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // For village farmers, we'll use a virtual email based on phone number
      // format: 256770000000@bananahealth.ai
      if (phoneText.startsWith('0') && phoneText.length == 10) {
        phoneText = phoneText.substring(1);
      }
      String virtualEmail = '256$phoneText@bananahealth.ai';

      if (_isSignUp) {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: virtualEmail,
          password: password,
        );
        if (credential.user != null) {
          await _saveUserData(credential.user!, _nameController.text.trim(),
              phoneNumber: '+256$phoneText');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l10n?.accountCreated ??
                  'Account created! Sign in to continue.')));
          setState(() {
            _isSignUp = false;
            _passController.clear();
          });
        }
      } else {
        await _auth.signInWithEmailAndPassword(
          email: virtualEmail,
          password: password,
        );
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? l10n?.authenticationFailed ?? 'Authentication failed';
      if (e.code == 'user-not-found') {
        message = l10n?.noAccountFound ?? 'No account found for this phone number.';
      }
      if (e.code == 'wrong-password') {
        message = l10n?.incorrectPassword ?? 'Incorrect password.';
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      // Ensure we clear previous sign-in state to avoid silent failures
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        // Only save if it's a new user or missing data
        await _saveUserData(userCredential.user!, null);
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      if (mounted) {
        String errorMsg = l10n?.googleSignInFailed ?? 'Google Sign-In failed';
        if (e.toString().contains('network_error')) {
          errorMsg = l10n?.networkError ?? 'Network error. Please check your connection.';
        }
        if (e.toString().contains('sign_in_failed')) {
          errorMsg = l10n?.signInFailedTryAgain ?? 'Sign in failed. Please try again.';
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOTP() async {
    final l10n = AppLocalizations.of(context);
    String phoneText = _phoneController.text.trim();
    if (phoneText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              l10n?.pleaseEnterPhone ?? 'Please enter your phone number')));
      return;
    }

    // Strip leading zero if the user entered 10 digits
    if (phoneText.startsWith('0') && phoneText.length == 10) {
      phoneText = phoneText.substring(1);
    }

    String fullPhoneNumber = '+256$phoneText';

    setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          if (mounted) {
            Navigator.pop(context); // Close bottom sheet
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          String msg = e.message ?? l10n?.verificationFailed ?? 'Verification failed';
          if (e.code == 'billing-not-enabled') {
            msg = l10n?.billingRequired ??
                'Phone verification requires Firebase Blaze plan or test numbers. Please use a registered test number.';
          } else if (e.code == 'admin-restricted-operation') {
            msg = l10n?.operationRestricted ??
                'Operation restricted. Ensure Phone Sign-in is enabled in Firebase Console.';
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(msg), duration: const Duration(seconds: 5)));
        },
        codeSent: (String verId, int? resendToken) {
          setState(() {
            _isOTPSent = true;
            _verificationId = verId;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  l10n?.verificationCodeSent ?? 'Verification code sent!')));
        },
        codeAutoRetrievalTimeout: (String verId) {
          _verificationId = verId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n?.error(e.toString()) ?? 'Error: $e')));
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        String phone = _phoneController.text.trim();
        if (phone.startsWith('0')) phone = phone.substring(1);
        await _saveUserData(userCredential.user!, null,
            phoneNumber: '+256$phone');
      }
      if (mounted) {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              l10n?.invalidCodeTryAgain ?? 'Invalid code. Please try again.')));
    }
  }

  void _showPhoneSignInDialog() {
    setState(() {
      _isOTPSent = false;
      _otpController.clear();
      _phoneController.clear();
    });

    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28), topRight: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
                left: 28,
                right: 28,
                top: 28,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.borderDark,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 24),
                  Text(l10n?.signIn ?? 'Sign In',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text(
                    _isOTPSent
                        ? (l10n?.enterCodeSent ??
                            'Enter the 6-digit code sent to your phone')
                        : (l10n?.enterPhoneForVerification ??
                            'Enter your phone number to receive a verification code'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  if (!_isOTPSent)
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10)
                      ],
                      decoration: AppDecorations.inputDecoration(
                              l10n?.phoneNumber ?? 'Phone Number',
                              Icons.phone_android)
                          .copyWith(
                        prefixText: '+256 ',
                        prefixStyle: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                        hintText: '770123456',
                      ),
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                    )
                  else
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6)
                      ],
                      decoration: AppDecorations.inputDecoration(
                          l10n?.digitCode ?? '6-Digit Code',
                          Icons.lock_clock_outlined),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    GreenButton(
                      label: _isOTPSent
                          ? (l10n?.verifyOTP ?? 'Verify OTP')
                          : (l10n?.sendCode ?? 'Send Code'),
                      onPressed: () async {
                        if (!_isOTPSent) {
                          await _sendOTP();
                          setModalState(() {});
                        } else {
                          await _verifyOTP();
                        }
                      },
                      fullWidth: true,
                    ),
                  if (_isOTPSent) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setModalState(() => _isOTPSent = false);
                      },
                      child: Text(l10n?.changePhoneNumber ?? 'Change Phone Number',
                          style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold)),
                    )
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 260,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)]),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40)),
              ),
              child: SafeArea(
                child: CustomPaint(
                  painter:
                      LeafPatternPainter(color: Colors.white, opacity: 0.04),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white70, size: 18),
                            onPressed: () =>
                                Navigator.pushReplacementNamed(context, '/')),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.25))),
                              child: const Icon(Icons.eco,
                                  color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isSignUp
                                        ? (l10n?.signUp ?? 'Sign Up')
                                        : (l10n?.welcomeBack ?? 'Welcome Back'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
                                  ),
                                  Text(
                                    _isSignUp
                                        ? (l10n?.joinThousands ??
                                            'Join thousands of farmers')
                                        : (l10n?.appTitle ??
                                            'Banana Health AI'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.65)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
              top: 260,
              child: CustomPaint(
                  painter: LeafPatternPainter(
                      color: AppColors.primary, opacity: 0.03))),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 200, 20, 40 + bottomInset),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.primaryDeep.withValues(alpha: 0.10),
                                blurRadius: 32,
                                offset: const Offset(0, 12))
                          ]),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                  _isSignUp
                                      ? (l10n?.signUp ?? 'Sign Up')
                                      : (l10n?.signIn ?? 'Sign in'),
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Text(
                                  _isSignUp
                                      ? (l10n?.joinThousands ??
                                          'Fill in your information to get started')
                                      : (l10n?.diagnoseAndProtect ??
                                          'Enter your credentials to continue'),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted)),
                              const SizedBox(height: 24),
                              if (_isSignUp) ...[
                                TextField(
                                    controller: _nameController,
                                    decoration: AppDecorations.inputDecoration(
                                        l10n?.fullName ?? 'Full Name',
                                        Icons.person_outline),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 14),
                              ],
                              TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10)
                                  ],
                                  decoration: AppDecorations.inputDecoration(
                                          l10n?.phoneNumber ?? 'Phone Number',
                                          Icons.phone_android)
                                      .copyWith(
                                    prefixText: '+256 ',
                                    prefixStyle: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 14),
                              TextField(
                                  controller: _passController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textPrimary),
                                  decoration: AppDecorations.inputDecoration(
                                          l10n?.password ?? 'Password',
                                          Icons.lock_outline)
                                      .copyWith(
                                          suffixIcon: IconButton(
                                              icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                          .visibility_off_outlined
                                                      : Icons
                                                          .visibility_outlined,
                                                  color: AppColors.textMuted,
                                                  size: 18),
                                              onPressed: () => setState(() =>
                                                  _obscurePassword =
                                                      !_obscurePassword)))),
                              const SizedBox(height: 20),
                              if (_isLoading)
                                const Center(child: CircularProgressIndicator())
                              else
                                GreenButton(
                                    label: _isSignUp
                                        ? (l10n?.signUp ?? 'Create Account')
                                        : (l10n?.signIn ?? 'Sign In'),
                                    icon: _isSignUp ? Icons.eco : Icons.login,
                                    onPressed: _handleAuth,
                                    fullWidth: true),
                              const SizedBox(height: 20),
                              Row(children: [
                                const Expanded(child: Divider()),
                                Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(l10n?.or ?? 'Or',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted))),
                                const Expanded(child: Divider())
                              ]),
                              const SizedBox(height: 16),
                              _SocialButton(
                                  label: l10n?.google ?? 'Google',
                                  icon: Icons.g_mobiledata,
                                  onTap: _handleGoogleSignIn),
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: _showPhoneSignInDialog,
                                  child: Text(
                                    l10n?.signInWithPhone ?? 'Sign in with Phone',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Text(
                            _isSignUp
                                ? (l10n?.alreadyHaveAccount ??
                                    'Already have an account?')
                                : (l10n?.dontHaveAccount ??
                                    "Don't have an account?"),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggle,
                            child: Text(
                              _isSignUp
                                  ? (l10n?.signIn ?? 'Sign In')
                                  : (l10n?.signUp ?? 'Sign Up'),
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SocialButton(
      {required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.5), width: 1.5),
            borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary))
        ]),
      ),
    );
  }
}
