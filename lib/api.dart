import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class OyudentApi {
  static final instance = OyudentApi();
  static const base = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8087',
  );
  final storage = const FlutterSecureStorage();
  String? token;
  Map<String, dynamic>? user;
  Future<Map<String, dynamic>> request(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authenticated && token != null) 'Authorization': 'Bearer $token',
    };
    final uri = Uri.parse('$base$path');
    final response =
        await (body == null
                ? http.get(uri, headers: headers)
                : http.post(uri, headers: headers, body: jsonEncode(body)))
            .timeout(const Duration(seconds: 15));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 401 && authenticated) {
      await clear();
    }
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Серверийн алдаа');
    }
    return data;
  }

  Future<void> restore() async {
    token = await storage.read(key: 'oyudent.session.$base');
    if (token != null) {
      final result = await request('/auth/me');
      user = Map<String, dynamic>.from(result['user']);
    }
  }

  Future<void> authenticate(
    String email,
    String password, {
    String? name,
    Map<String, String>? registration,
  }) async {
    final result = await request(
      name == null ? '/auth/login' : '/auth/register',
      body: {
        'email': email,
        'password': password,
        'name': ?name,
        ...?registration,
      },
      authenticated: false,
    );
    final access = result['accessToken'] as String;
    await storage.write(key: 'oyudent.session.$base', value: access);
    token = access;
    user = Map<String, dynamic>.from(result['user']);
  }

  Future<void> clear() async {
    token = null;
    user = null;
    await storage.delete(key: 'oyudent.session.$base');
  }

  Future<void> logout() async {
    try {
      await request('/auth/logout', body: {});
    } finally {
      await clear();
    }
  }
}
