import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_state.dart';
import 'dashboard_screen.dart';

enum AuthMode { signIn, signUp, forgotPassword }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  AuthMode _mode = AuthMode.signIn;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode newMode) {
    setState(() {
      _mode = newMode;
      _errorMessage = '';
      _formKey.currentState?.reset();
      // Clear controllers when switching
      _nameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  String _parseFirebaseAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'This email address is already registered.';
        case 'weak-password':
          return 'The password is too weak. Must be at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later.';
        default:
          return e.message ?? 'An authentication error occurred.';
      }
    }
    return e.toString();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authNotifier = ref.read(authStateProvider.notifier);

      if (_mode == AuthMode.signIn) {
        await authNotifier.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else if (_mode == AuthMode.signUp) {
        await authNotifier.signUpWithEmail(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim(),
        );
      } else if (_mode == AuthMode.forgotPassword) {
        await authNotifier.sendPasswordReset(_emailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset link sent to your email successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _switchMode(AuthMode.signIn);
        }
      }

      // Check if user is authenticated after attempt and navigate
      if (mounted && _mode != AuthMode.forgotPassword) {
        final authState = ref.read(authStateProvider);
        if (authState.isAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _parseFirebaseAuthError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final success = await ref.read(authStateProvider.notifier).signInWithGoogle();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Google Sign-In failed or cancelled. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Branding Logo with subtle animation
                  if (!isKeyboardOpen) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.cyanAccent, Colors.blueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        size: 48,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SRI SIVA GAYATHRI',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Enterprizes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.cyanAccent,
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Stock & Billing Manager',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Glassmorphic Authentication Card
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 450),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Card Mode Title
                          Text(
                            _mode == AuthMode.signIn
                                ? 'Welcome Back'
                                : _mode == AuthMode.signUp
                                    ? 'Create Account'
                                    : 'Reset Password',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _mode == AuthMode.signIn
                                ? 'Sign in to access distributor database'
                                : _mode == AuthMode.signUp
                                    ? 'Register admin credentials to get started'
                                    : 'Enter your email to receive recovery instructions',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Dynamic Form Fields based on Mode
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Column(
                              children: [
                                if (_mode == AuthMode.signUp) ...[
                                  _buildTextField(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    icon: Icons.person_outline_rounded,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Please enter your full name.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  _buildTextField(
                                    controller: _phoneController,
                                    label: 'Mobile Number',
                                    icon: Icons.phone_android_rounded,
                                    keyboardType: TextInputType.phone,
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Please enter mobile number.';
                                      }
                                      if (!RegExp(r'^\d{10}$').hasMatch(val)) {
                                        return 'Please enter a valid 10-digit number.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  icon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter your email.';
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                                      return 'Please enter a valid email address.';
                                    }
                                    return null;
                                  },
                                ),
                                if (_mode != AuthMode.forgotPassword) ...[
                                  const SizedBox(height: 14),
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: Colors.white38,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Please enter your password.';
                                      }
                                      if (val.length < 6) {
                                        return 'Password must be at least 6 characters.';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                                if (_mode == AuthMode.signUp) ...[
                                  const SizedBox(height: 14),
                                  _buildTextField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm Password',
                                    icon: Icons.lock_clock_outlined,
                                    obscureText: _obscureConfirmPassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: Colors.white38,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Please confirm your password.';
                                      }
                                      if (val != _passwordController.text) {
                                        return 'Passwords do not match.';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Forgot Password Helper Text (only in Sign In mode)
                          if (_mode == AuthMode.signIn) ...[
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _switchMode(AuthMode.forgotPassword),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            const SizedBox(height: 20),
                          ],

                          // Error message banner inside the card
                          if (_errorMessage.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Primary Action Button (Sign In / Sign Up / Reset)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                                foregroundColor: const Color(0xFF0F172A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _isLoading ? null : _handleSubmit,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
                                      ),
                                    )
                                  : Text(
                                      _mode == AuthMode.signIn
                                          ? 'Sign In'
                                          : _mode == AuthMode.signUp
                                              ? 'Create Account'
                                              : 'Send Reset Link',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),

                          // Google Sign-In divider & button (only on SignIn / SignUp)
                          if (_mode != AuthMode.forgotPassword) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0F172A),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _handleGoogleSignIn,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/512px-Google_%22G%22_Logo.svg.png',
                                      height: 18,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.g_mobiledata,
                                        color: Colors.blueAccent,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Mode Switching footer Text Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _mode == AuthMode.signIn
                                    ? "Don't have an account?"
                                    : "Already have an account?",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11.5,
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  if (_mode == AuthMode.forgotPassword) {
                                    _switchMode(AuthMode.signIn);
                                  } else {
                                    _switchMode(_mode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn);
                                  }
                                },
                                child: Text(
                                  _mode == AuthMode.signIn
                                      ? 'Sign Up'
                                      : 'Sign In',
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
        prefixIcon: Icon(icon, size: 18, color: Colors.white.withOpacity(0.3)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 10),
      ),
    );
  }
}

// Organic Floating Animated Background circles
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Dark base premium gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A), // Tailwind Slate 900
                    Color(0xFF020617), // Tailwind Slate 950
                  ],
                ),
              ),
            ),
            // Floating bubble 1 (Top-Left area)
            Positioned(
              top: -50 + (120 * _animation.value),
              left: -50 + (100 * (1 - _animation.value)),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyan.withOpacity(0.14),
                ),
              ),
            ),
            // Floating bubble 2 (Bottom-Right area)
            Positioned(
              bottom: -60 + (140 * (1 - _animation.value)),
              right: -60 + (90 * _animation.value),
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withOpacity(0.12),
                ),
              ),
            ),
            // The content
            widget.child,
          ],
        );
      },
    );
  }
}
