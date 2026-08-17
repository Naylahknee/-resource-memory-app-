import 'package:flutter/material.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/resource/data/resource_store.dart';
import 'package:taskee/features/resource/domain/resource.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class SaveResourceScreen extends StatefulWidget {
  const SaveResourceScreen({super.key});

  @override
  State<SaveResourceScreen> createState() => _SaveResourceScreenState();
}

class _SaveResourceScreenState extends State<SaveResourceScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _saving = true);
    final uri = Uri.tryParse(url);
    final host = uri?.host.replaceFirst('www.', '') ?? 'Saved link';
    final resource = Resource(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: host.isEmpty ? 'Saved link' : host,
      url: url,
      platform: host,
      summary: 'Saved from $host. AI understanding will enrich this resource next.',
      whyUseful: 'You saved this because it looked useful for future work.',
      useWhen: 'Surface this when a project or search matches this resource.',
      savedAt: DateTime.now(),
      type: url.contains('github.com')
          ? ResourceType.github
          : url.contains('youtube.com') || url.contains('youtu.be')
              ? ResourceType.video
              : ResourceType.website,
    );

    await ResourceStore.save(resource);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to your library.')),
    );
    _urlController.clear();
  }

  @override
  void dispose() {
    _urlController.dispose();
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
                  Text('Save something useful', style: AppTypography.h3),
                ]),
                const SizedBox(height: 24),
                Text('Paste a link', style: AppTypography.h2),
                const SizedBox(height: 8),
                Text('Threads, YouTube, GitHub, websites, tutorials — anything Future You should remember.', style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 22),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    filled: true,
                    fillColor: AppColors.surface,
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: AppColors.kBorderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: AppColors.kBorderColor)),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(_saving ? 'Saving...' : 'Understand and save'),
                  ),
                ),
                const SizedBox(height: 28),
                Row(children: [Expanded(child: Divider(color: AppColors.kBorderColor)), const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR')), Expanded(child: Divider(color: AppColors.kBorderColor))]),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.kBorderColor)),
                  child: Column(children: [
                    CircleAvatar(backgroundColor: AppColors.accentMuted, child: const Icon(Icons.image_outlined, color: AppColors.accent)),
                    const SizedBox(height: 12),
                    Text('Upload a screenshot', style: AppTypography.h3),
                    const SizedBox(height: 6),
                    Text('Screenshot import is next.', textAlign: TextAlign.center, style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
