import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:taskee/features/resource/data/resource_enrichment_service.dart';
import 'package:taskee/features/resource/data/resource_store.dart';
import 'package:taskee/features/resource/domain/resource.dart';

class IncomingShareService {
  static Future<int> saveSharedItems(List<SharedMediaFile> items) async {
    var saved = 0;
    for (final item in items) {
      if (await _saveItem(item)) saved++;
    }
    return saved;
  }

  static Future<bool> _saveItem(SharedMediaFile item) async {
    switch (item.type) {
      case SharedMediaType.url:
      case SharedMediaType.text:
        return _saveTextOrUrl(item.path, item.message);
      case SharedMediaType.image:
        return _saveImage(item);
      case SharedMediaType.video:
      case SharedMediaType.file:
        return _saveFile(item);
    }
  }

  static Future<bool> _saveTextOrUrl(String raw, String? message) async {
    final text = [raw, message].whereType<String>().join(' ').trim();
    if (text.isEmpty) return false;

    final url = _firstUrl(text);
    if (url != null) {
      if (_alreadySaved(url)) return false;
      final draft = await ResourceEnrichmentService.enrich(url);
      final now = DateTime.now();
      await ResourceStore.save(
        Resource(
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
        ),
      );
      return true;
    }

    final now = DateTime.now();
    await ResourceStore.save(
      Resource(
        id: now.microsecondsSinceEpoch.toString(),
        title: _titleFromText(text),
        platform: 'Shared text',
        summary: text,
        whyUseful: 'You shared this because it contained an idea, explanation, or reference worth keeping.',
        useWhen: 'Resurface when a project or learning goal overlaps with this note.',
        type: ResourceType.article,
        topics: const ['shared text'],
        savedAt: now,
      ),
    );
    return true;
  }

  static Future<bool> _saveImage(SharedMediaFile item) async {
    final now = DateTime.now();
    final name = _fileName(item.path, fallback: 'Shared screenshot');
    await ResourceStore.save(
      Resource(
        id: now.microsecondsSinceEpoch.toString(),
        title: name,
        platform: 'Shared image',
        thumbnail: item.path,
        summary: item.message?.trim().isNotEmpty == true
            ? item.message!.trim()
            : 'An image or screenshot shared into Resource Memory.',
        whyUseful: 'Useful as a visual reference you wanted Future You to keep.',
        useWhen: 'Resurface when the current project overlaps with the subject of this image.',
        type: ResourceType.screenshot,
        topics: const ['screenshot', 'visual reference'],
        savedAt: now,
      ),
    );
    return true;
  }

  static Future<bool> _saveFile(SharedMediaFile item) async {
    final now = DateTime.now();
    await ResourceStore.save(
      Resource(
        id: now.microsecondsSinceEpoch.toString(),
        title: _fileName(item.path, fallback: 'Shared file'),
        platform: 'Shared file',
        summary: 'A file shared into Resource Memory for future reference.',
        whyUseful: 'You chose to keep this file for a future learning or building context.',
        useWhen: 'Resurface when a project or learning goal overlaps with this file.',
        type: ResourceType.other,
        topics: const ['shared file'],
        savedAt: now,
      ),
    );
    return true;
  }

  static String? _firstUrl(String text) {
    final match = RegExp(r'https?://[^\s]+', caseSensitive: false).firstMatch(text);
    if (match == null) return null;
    return match.group(0)?.replaceAll(RegExp(r'[),.;]+$'), '');
  }

  static bool _alreadySaved(String url) {
    return ResourceStore.getAll().any((resource) => resource.url == url);
  }

  static String _titleFromText(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 70) return normalized;
    return '${normalized.substring(0, 67)}…';
  }

  static String _fileName(String path, {required String fallback}) {
    final segments = path.split(RegExp(r'[/\\]')).where((e) => e.isNotEmpty).toList();
    return segments.isEmpty ? fallback : segments.last;
  }
}
