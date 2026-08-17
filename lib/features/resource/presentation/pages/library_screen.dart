import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/resource/data/resource_store.dart';
import 'package:taskee/features/resource/domain/resource.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradient(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
                  const SizedBox(width: 4),
                  Text('Library', style: AppTypography.h3),
                ]),
                const SizedBox(height: 20),
                Text('Your saved resources', style: AppTypography.h2),
                const SizedBox(height: 6),
                Text('What you save here can come back when your work needs it.', style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                Expanded(
                  child: ValueListenableBuilder<Box<Map>>(
                    valueListenable: ResourceStore.box.listenable(),
                    builder: (context, _, __) {
                      final resources = ResourceStore.getAll();
                      if (resources.isEmpty) {
                        return Center(child: Text('Nothing saved yet.', style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)));
                      }
                      return ListView.separated(
                        itemCount: resources.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _ResourceCard(resource: resources[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource});
  final Resource resource;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.kBorderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accentMuted,
            child: Icon(_iconFor(resource.type), color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resource.title, style: AppTypography.h3),
                const SizedBox(height: 5),
                Text(resource.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Text('Use when: ${resource.useWhen}', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ResourceType type) {
    switch (type) {
      case ResourceType.github:
        return Icons.code;
      case ResourceType.video:
        return Icons.play_arrow;
      case ResourceType.screenshot:
        return Icons.image_outlined;
      default:
        return Icons.link;
    }
  }
}
