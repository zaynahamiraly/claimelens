import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claimlens/config/api_config.dart';
import 'package:claimlens/providers/auth_provider.dart';
import 'package:claimlens/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('offline startup retains saved session and retries without a password',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      'server_url': ApiConfig.baseUrl,
      'build_server_url': ApiConfig.baseUrl,
      'access_token': 'test-access',
      'refresh_token': 'test-refresh',
    });
    final api = ApiClient();
    var online = false;
    api.dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      if (!online) {
        handler.reject(DioException(
            requestOptions: request, type: DioExceptionType.connectionError));
      } else {
        handler
            .resolve(Response(requestOptions: request, statusCode: 200, data: {
          'id': 'qa',
          'display_name': 'QA Client',
          'role': 'client',
          'status': 'active',
        }));
      }
    }));
    final auth = AuthProvider(api);
    await auth.initialise();
    expect(auth.authenticated, isFalse);
    expect(api.hasSession, isTrue);
    expect(auth.error, contains('Cannot reach'));
    online = true;
    await auth.initialise();
    expect(auth.authenticated, isTrue);
    expect(auth.user!.displayName, 'QA Client');
    expect(auth.error, isNull);
  });
}
