import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskee/features/resource/domain/resource.dart';

class CloudSyncService {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static bool _initialized = false;

  static bool get isConfigured => _url.isNotEmpty && _key.isNotEmpty;
  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (!isConfigured || _initialized) return;
    await Supabase.initialize(url: _url, anonKey: _key);
    _initialized = true;
  }

  static SupabaseClient? get _client =>
      _initialized ? Supabase.instance.client : null;

  static User? get currentUser => _client?.auth.currentUser;
  static bool get isSignedIn => currentUser != null;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    return client.auth.signUp(email: email, password: password);
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    await _client?.auth.signOut();
  }

  static Future<void> push(Resource resource) async {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null) return;

    await client.from('resources').upsert({
      'id': resource.id,
      'user_id': user.id,
      'data': resource.toMap(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,id');
  }

  static Future<void> pushAll(Iterable<Resource> resources) async {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null || resources.isEmpty) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final rows = resources
        .map((resource) => {
              'id': resource.id,
              'user_id': user.id,
              'data': resource.toMap(),
              'updated_at': now,
            })
        .toList();
    await client.from('resources').upsert(rows, onConflict: 'user_id,id');
  }

  static Future<void> remove(String id) async {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null) return;
    await client
        .from('resources')
        .delete()
        .eq('user_id', user.id)
        .eq('id', id);
  }

  static Future<List<Resource>> pullAll() async {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null) return const [];

    final rows = await client
        .from('resources')
        .select('data')
        .eq('user_id', user.id);

    return (rows as List)
        .map((row) => Resource.fromMap(
              Map<String, dynamic>.from(row['data'] as Map),
            ))
        .toList();
  }

  static SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError(
        'Cloud sync is not configured. Add SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
      );
    }
    return client;
  }
}
