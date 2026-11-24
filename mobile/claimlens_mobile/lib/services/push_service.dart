import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_client.dart';

@pragma('vm:entry-point')
Future<void> claimLensBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  // OS notifications contain generic text. Medical details are fetched only
  // after the user opens the app and an authenticated API request succeeds.
}

class PushService {
  PushService(this.client);
  final ApiClient client;
  static String? _installationId;
  StreamSubscription<String>? refresh;
  StreamSubscription<RemoteMessage>? opened;
  Future<void> initialise({required void Function(String) onOpen}) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission();
      if (permission.authorizationStatus != AuthorizationStatus.authorized &&
          permission.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }
      refresh = messaging.onRegistered.listen((fid) async {
        _installationId = fid;
        try {
          await client.dio.post<dynamic>('/devices', data: {'token': fid});
        } catch (_) {}
      });
      await messaging.register();
      opened = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final reference = message.data['reference'];
        if (reference is String && reference.isNotEmpty) onOpen(reference);
      });
      final initial = await messaging.getInitialMessage();
      final reference = initial?.data['reference'];
      if (reference is String && reference.isNotEmpty) onOpen(reference);
    } catch (_) {/* In-app notifications work when OS push is unavailable. */}
  }

  Future<void> dispose() async {
    await refresh?.cancel();
    await opened?.cancel();
  }

  static Future<void> unregister(ApiClient client) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final token = _installationId;
      if (token != null) {
        await client.dio.delete<dynamic>('/devices', data: {'token': token});
      }
      await FirebaseMessaging.instance.unregister();
      _installationId = null;
    } catch (_) {}
  }
}
