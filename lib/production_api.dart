import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

typedef Record = Map<String, dynamic>;

class ProductionApi {
  ProductionApi();
  static final origin = Uri.parse('https://api.oyudent.com/landing/api/v1/');
  static const _key = 'oyudent.production.access';
  final _storage = const FlutterSecureStorage();
  String? _token;
  String? _owner;
  String? get localOwner => _owner;
  Future<void> _rememberOwner(Record profile) async {
    final id =
        profile['id'] ??
        profile['doctor_id'] ??
        profile['doctorId'] ??
        profile['username'] ??
        profile['phone'];
    if (id != null && id.toString().isNotEmpty) {
      _owner = 'doctor/$id';
      await _storage.write(key: '$_key.owner', value: _owner);
    }
  }

  bool get signedIn => _token != null;

  Future<Record> _request(
    String path, {
    Record? body,
    bool authenticated = false,
  }) async {
    final uri = origin.resolve(path);
    if (uri.origin != origin.origin || !uri.path.startsWith(origin.path)) {
      throw const ApiError('Холболтын хаяг буруу байна.');
    }
    final request = http.Request(body == null ? 'GET' : 'POST', uri)
      ..followRedirects = false
      ..headers['Accept'] = 'application/json';
    if (authenticated && _token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final client = http.Client();
    try {
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 401 && authenticated) await logout();
      if (response.statusCode == 401) {
        throw const ApiError('Нэвтрэх эрхээ шалгана уу.');
      }
      final result = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          (result is Record &&
              ['failed', 'error'].contains(result['status']))) {
        final errors = result is Record ? result['errors'] : null;
        final first = errors is List && errors.isNotEmpty ? errors.first : null;
        throw ApiError(
          first is String && first.isNotEmpty && response.statusCode < 500
              ? first
              : 'Серверээс мэдээлэл авч чадсангүй.',
        );
      }
      if (result is! Record || ['failed', 'error'].contains(result['status'])) {
        throw const ApiError('Хүсэлтийг боловсруулах боломжгүй байна.');
      }
      return result;
    } finally {
      client.close();
    }
  }

  Future<List<Record>> list(String path, {bool authenticated = false}) async {
    final response = await _request(path, authenticated: authenticated);
    final data = response['data'];
    final entries =
        response['items'] ?? (data is Record ? data['items'] : data);
    if (entries == null &&
        (response.containsKey('items') || response.containsKey('data'))) {
      return [];
    }
    if (entries is! List) throw const ApiError('Жагсаалт уншиж чадсангүй.');
    return entries.whereType<Record>().toList();
  }

  Future<Record> detail(String path, {bool authenticated = false}) async {
    final response = await _request(path, authenticated: authenticated);
    final data = response['data'];
    if (data == null && response['id'] is String) return response;
    if (data is! Record) throw const ApiError('Мэдээлэл уншиж чадсангүй.');
    return data;
  }

  Future<Record> submit(
    String path,
    Record body, {
    bool authenticated = true,
  }) async {
    final response = await _request(
      path,
      body: body,
      authenticated: authenticated,
    );
    final data = response['data'];
    return data is Record ? data : {};
  }

  Future<Record?> restore() async {
    _token = await _storage.read(key: _key);
    if (_token == null) return null;
    _owner = await _storage.read(key: '$_key.owner');
    final profile = await detail('doctor/info', authenticated: true);
    await _rememberOwner(profile);
    return profile;
  }

  Future<Record> login(String phone, String password) async {
    final response = await _request(
      'doctor/login',
      body: {'username': phone, 'password': password},
    );
    final token = response['data'];
    if (token is! String || token.isEmpty) {
      throw const ApiError('Утасны дугаар эсвэл нууц үгээ шалгана уу.');
    }
    _token = token;
    try {
      final profile = await detail('doctor/info', authenticated: true);
      await _rememberOwner(profile);
      await _storage.write(key: _key, value: token);
      return profile;
    } catch (_) {
      _token = null;
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _owner = null;
    await _storage.delete(key: '$_key.owner');
    await _storage.delete(key: _key);
  }
}

class ApiError implements Exception {
  const ApiError(this.message);
  final String message;
  @override
  String toString() => message;
}
