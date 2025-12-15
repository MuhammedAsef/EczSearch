// lib/presentation/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'root_shell.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _exitVisible = true; 
  double _entryOpacity = 0.0; 

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 40), () {
      if (mounted) setState(() => _entryOpacity = 1.0);
    });

    Timer(const Duration(seconds: 5), () async {
      if (!mounted) return;
      setState(() => _exitVisible = false); 
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => const RootShell(), 
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: AnimatedOpacity(
          opacity: _exitVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1.0),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: child,
                ),
                child: AnimatedOpacity(
                  opacity: _entryOpacity, 
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOut,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 300, 
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedOpacity(
                opacity: _entryOpacity,
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                child: Text(
                  'EczSearch',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}