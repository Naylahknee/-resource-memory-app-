import 'package:flutter/material.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/resource/data/resource_store.dart';
import 'package:taskee/features/resource/domain/resource.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class ProjectMatchScreen extends StatefulWidget {
  const ProjectMatchScreen({super.key});

  @override
  State<ProjectMatchScreen> createState() => _ProjectMatchScreenState();
}

class _ProjectMatchScreenState extends State<ProjectMatchScreen> {
  final TextEditingController _projectController = TextEditingController();
  List<Resource> _matches = const [];
  bool _searched = false;

  void _findMatches() {
    final query = _projectController.text.trim().toLowerCase();
    if (query.isEmpty) return;
    final terms = query.split(RegExp(r'\s+')).where((term) => term.length > 2).toSet();
    final ranked = ResourceStore.getAll().map((resource) {
      final score = terms.where((term) => resource.searchableText.contains(term)).length;
      return (resource: resource, score: score);
    }).where((item) => item.score > 0).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    setState(() {
      _searched = true;
      _matches = ranked.map((item) => item.resource).toList();
    });
  }

  @override
  void dispose() {
    _projectController.dispose();
    super.dispose();
  }

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
                  Text('Start a project', style: AppTypography.h3),
                ]),
                const SizedBox(height: 20),
                Text('What are you building?', style: AppTypography.h2),
                const SizedBox(height: 8),
                Text('Describe it normally. We’ll look through what you already saved.', style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 18),
                TextField(
                  controller: _projectController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'I’m building a Roblox inventory system in Luau.',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.kBorderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.kBorderColor)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _findMatches,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Find what I already saved'),
                  ),
                ),
                const SizedBox(height: 24),
                if (_searched)
                  Text(_matches.isEmpty ? 'No matches yet' : 'You already saved ${_matches.length} thing${_matches.length == 1 ? '' : 's'} that may help', style: AppTypography.h3),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _matches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final resource = _matches[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.kBorderColor)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(resource.title, style: AppTypography.h3),
                            const SizedBox(height: 5),
                            Text(resource.summary, style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            Text('Use when: ${resource.useWhen}', style: AppTypography.bodySm.copyWith(color: AppColors.accent)),
                          ],
                        ),
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
