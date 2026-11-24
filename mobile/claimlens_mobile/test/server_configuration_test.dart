import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claimlens/config/api_config.dart';
import 'package:claimlens/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new build replaces old API and clears sessions for that server',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      'server_url': 'http://127.0.0.1:9999/api/v1',
      'build_server_url': 'http://127.0.0.1:9999/api/v1',
      'access_token': 'test-access',
      'refresh_token': 'test-refresh',
    });
    final api = ApiClient();
    await api.initialise();
    expect(api.dio.options.baseUrl, ApiConfig.baseUrl);
    expect(api.hasSession, isFalse);
  });

  test('same build keeps an explicitly saved server and its session', () async {
    const selected = 'https://example.org/api/v1';
    FlutterSecureStorage.setMockInitialValues({
      'server_url': selected,
      'build_server_url': ApiConfig.baseUrl,
      'access_token': 'test-access',
      'refresh_token': 'test-refresh',
    });
    final api = ApiClient();
    await api.initialise();
    expect(api.dio.options.baseUrl, selected);
    expect(api.hasSession, isTrue);
  });

  test('upgrade from unversioned settings uses the current build API',
      () async {
    FlutterSecureStorage.setMockInitialValues({
      'server_url': 'http://127.0.0.1:9999/api/v1',
    });
    final api = ApiClient();
    await api.initialise();
    expect(api.dio.options.baseUrl, ApiConfig.baseUrl);
    expect(await const FlutterSecureStorage().read(key: 'server_url'),
        ApiConfig.baseUrl);
  });
}
