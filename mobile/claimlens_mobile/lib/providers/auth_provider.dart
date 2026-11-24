import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/push_service.dart';
import 'package:local_auth/local_auth.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this.client) : service = AuthService(client) {
    client.onSessionExpired = () {
      user = null;
      notifyListeners();
    };
  }
  final ApiClient client;
  final AuthService service;

  UserProfile? user;
  bool initialising = true;
  bool busy = false;
  String? error;

  bool get authenticated => user != null;
  bool locked = false;
  DateTime lastActivity = DateTime.now();
  void touch() {
    if (!locked) lastActivity = DateTime.now();
  }

  void lock() {
    if (user != null && !locked) {
      locked = true;
      notifyListeners();
    }
  }

  Future<void> unlock(String password) async {
    await client.dio
        .post<dynamic>('/profile/unlock', data: {'password': password});
    locked = false;
    lastActivity = DateTime.now();
    notifyListeners();
  }

  Future<bool> unlockWithDevice() async {
    final local = LocalAuthentication();
    if (!await local.isDeviceSupported()) {
      throw Exception(
          'Device authentication is unavailable. Use your password instead.');
    }
    if (!await local.authenticate(
        localizedReason: 'Unlock your ClaimLens workspace',
        persistAcrossBackgrounding: true)) {
      return false;
    }
    // Device authentication unlocks the local view. Server authorization and
    // active-account checks still run on every API request.
    await reloadProfile();
    locked = false;
    lastActivity = DateTime.now();
    notifyListeners();
    return true;
  }

  Future<void> reloadProfile({bool refreshToken = false}) async {
    if (refreshToken && !await client.refreshSession()) {
      throw Exception('Sign in again to refresh your session.');
    }
    user = await service.profile();
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> values) async {
    final response =
        await client.dio.put<Map<String, dynamic>>('/profile', data: values);
    user = UserProfile.fromJson(response.data!);
    notifyListeners();
  }

  Future<void> changePassword(String current, String password) async {
    final response = await client.dio.post<Map<String, dynamic>>(
        '/profile/password',
        data: {'current_password': current, 'new_password': password});
    final data = response.data!;
    await client.saveSession(
        data['access_token'] as String, data['refresh_token'] as String);
    user = await service.profile();
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  Future<void> initialise() async {
    await client.initialise();
    if (client.hasSession) {
      try {
        user = await service.profile();
        locked = user?.isClient == false;
      } catch (_) {
        await client.clearSession();
      }
    }
    initialising = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await service.login(email, password);
      locked = false;
      lastActivity = DateTime.now();
      return true;
    } catch (exception) {
      error = readableApiError(exception);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    busy = true;
    notifyListeners();
    try {
      await PushService.unregister(client);
      await service.logout();
    } catch (_) {/* Local sign-out must work without a connection. */} finally {
      user = null;
      locked = false;
      busy = false;
      notifyListeners();
    }
  }

  Future<void> changeServer(String value) async {
    await client.configureServer(value);
    user = null;
    locked = false;
    error = null;
    notifyListeners();
  }
}
