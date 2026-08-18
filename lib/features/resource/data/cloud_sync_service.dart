import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskee/features/resource/domain/resource.dart';

class CloudSyncService {
  static const _apiUrl = String.fromEnvironment('RESOURCE_API_URL');
  static const _tokenKey = 'resource_memory_sync_token';
  static const _emailKey = 'resource_memory_sync_email';

  static String? _token;
  static String? _email;
  static bool _initialized = false;

  static bool get isConfigured => _apiUrl.isNotEmpty;
  static bool get isInitialized => _initialized;
  static bool get isSignedIn => _token?.isNotEmpty == true;
  static String? get currentEmail => _email;

  static Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _email = prefs.getString(_emailKey);
    _initialized = true;
  }

  static Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _authenticate('/auth/register', email, password);
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _authenticate('/auth/login', email, password);
  }

  static Future<void> _authenticate(
    String path,
    String email,
    String password,
  ) async {
    _requireConfigured();
    final response = await http.post(
      _uri(path),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(response);
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('Sync server did not return a session token.');
    }
    _token = token;
    _email = (data['email'] as String?) ?? email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, _email!);
  }

  static Future<void> signOut() async {
    if (isConfigured && isSignedIn) {
      try {
        await http.post(_uri('/auth/logout'), headers: _authHeaders());
      } catch (_) {}
    }
    _token = null;
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
  }

  static Future<void> push(Resource resource) async {
    if (!isSignedIn || !isConfigured) return;
    final response = await http.put(
      _uri('/resources/${Uri.encodeComponent(resource.id)}'),
      headers: _authHeaders(),
      body: jsonEncode({'data': resource.toMap()}),
    );
    _decode(response);
  }

  static Future<void> pushAll(Iterable<Resource> resources) async {
    if (!isSignedIn || !isConfigured || resources.isEmpty) return;
    final response = await http.post(
      _uri('/sync'),
      headers: _authHeaders(),
      body: jsonEncode({
        'resources': resources.map((resource) => resource.toMap()).toList(),
      }),
    );
    _decode(response);
  }

  static Future<void> remove(String id) async {
    if (!isSignedIn || !isConfigured) return;
    final response = await http.delete(
      _uri('/resources/${Uri.encodeComponent(id)}'),
      headers: _authHeaders(),
    );
    _decode(response);
  }

  static Future<List<Resource>> pullAll() async {
    if (!isSignedIn || !isConfigured) return const [];
    final response = await http.get(_uri('/resources'), headers: _authHeaders());
    final data = _decode(response);
    final rows = data['resources'] as List? ?? const [];
    return rows
        .map((row) => Resource.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  static Uri _uri(String path) {
    final base = _apiUrl.endsWith('/')
        ? _apiUrl.substring(0, _apiUrl.length - 1)
        : _apiUrl;
    return Uri.parse('$base$path');
  }

  static Map<String, String> _jsonHeaders() => const {
        'content-type': 'application/json',
        'accept': 'application/json',
      };

  static Map<String, String> _authHeaders() => {
        ..._jsonHeaders(),
        if (_token != null) 'authorization': 'Bearer $_token',
      };

  static Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data = const {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) data = Map<String, dynamic>.from(decoded);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        data['error']?.toString() ?? 'Sync request failed (${response.statusCode}).',
      );
    }
    return data;
  }

  static void _requireConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Cloud sync is not configured. Add RESOURCE_API_URL when building the app.',
      );
    }
  }
}
