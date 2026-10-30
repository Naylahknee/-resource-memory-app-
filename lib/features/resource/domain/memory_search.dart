import 'resource.dart';

class MemoryMatch {
  const MemoryMatch(this.resource, this.score, this.terms);
  final Resource resource;
  final int score;
  final List<String> terms;
  String get explanation => 'Matches ${terms.map((t) => '“$t”').join(', ')} in your saved memory.';
}

/// Local, explainable word matching. This is not an embedding/AI search.
/// Natural-language filler is ignored and common recall terms are normalized.
abstract final class MemorySearch {
  static const _stop = {
    'a', 'an', 'the', 'and', 'or', 'for', 'with', 'that', 'this', 'those',
    'about', 'from', 'into', 'of', 'to', 'in', 'on', 'at', 'is', 'was', 'are',
    'it', 'my', 'me', 'i', 'you', 'we', 'find', 'show', 'where', 'what',
    'did', 'do', 'have', 'has', 'had', 'can', 'please', 'saved', 'save',
    'remember', 'something', 'thing', 'need', 'want', 'looking', 'look', 'help',
  };
  static const _aliases = {
    'grants': 'funding', 'grant': 'funding', 'fund': 'funding',
    'funds': 'funding', 'financing': 'funding',
    'emails': 'message', 'email': 'message', 'messages': 'message',
    'reminders': 'reminder', 'photos': 'image', 'photo': 'image',
    'pictures': 'image', 'picture': 'image', 'images': 'image',
    'screenshots': 'screenshot', 'videos': 'video', 'articles': 'article',
    'appointments': 'appointment', 'meetings': 'meeting',
    'communities': 'community', 'resources': 'resource',
    'voice': 'audio', 'recording': 'audio', 'recordings': 'audio',
  };

  static Set<String> terms(String text) => text.toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}+#]+', unicode: true), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty && !_stop.contains(t))
      .map((t) => _aliases[t] ?? t)
      .toSet();

  static List<MemoryMatch> find(Iterable<Resource> resources, String query) {
    final wanted = terms(query);
    if (wanted.isEmpty) return [];
    final matches = <MemoryMatch>[];
    for (final resource in resources) {
      if (resource.status == ResourceStatus.archived) continue;
      final title = terms(resource.title);
      final metadata = terms([
        resource.platform, resource.creator, resource.type.name, resource.url,
        ...resource.topics, ...resource.technologies,
      ].whereType<String>().join(' '));
      final body = terms(resource.searchableText);
      final matched = wanted.where(body.union(metadata).contains).toList()..sort();
      if (matched.isEmpty) continue;
      var score = 0;
      for (final term in matched) {
        score += title.contains(term) ? 6 : metadata.contains(term) ? 3 : 1;
      }
      if (matched.length == wanted.length) score += 6;
      matches.add(MemoryMatch(resource, score, matched));
    }
    matches.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : b.resource.savedAt.compareTo(a.resource.savedAt);
    });
    return matches;
  }
}
