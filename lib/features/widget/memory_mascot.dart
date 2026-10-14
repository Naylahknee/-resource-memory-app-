import 'package:flutter/material.dart';
import 'todoist_light.dart';

enum MemoryMood { welcome, saved, searching, found, reminder }

/// A single, short acknowledgement, never an idle animation loop.
class MemoryMascot extends StatelessWidget {
  const MemoryMascot({super.key, this.mood = MemoryMood.welcome, this.size = 104});
  final MemoryMood mood;
  final double size;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final icon = switch (mood) {
      MemoryMood.welcome => Icons.waving_hand_outlined,
      MemoryMood.saved => Icons.check_rounded,
      MemoryMood.searching => Icons.search_rounded,
      MemoryMood.found => Icons.bookmark_added_outlined,
      MemoryMood.reminder => Icons.notifications_none_rounded,
    };
    return Semantics(
      label: 'NanyNany: ${mood.name}',
      image: true,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(mood),
        tween: Tween(begin: reduced ? 1 : 0, end: 1),
        duration: Duration(milliseconds: reduced ? 0 : 280),
        curve: Curves.easeOutCubic,
        builder: (_, value, child) => Opacity(
          opacity: reduced ? 1 : .7 + .3 * value,
          child: Transform.translate(
            offset: Offset(0, reduced ? 0 : 6 * (1 - value)), child: child),
        ),
        child: SizedBox(
          width: size, height: size,
          child: Stack(children: [
            Image.asset('assets/mascot_wave_light.png', width: size, height: size, excludeFromSemantics: true),
            Positioned(right: 0, bottom: 0, child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: TodoistLight.verbTint, shape: BoxShape.circle),
              child: Icon(icon, color: TodoistLight.verb, size: 20),
            )),
          ]),
        ),
      ),
    );
  }
}
