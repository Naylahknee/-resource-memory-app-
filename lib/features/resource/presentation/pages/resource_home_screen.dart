import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskee/app/routing/app_route.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class ResourceHomeScreen extends StatelessWidget {
  const ResourceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/${Routes.saveResourceScreen}'),
        child: const Icon(Icons.add),
      ),
      body: AppGradient(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Remember what helps.', style: AppTypography.h2),
                const SizedBox(height: 8),
                Text(
                  'Save useful coding resources and bring them back when a project needs them.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.kBorderColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _NavPill(label: 'NOW', selected: true, onTap: () {})),
                      Expanded(child: _NavPill(label: 'LIBRARY', onTap: () => context.go('/${Routes.libraryScreen}'))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _ActionCard(
                  icon: Icons.auto_awesome,
                  title: 'What are you working on?',
                  body: 'Describe the project. We’ll surface things you already saved that may help.',
                  action: 'Find useful resources',
                  onTap: () => context.go('/${Routes.projectMatchScreen}'),
                ),
                const SizedBox(height: 16),
                _ActionCard(
                  icon: Icons.add_link,
                  title: 'Save something useful',
                  body: 'Threads, YouTube, GitHub, websites, screenshots — save it with context.',
                  action: 'Save a resource',
                  onTap: () => context.go('/${Routes.saveResourceScreen}'),
                ),
                const Spacer(),
                Text(
                  'Save it once. Find it when it matters.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavPill({required this.label, required this.onTap, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.kTabGreyColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.labelLg.copyWith(
            fontSize: 13.5,
            color: selected ? Colors.white : Colors.white38,
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.body, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accentMuted,
            child: Icon(icon, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.h3),
          const SizedBox(height: 8),
          Text(body, style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward),
            label: Text(action),
          ),
        ],
      ),
    );
  }
}
