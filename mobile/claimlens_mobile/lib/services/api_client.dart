import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';

class ApiClient {
  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 120),
            headers: {'Accept': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _accessToken;
  String? _refreshToken;
  Future<bool>? _refreshOperation;
  void Function()? onSessionExpired;

  bool get hasSession => _accessToken != null && _refreshToken != null;
  Future<bool> refreshSession() => _refresh();

  Future<void> initialise() async {
    dio.options.baseUrl =
        await _storage.read(key: 'server_url') ?? ApiConfig.baseUrl;
    _accessToken = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
  }

  Future<void> saveSession(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await Future.wait([
      _storage.write(key: 'access_token', value: accessToken),
      _storage.write(key: 'refresh_token', value: refreshToken),
    ]);
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    await Future.wait([
      _storage.delete(key: 'access_token'),
      _storage.delete(key: 'refresh_token')
    ]);
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    if (error.response?.statusCode != 401 ||
        request.extra['retried'] == true ||
        _refreshToken == null ||
        request.path.contains('/auth/')) {
      handler.next(error);
      return;
    }
    _refreshOperation ??= _refresh();
    final refreshed = await _refreshOperation!;
    _refreshOperation = null;
    if (!refreshed) {
      handler.next(error);
      return;
    }
    request.headers['Authorization'] = 'Bearer $_accessToken';
    request.extra['retried'] = true;
    try {
      handler.resolve(await dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refresh() async {
    try {
      final response = await Dio(BaseOptions(baseUrl: dio.options.baseUrl))
          .post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': _refreshToken},
      );
      final data = response.data!;
      await saveSession(
        data['access_token'] as String,
        data['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      await clearSession();
      onSessionExpired?.call();
      return false;
    }
  }

  Future<void> configureServer(String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !['https', 'http'].contains(uri.scheme)) {
      throw Exception('Enter a valid server URL.');
    }
    final host = uri.host;
    final local = host == 'localhost' ||
        host == '127.0.0.1' ||
        host.startsWith('10.') ||
        host.startsWith('192.168.') ||
        RegExp(r'^172\.(1[6-9]|2[0-9]|3[01])\.').hasMatch(host);
    if (uri.scheme != 'https' && !(kDebugMode && local)) {
      throw Exception('Internet connections must use HTTPS.');
    }
    final base = uri.replace(path: '/api/v1').toString();
    final health = await Dio().get<Map<String, dynamic>>('$base/health',
        options: Options(receiveTimeout: const Duration(seconds: 15)));
    if (!['ClaimLens API', 'claimelens API']
        .contains(health.data?['service'])) {
      throw Exception('This address is not a ClaimLens server.');
    }
    await clearSession();
    await _storage.write(key: 'server_url', value: base);
    dio.options.baseUrl = base;
  }
}

String readableApiError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is List) {
        return detail
            .whereType<Map>()
            .map(
                (entry) => entry['msg']?.toString() ?? 'Check the form fields.')
            .join('\n');
      }
      return detail.toString();
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Cannot reach the ClaimLens server. Check the API address and your connection.';
    }
    return error.message ?? 'The request could not be completed.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}
