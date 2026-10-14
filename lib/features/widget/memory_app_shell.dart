import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'memory_capture_sheet.dart';
import 'todoist_light.dart';

class MemoryAppShell extends StatelessWidget {
  const MemoryAppShell({super.key, required this.navigation});
  final StatefulNavigationShell navigation;
  static const labels = ['Now', 'Focus', 'Reminders', 'Memory'];
  static const icons = [Icons.home_outlined, Icons.center_focus_strong_outlined, Icons.notifications_none, Icons.bookmarks_outlined];
  void _select(int index) => navigation.goBranch(index, initialLocation: index == navigation.currentIndex);

  @override
  Widget build(BuildContext context) {
    return TodoistLightScope(
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          backgroundColor: TodoistLight.canvas,
          body: Row(children: [
            if (wide)
              SafeArea(
                child: SizedBox(
                  width: 210,
                  child: Column(children: [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('NanyNany', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FilledButton.icon(
                        onPressed: () => showMemoryCapture(context),
                        icon: const Icon(Icons.add), label: const Text('Save something'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: NavigationRail(
                        extended: true, minExtendedWidth: 210,
                        backgroundColor: TodoistLight.canvas,
                        selectedIndex: navigation.currentIndex, onDestinationSelected: _select,
                        indicatorColor: TodoistLight.verbTint,
                        selectedIconTheme: const IconThemeData(color: TodoistLight.verb),
                        selectedLabelTextStyle: const TextStyle(color: TodoistLight.verb, fontWeight: FontWeight.w600),
                        destinations: List.generate(4, (i) => NavigationRailDestination(
                          icon: Icon(icons[i]), label: Text(labels[i]),
                        )),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/sync'),
                      icon: const Icon(Icons.cloud_sync_outlined), label: const Text('Sync devices'),
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            if (wide) const VerticalDivider(width: 1),
            Expanded(child: navigation),
          ]),
          bottomNavigationBar: wide ? null : NavigationBar(
            backgroundColor: TodoistLight.canvas, indicatorColor: TodoistLight.verbTint,
            selectedIndex: navigation.currentIndex, onDestinationSelected: _select,
            destinations: List.generate(4, (i) => NavigationDestination(
              icon: Icon(icons[i]), selectedIcon: Icon(icons[i], color: TodoistLight.verb), label: labels[i],
            )),
          ),
        );
      }),
    );
  }
}
