import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/local_auth_service.dart';
import '../services/auth_service.dart';
import '../services/navigation_service.dart';

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

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
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
            // Background blur effects
            Positioned(
              top: screenHeight * 0.1,
              right: -screenWidth * 0.2,
              child: Container(
                width: screenWidth * 0.6,
                height: screenWidth * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00D4FF).withOpacity(0.3),
                      const Color(0xFF00D4FF).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.2,
              left: -screenWidth * 0.3,
              child: Container(
                width: screenWidth * 0.8,
                height: screenWidth * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF3C7E).withOpacity(0.2),
                      const Color(0xFFFF3C7E).withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Backdrop filter for blur effect
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
                          onPressed: () {
                            Navigator.pop(context);
                          },
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
                            // Logo
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
                            // Title
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sign in to continue your premium experience',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
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
                                children: [
                                  // Email Field
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    hint: 'Enter your email address',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$',
                                      ).hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  // Password Field
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hint: 'Enter your password',
                                    obscureText: _obscurePassword,
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
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _showForgotPasswordDialog();
                                        },
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            color: Color(0xFF00D4FF),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  // Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () async {
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                setState(() {
                                                  _isLoading = true;
                                                });

                                                try {
                                                  final user =
                                                      await LocalAuthService
                                                          .instance
                                                          .signIn(
                                                            email:
                                                                _emailController
                                                                    .text
                                                                    .trim(),
                                                            password:
                                                                _passwordController
                                                                    .text,
                                                          );

                                                  if (mounted) {
                                                    if (user != null) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Login successful!',
                                                          ),
                                                          backgroundColor:
                                                              Color(0xFF00D4FF),
                                                        ),
                                                      );
                                                      Navigator.pushReplacementNamed(
                                                        context,
                                                        AppRoutes.dashboard,
                                                      );
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Invalid email or password',
                                                          ),
                                                          backgroundColor:
                                                              Color(0xFFFF3C7E),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                } catch (e) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Login failed: ${e.toString()}',
                                                        ),
                                                        backgroundColor:
                                                            const Color(
                                                              0xFFFF3C7E,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                } finally {
                                                  if (mounted) {
                                                    setState(() {
                                                      _isLoading = false;
                                                    });
                                                  }
                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF00D4FF,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF0D0B1E,
                                        ),
                                        disabledBackgroundColor: const Color(
                                          0xFF00D4FF,
                                        ).withOpacity(0.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            26,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Color(0xFF0D0B1E),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Log In',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
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
                                  // Social Login Buttons
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: OutlinedButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : () async {
                                              setState(() {
                                                _isLoading = true;
                                              });

                                              try {
                                                final result = await AuthService
                                                    .instance
                                                    .signInWithOAuth('google');

                                                if (mounted) {
                                                  if (result.success) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Google Sign-In successful!',
                                                        ),
                                                        backgroundColor: Color(
                                                          0xFF00D4FF,
                                                        ),
                                                      ),
                                                    );
                                                    Navigator.pushReplacementNamed(
                                                      context,
                                                      AppRoutes.dashboard,
                                                    );
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          result.error ??
                                                              'Google Sign-In failed',
                                                        ),
                                                        backgroundColor:
                                                            const Color(
                                                              0xFFFF3C7E,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Error: ${e.toString()}',
                                                      ),
                                                      backgroundColor:
                                                          const Color(
                                                            0xFFFF3C7E,
                                                          ),
                                                    ),
                                                  );
                                                }
                                              } finally {
                                                if (mounted) {
                                                  setState(() {
                                                    _isLoading = false;
                                                  });
                                                }
                                              }
                                            },
                                      icon: const Icon(
                                        Icons.g_mobiledata,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      label: const Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.white24,
                                          width: 1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            26,
                                          ),
                                        ),
                                        backgroundColor: Colors.white
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: OutlinedButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : () async {
                                              setState(() {
                                                _isLoading = true;
                                              });

                                              try {
                                                final result = await AuthService
                                                    .instance
                                                    .signInWithOAuth('apple');

                                                if (mounted) {
                                                  if (result.success) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Apple Sign-In successful!',
                                                        ),
                                                        backgroundColor: Color(
                                                          0xFF00D4FF,
                                                        ),
                                                      ),
                                                    );
                                                    Navigator.pushReplacementNamed(
                                                      context,
                                                      AppRoutes.dashboard,
                                                    );
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          result.error ??
                                                              'Apple Sign-In failed',
                                                        ),
                                                        backgroundColor:
                                                            const Color(
                                                              0xFFFF3C7E,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Error: ${e.toString()}',
                                                      ),
                                                      backgroundColor:
                                                          const Color(
                                                            0xFFFF3C7E,
                                                          ),
                                                    ),
                                                  );
                                                }
                                              } finally {
                                                if (mounted) {
                                                  setState(() {
                                                    _isLoading = false;
                                                  });
                                                }
                                              }
                                            },
                                      icon: const Icon(
                                        Icons.apple,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      label: const Text(
                                        'Continue with Apple',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.white24,
                                          width: 1,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            26,
                                          ),
                                        ),
                                        backgroundColor: Colors.white
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Create Account Link
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/create-account',
                                      );
                                    },
                                    child: const Text(
                                      'Don\'t have an account? Create one',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
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
            fillColor: Colors.white.withOpacity(0.1),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
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
                  fillColor: Colors.white.withOpacity(0.1),
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter your email'),
                      backgroundColor: Color(0xFFFF3C7E),
                    ),
                  );
                  return;
                }

                // Show loading indicator or handle state if needed
                // For simplicity, using AuthService resetPassword
                final result = await AuthService.instance.resetPassword(email);

                if (mounted) {
                  Navigator.of(context).pop();
                  if (result.success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Password reset link sent to your email!',
                        ),
                        backgroundColor: Color(0xFF00D4FF),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.error ?? 'Failed to send reset link',
                        ),
                        backgroundColor: const Color(0xFFFF3C7E),
                      ),
                    );
                  }
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
