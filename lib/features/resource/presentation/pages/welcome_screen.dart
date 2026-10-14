import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resource_memory/app/routing/app_route.dart';
import 'package:resource_memory/app/theme/app_colors.dart';
import 'package:resource_memory/app/theme/app_typography.dart';
import 'package:resource_memory/features/resource/data/welcome_store.dart';

/// First-launch welcome screen. Mascot waves hello, swipe up to enter.
/// One-way door: once dismissed it never shows again.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // Drag state: 0 = resting, negative = dragged upward.
  double _dragOffset = 0;
  double _opacity = 1;
  bool _leaving = false;

  late final AnimationController _hintController;
  late final AnimationController _exitController;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _hintController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    await WelcomeStore.markSeen();
    if (!mounted) return;
    // Slide the whole screen up and fade as she enters.
    final height = MediaQuery.of(context).size.height;
    final start = _dragOffset;
    _exitController.addListener(() {
      if (!mounted) return;
      setState(() {
        _dragOffset = start + (-height - start) * _exitController.value;
        _opacity = 1 - _exitController.value;
      });
    });
    await _exitController.forward();
    if (!mounted) return;
    context.go(Routes.homeScreen);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_leaving) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(-220.0, 0.0);
      _opacity = 1 - (_dragOffset.abs() / 220 * 0.4);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_leaving) return;
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset < -90 || velocity < -600) {
      _enter();
    } else {
      // Spring back home.
      setState(() {
        _dragOffset = 0;
        _opacity = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Opacity(
              opacity: _opacity,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      Text(
                        'NanyNany',
                        style: AppTypography.labelLg.copyWith(
                          color: AppColors.accent,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'You don\u2019t have to\nremember to remember.',
                        textAlign: TextAlign.center,
                        style: AppTypography.h1.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your second brain for the things\nthat slip away.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLg.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const Spacer(),
                      // The mascot, waving hello.
                      Image.asset(
                        'assets/mascot_wave.png',
                        width: 240,
                        height: 240,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                      // Swipe-up hint.
                      GestureDetector(
                        onTap: _enter,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 36, top: 12),
                          child: Column(
                            children: [
                              AnimatedBuilder(
                                animation: _hintController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      -6 * _hintController.value,
                                    ),
                                    child: child,
                                  );
                                },
                                child: const Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  color: AppColors.accent,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Swipe up to get started',
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.textSecondary,
                                ),
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
        ),
      ),
    );
  }
}
