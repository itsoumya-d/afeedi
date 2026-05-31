import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/navigation_service.dart';
import '../services/local_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  // Per-field error state for inline error messages
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Clear previous inline errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = await LocalAuthService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (user != null) {
        NavigationService.navigateToHome();
      } else {
        setState(() {
          _emailError = 'Invalid email or password';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emailError = 'Sign-in failed. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await AnalyticsService.instance.trackOAuthEvent(
        platform: 'google',
        action: 'connect',
      );
      final authResult = await AuthService.instance.signInWithOAuth('google');
      if (authResult.success && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.onboardingChatbot);
      } else if (mounted) {
        _showErrorSnackBar(
          AppLocalizations.of(context)?.authenticationFailed ??
              'Authentication failed. Please try again.',
        );
      }
    } catch (_) {
      if (mounted)
        _showErrorSnackBar(
          AppLocalizations.of(context)?.authenticationFailed ??
              'Authentication failed. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await AnalyticsService.instance.trackOAuthEvent(
        platform: 'apple',
        action: 'connect',
      );
      final authResult = await AuthService.instance.signInWithOAuth('apple');
      if (authResult.success && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.onboardingChatbot);
      } else if (mounted) {
        _showErrorSnackBar(
          AppLocalizations.of(context)?.authenticationFailed ??
              'Authentication failed. Please try again.',
        );
      }
    } catch (_) {
      if (mounted)
        _showErrorSnackBar(
          AppLocalizations.of(context)?.authenticationFailed ??
              'Authentication failed. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFFFF6B6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B1E),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0B1E), Color(0xFF2D1B69)],
          ),
        ),
        child: Stack(
          children: [
            // Background ambient glow — top-right cyan
            PositionedDirectional(
              top: screenHeight * 0.1,
              end: -screenWidth * 0.2,
              child: Container(
                width: screenWidth * 0.6,
                height: screenWidth * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00D4FF).withValues(alpha: 0.3),
                      const Color(0xFF00D4FF).withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Background ambient glow — bottom-left pink
            PositionedDirectional(
              bottom: screenHeight * 0.2,
              start: -screenWidth * 0.3,
              child: Container(
                width: screenWidth * 0.8,
                height: screenWidth * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF3C7E).withValues(alpha: 0.2),
                      const Color(0xFFFF3C7E).withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Backdrop blur
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(color: Colors.transparent),
            ),
            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Logo and title
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF00D4FF),
                                    Color(0xFFFF3C7E),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              AppLocalizations.of(context)!.welcomeBack,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sign in to continue your premium experience',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Form
                    Expanded(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Form(
                            key: _formKey,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Email Field
                                  _buildTextField(
                                    controller: _emailController,
                                    label: AppLocalizations.of(context)!.email,
                                    hint: 'Enter your email address',
                                    keyboardType: TextInputType.emailAddress,
                                    externalError: _emailError,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(
                                        r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                                      ).hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Password Field
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.password,
                                    hint: 'Enter your password',
                                    obscureText: _obscurePassword,
                                    externalError: _passwordError,
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Remember Me and Forgot Password
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                            activeColor: const Color(
                                              0xFF00D4FF,
                                            ),
                                            checkColor: const Color(0xFF0D0B1E),
                                            side: const BorderSide(
                                              color: Colors.white54,
                                            ),
                                          ),
                                          const Text(
                                            'Remember me',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: _showForgotPasswordDialog,
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: Color(0xFF00D4FF),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF00D4FF,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF0D0B1E,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF0D0B1E),
                                              ),
                                            )
                                          : Text(
                                              AppLocalizations.of(
                                                context,
                                              )!.signIn,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Divider
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.white24,
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          'or',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.white24,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Google social button
                                  Semantics(
                                    button: true,
                                    label: 'Sign in with Google',
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: OutlinedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleGoogleSignIn,
                                        icon: const Icon(
                                          Icons.g_mobiledata,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.continueWithGoogle,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.white24,
                                            width: 1,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.05),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Apple social button
                                  Semantics(
                                    button: true,
                                    label: 'Sign in with Apple',
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: OutlinedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleAppleSignIn,
                                        icon: const Icon(
                                          Icons.apple,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.continueWithApple,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Colors.white24,
                                            width: 1,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.05),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Create Account link
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          AppRoutes.createAccount,
                                        );
                                      },
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.alreadyHaveAccount,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? externalError,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 16),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF1A1A2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00D4FF), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF3C7E), width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF3C7E), width: 2),
            ),
            errorStyle: const TextStyle(color: Color(0xFFFF3C7E), fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        // External / server-side inline error
        if (externalError != null) ...[
          const SizedBox(height: 4),
          Text(
            externalError,
            style: const TextStyle(color: Color(0xFFFF3C7E), fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final emailController = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF2D1B69),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Reset Password',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter your email address and we'll send you a link to reset your password.",
                style: TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1A1A2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF00D4FF),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                Navigator.of(dialogContext).pop();
                if (email.isEmpty || !email.contains('@')) {
                  _showErrorSnackBar('Please enter a valid email address.');
                  return;
                }
                // Attempt password reset via LocalAuthService
                final sent = await LocalAuthService.instance.sendPasswordReset(
                  email,
                );
                if (!mounted) return;
                if (sent) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password reset link sent! Check your inbox.',
                      ),
                      backgroundColor: Color(0xFF00D4FF),
                    ),
                  );
                } else {
                  _showErrorSnackBar(
                    'No account found with that email address.',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: const Color(0xFF0D0B1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Send Reset Link',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
