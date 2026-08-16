enum ResourceType {
  website,
  video,
  github,
  screenshot,
  article,
  tool,
  tutorial,
  code,
  other,
}

enum ResourceStatus {
  saved,
  seen,
  used,
  useful,
  archived,
}

class Resource {
  const Resource({
    required this.id,
    required this.title,
    required this.summary,
    required this.whyUseful,
    required this.useWhen,
    required this.savedAt,
    this.url,
    this.creator,
    this.platform,
    this.thumbnail,
    this.type = ResourceType.other,
    this.status = ResourceStatus.saved,
    this.topics = const [],
    this.technologies = const [],
    this.lastUsedAt,
  });

  final String id;
  final String title;
  final String? url;
  final String? creator;
  final String? platform;
  final String summary;
  final String whyUseful;
  final String useWhen;
  final String? thumbnail;
  final ResourceType type;
  final ResourceStatus status;
  final List<String> topics;
  final List<String> technologies;
  final DateTime savedAt;
  final DateTime? lastUsedAt;

  String get searchableText => [
        title,
        creator,
        platform,
        summary,
        whyUseful,
        useWhen,
        ...topics,
        ...technologies,
      ].whereType<String>().join(' ').toLowerCase();
}
