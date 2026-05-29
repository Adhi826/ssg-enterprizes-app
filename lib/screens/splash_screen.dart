import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_state.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.9, curve: Curves.elasticOut)),
    );

    _controller.forward();

    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    _checkAndNavigate();
  }

  void _checkAndNavigate() {
    if (!mounted) return;
    final authState = ref.read(authStateProvider);
    
    if (authState.isInitializing) {
      Future.delayed(const Duration(milliseconds: 100), _checkAndNavigate);
      return;
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => authState.isAuthenticated ? const DashboardScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -size.height * 0.1,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D2FF).withOpacity(0.15),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.15,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFA709A).withOpacity(0.1),
                ),
              ),
            ),
            
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00D2FF), Color(0xFF0072FF)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D2FF).withOpacity(0.4),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_drink_rounded,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          children: [
                            Text(
                              'SRI SIVA GAYATHRI',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Colors.white.withOpacity(0.95),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(0, 4),
                                    blurRadius: 8,
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'ENTERPRIZES',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 4,
                                color: Colors.cyanAccent.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                      Opacity(
                        opacity: _fadeAnimation.value,
                        child: const CircularProgressIndicator(
                          color: Colors.cyanAccent,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
