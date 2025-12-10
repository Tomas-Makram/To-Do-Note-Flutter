import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shut_up/Screens/auth/login_screen.dart';
import 'package:shut_up/Screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Welcome Screen
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _opacityAnimation;
  Size mq = Size.zero;

  // Check if login or not
  Future<void> _checkAuthStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      if (user != null && user.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Animations - FIXED with safe values
    _logoAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _controller.forward();
      }
    });

    // System UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Check auth status
    Future.delayed(const Duration(seconds: 1), () {
      _checkAuthStatus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final logoScale = _logoAnimation.value;
          final textOpacity = _textAnimation.value;
          final opacityValue = _opacityAnimation.value;
          
          // Ensure opacity values are within 0.0-1.0 range
          final safeTextOpacity = textOpacity.clamp(0.0, 1.0);
          final safeOpacityValue = opacityValue.clamp(0.0, 1.0);
          
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.deepOrange.shade100.withOpacity(safeOpacityValue * 0.8),
                  Colors.orange.shade50.withOpacity(safeOpacityValue * 0.6),
                  Colors.white.withOpacity(safeOpacityValue * 0.4),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated background circles
                if (logoScale > 0)
                  Positioned(
                    top: mq.height * 0.1,
                    left: mq.width * 0.1,
                    child: Transform.scale(
                      scale: logoScale * 0.5,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.deepOrange.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ),
                
                if (logoScale > 0)
                  Positioned(
                    bottom: mq.height * 0.2,
                    right: mq.width * 0.1,
                    child: Transform.scale(
                      scale: logoScale * 0.35,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange.withOpacity(0.08),
                        ),
                      ),
                    ),
                  ),
                
                // Main content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo with animation
                    Transform.scale(
                      scale: logoScale.clamp(0.0, 2.0),
                      child: Container(
                        width: mq.width * 0.5,
                        height: mq.width * 0.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withOpacity(safeOpacityValue * 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.asset(
                              'images/Logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // App name with animation
                    Transform.translate(
                      offset: Offset(0, 20 * (1 - safeTextOpacity)),
                      child: Opacity(
                        opacity: safeTextOpacity,
                        child: Text(
                          'SHUT UP',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange.shade800,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.deepOrange.withOpacity(safeOpacityValue * 0.2),
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Tagline with animation
                    Transform.translate(
                      offset: Offset(0, 20 * (1 - safeTextOpacity)),
                      child: Opacity(
                        opacity: safeTextOpacity,
                        child: Text(
                          'Secure Private Note Pad and To-Do List',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.deepOrange.shade600,
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Loading indicator
                    Opacity(
                      opacity: safeTextOpacity,
                      child: SizedBox(
                        width: mq.width * 0.6,
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              backgroundColor: Colors.deepOrange.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.deepOrange.shade400,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              minHeight: 4,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Loading secure connection...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.deepOrange.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Footer text with animation
                Positioned(
                  bottom: mq.height * 0.05,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - safeTextOpacity)),
                    child: Opacity(
                      opacity: safeTextOpacity,
                      child: Column(
                        children: [
                          Text(
                            'Thanks for all D/Manal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepOrange.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Secure • Private • Encrypted',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Decorative elements
                if (safeTextOpacity > 0)
                  Positioned(
                    top: 50,
                    left: 20,
                    child: Opacity(
                      opacity: safeTextOpacity,
                      child: const Icon(
                        CupertinoIcons.lock_fill,
                        color: Colors.deepOrange,
                        size: 30,
                      ),
                    ),
                  ),
                
                if (safeTextOpacity > 0)
                  Positioned(
                    top: 50,
                    right: 20,
                    child: Opacity(
                      opacity: safeTextOpacity,
                      child: const Icon(
                        Icons.security,
                        color: Colors.deepOrange,
                        size: 30,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}