import 'package:flutter_test/flutter_test.dart';
import 'package:resource_memory/features/resource/domain/memory_search.dart';
import 'package:resource_memory/features/resource/domain/resource.dart';

Resource memory(String id, String title, {String summary = '', List<String> topics = const [], String? platform, String? url, ResourceStatus status = ResourceStatus.saved}) => Resource(
  id: id, title: title, summary: summary, whyUseful: '', useWhen: '',
  topics: topics, platform: platform, url: url, status: status, savedAt: DateTime.utc(2026, 10, 14));

void main() {
  test('recalls grants as funding while ignoring conversational filler', () {
    final result = MemorySearch.find([memory('1', 'Community funding guide', topics: ['community', 'funding'])], 'find that article about grants I saved');
    expect(result.single.resource.id, '1');
    expect(result.single.terms, contains('funding'));
  });
  test('ranks title matches ahead of incidental mentions', () {
    final result = MemorySearch.find([
      memory('incidental', 'Work notes', summary: 'We also talked about community funding.'),
      memory('title', 'Community funding guide'),
    ], 'community funding');
    expect(result.first.resource.id, 'title');
  });
  test('matches complete words rather than arbitrary substrings', () {
    expect(MemorySearch.find([memory('1', 'Startup checklist')], 'art'), isEmpty);
  });
  test('does not return everything for filler-only questions', () {
    expect(MemorySearch.find([memory('1', 'Notes')], 'what did I save'), isEmpty);
  });
  test('retains source and URL as recall cues', () {
    final result = MemorySearch.find([memory('1', 'A useful page', platform: 'YouTube', url: 'https://example.com/community')], 'youtube community');
    expect(result.single.terms, ['community', 'youtube']);
  });
  test('normalizes voice, image, and message recall terms', () {
    expect(MemorySearch.find([memory('voice', 'Voice memory')], 'audio').single.resource.id, 'voice');
    expect(MemorySearch.find([memory('photo', 'A photo')], 'picture').single.resource.id, 'photo');
    expect(MemorySearch.find([memory('email', 'School email')], 'messages').single.resource.id, 'email');
  });
  test('archived memories do not appear in suggestions', () {
    expect(MemorySearch.find([memory('1', 'Community guide', status: ResourceStatus.archived)], 'community'), isEmpty);
  });
}
