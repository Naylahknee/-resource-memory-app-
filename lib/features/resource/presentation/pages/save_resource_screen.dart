import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/resource/data/resource_enrichment_service.dart';
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
  final ImagePicker _picker = ImagePicker();
  bool _saving = false;

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || _saving) return;
    setState(() => _saving = true);

    try {
      final draft = await ResourceEnrichmentService.enrich(url);
      final now = DateTime.now();
      final resource = Resource(
        id: now.microsecondsSinceEpoch.toString(),
        title: draft.title,
        url: url,
        creator: draft.creator,
        platform: draft.platform,
        summary: draft.summary,
        whyUseful: draft.whyUseful,
        useWhen: draft.useWhen,
        thumbnail: draft.thumbnail,
        type: draft.type,
        topics: draft.topics,
        technologies: draft.technologies,
        savedAt: now,
      );
      await ResourceStore.save(resource);
      if (!mounted) return;
      _urlController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${resource.title}')),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save that resource. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveScreenshot() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final now = DateTime.now();
    final name = image.name.trim().isEmpty ? 'Screenshot' : image.name.trim();
    await ResourceStore.save(
      Resource(
        id: now.microsecondsSinceEpoch.toString(),
        title: name,
        platform: 'Screenshot',
        summary: 'A screenshot saved as a visual reference.',
        whyUseful: 'Useful because it captures an idea, tool, example, or explanation you wanted Future You to keep.',
        useWhen: 'Resurface when the current project overlaps with the subject of this screenshot.',
        type: ResourceType.screenshot,
        topics: const ['screenshot', 'visual reference'],
        savedAt: now,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved $name')),
    );
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Text('Save something useful', style: AppTypography.h3),
                ]),
                const SizedBox(height: 24),
                Text('Paste a link', style: AppTypography.h2),
                const SizedBox(height: 8),
                Text(
                  'Threads, YouTube, GitHub, websites, tutorials — anything Future You should remember.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveUrl(),
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    filled: true,
                    fillColor: AppColors.surface,
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.kBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.kBorderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveUrl,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_saving ? 'Understanding…' : 'Understand and save'),
                  ),
                ),
                const SizedBox(height: 28),
                Row(children: [
                  Expanded(child: Divider(color: AppColors.kBorderColor)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR'),
                  ),
                  Expanded(child: Divider(color: AppColors.kBorderColor)),
                ]),
                const SizedBox(height: 28),
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _saveScreenshot,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.kBorderColor),
                    ),
                    child: Column(children: [
                      CircleAvatar(
                        backgroundColor: AppColors.accentMuted,
                        child: const Icon(Icons.image_outlined, color: AppColors.accent),
                      ),
                      const SizedBox(height: 12),
                      Text('Upload a screenshot', style: AppTypography.h3),
                      const SizedBox(height: 6),
                      Text(
                        'Save visual references alongside your links.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                      ),
                    ]),
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
