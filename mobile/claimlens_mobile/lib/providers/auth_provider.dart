import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

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
    await service.logout();
    user = null;
    busy = false;
    notifyListeners();
  }
}
