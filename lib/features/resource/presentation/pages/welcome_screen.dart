import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resource_memory/app/routing/app_route.dart';
import 'package:resource_memory/features/resource/data/welcome_store.dart';

/// First-launch welcome screen in Todoist style: warm white canvas,
/// quiet typography, one red verb. Mascot waves hello below the headline,
/// swipe up to enter. One-way door: once dismissed it never shows again.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // Todoist palette.
  static const _canvas = Color(0xFFFDFCFA);
  static const _ink = Color(0xFF202020);
  static const _secondary = Color(0xFF808080);
  static const _verb = Color(0xFFDC4C3E); // Todoist red: actions only.

  // Drag state: 0 = resting, negative = dragged upward.
  double _dragOffset = 0;
  double _opacity = 1;
  bool _leaving = false;

  late final AnimationController _hintController;
  late final AnimationController _exitController;
  late final AnimationController _waveController;

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
    // Gentle wave: the mascot rocks side to side like it's waving hello.
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hintController.dispose();
    _exitController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    await WelcomeStore.markSeen();
    if (!mounted) return;
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
      setState(() {
        _dragOffset = 0;
        _opacity = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      body: GestureDetector(
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        behavior: HitTestBehavior.opaque,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Opacity(
            opacity: _opacity,
            child: SafeArea(
              // Proven pattern from the home screen: Center +
              // ConstrainedBox keeps content centered on wide screens.
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 56),
                        const Text(
                          'NANYNANY',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3,
                            color: _verb,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'You don\u2019t have to\nremember to remember.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your second brain for the things\nthat slip away.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.5,
                            color: _secondary,
                          ),
                        ),
                        const Spacer(),
                        // The mascot, waving hello.
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            // Gentle rock + bob, like a happy wave.
                            final t = _waveController.value;
                            return Transform.translate(
                              offset: Offset(0, -8 * t),
                              child: Transform.rotate(
                                angle: 0.06 * (t * 2 - 1),
                                child: child,
                              ),
                            );
                          },
                          child: Image.asset(
                            'assets/mascot_wave_light.png',
                            width: 240,
                            height: 240,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const Spacer(),
                        // Swipe-up hint.
                        GestureDetector(
                          onTap: _enter,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: 40, top: 12),
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
                                    color: _verb,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Swipe up to get started',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _secondary,
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
      ),
    );
  }
}
