import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/resource/data/cloud_sync_service.dart';
import 'package:taskee/features/resource/data/resource_store.dart';
import 'package:taskee/features/resource/domain/resource.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class ResourceDetailScreen extends StatefulWidget {
  const ResourceDetailScreen({super.key, required this.resourceId});

  final String resourceId;

  @override
  State<ResourceDetailScreen> createState() => _ResourceDetailScreenState();
}

class _ResourceDetailScreenState extends State<ResourceDetailScreen> {
  late final TextEditingController _title;
  late final TextEditingController _creator;
  late final TextEditingController _summary;
  late final TextEditingController _whyUseful;
  late final TextEditingController _useWhen;
  late final TextEditingController _topics;
  late final TextEditingController _technologies;
  Resource? _resource;
  Uint8List? _assetBytes;
  bool _assetLoading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _resource = ResourceStore.getById(widget.resourceId);
    final resource = _resource;
    _title = TextEditingController(text: resource?.title ?? '');
    _creator = TextEditingController(text: resource?.creator ?? '');
    _summary = TextEditingController(text: resource?.summary ?? '');
    _whyUseful = TextEditingController(text: resource?.whyUseful ?? '');
    _useWhen = TextEditingController(text: resource?.useWhen ?? '');
    _topics = TextEditingController(text: resource?.topics.join(', ') ?? '');
    _technologies = TextEditingController(text: resource?.technologies.join(', ') ?? '');
    if (resource?.assetPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAsset());
    }
  }

  Future<void> _loadAsset() async {
    final path = _resource?.assetPath;
    if (path == null || path.isEmpty || _assetLoading) return;
    setState(() => _assetLoading = true);
    try {
      final bytes = await CloudSyncService.fetchAsset(path);
      if (!mounted || bytes == null) return;
      setState(() => _assetBytes = Uint8List.fromList(bytes));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load the synced file.')),
      );
    } finally {
      if (mounted) setState(() => _assetLoading = false);
    }
  }

  List<String> _split(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList();

  Future<void> _save() async {
    final resource = _resource;
    if (resource == null || _saving) return;
    setState(() => _saving = true);
    final updated = resource.copyWith(
      title: _title.text.trim().isEmpty ? resource.title : _title.text.trim(),
      creator: _creator.text.trim(),
      summary: _summary.text.trim(),
      whyUseful: _whyUseful.text.trim(),
      useWhen: _useWhen.text.trim(),
      topics: _split(_topics.text),
      technologies: _split(_technologies.text),
    );
    await ResourceStore.save(updated);
    if (!mounted) return;
    setState(() {
      _resource = updated;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resource updated.')),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _creator.dispose();
    _summary.dispose();
    _whyUseful.dispose();
    _useWhen.dispose();
    _topics.dispose();
    _technologies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resource = _resource;
    if (resource == null) {
      return const Scaffold(body: Center(child: Text('Resource not found.')));
    }
    return Scaffold(
      body: AppGradient(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 4),
                      Text('Resource details', style: AppTypography.h3),
                    ]),
                    if (resource.assetPath != null) ...[
                      const SizedBox(height: 20),
                      _SyncedAssetCard(
                        resource: resource,
                        bytes: _assetBytes,
                        loading: _assetLoading,
                        onLoad: _loadAsset,
                      ),
                    ],
                    const SizedBox(height: 20),
                    _field('Title', _title),
                    _field('Creator', _creator),
                    _field('Summary', _summary, lines: 4),
                    _field('Why this is useful', _whyUseful, lines: 3),
                    _field('Use when', _useWhen, lines: 3),
                    _field('Topics', _topics, hint: 'MVP, UI, Roblox'),
                    _field('Technologies', _technologies, hint: 'Flutter, Luau, Next.js'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Saving…' : 'Save changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {int lines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelLg),
          const SizedBox(height: 7),
          TextField(
            controller: controller,
            maxLines: lines,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.kBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.kBorderColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncedAssetCard extends StatelessWidget {
  const _SyncedAssetCard({
    required this.resource,
    required this.bytes,
    required this.loading,
    required this.onLoad,
  });

  final Resource resource;
  final Uint8List? bytes;
  final bool loading;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    final isImage = resource.type == ResourceType.screenshot;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.cloud_done_outlined, color: AppColors.accent),
            const SizedBox(width: 8),
            Text('Synced file', style: AppTypography.h3),
          ]),
          const SizedBox(height: 12),
          if (bytes != null && isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(bytes!, fit: BoxFit.contain),
            )
          else if (bytes != null)
            Text(
              'File loaded from your synced library (${(bytes!.length / 1024).toStringAsFixed(1)} KB).',
              style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: loading ? null : onLoad,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download_outlined),
                label: Text(loading ? 'Loading…' : 'Load synced file'),
              ),
            ),
        ],
      ),
    );
  }
}
