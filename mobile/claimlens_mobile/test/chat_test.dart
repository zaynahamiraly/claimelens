import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:claimlens/models/user_profile.dart';
import 'package:claimlens/providers/auth_provider.dart';
import 'package:claimlens/screens/chat_screen.dart';
import 'package:claimlens/services/api_client.dart';

const conversation = {
  'id': 'test-thread',
  'client_id': 'client',
  'client_name': 'QA Client',
  'subject': 'Claim questions'
};
const staffMessage = {
  'id': 'msg-1',
  'sequence': 1,
  'sender_id': 'officer',
  'sender_name': 'QA Officer',
  'sender_role': 'claims_officer',
  'text': 'How can we help?',
  'sent_at': '2026-11-24T08:00:00Z'
};

Widget wrap(ApiClient api, Widget child, {String role = 'client'}) =>
    ChangeNotifierProvider(
      create: (_) => AuthProvider(api)
        ..user = UserProfile(
            id: 'client',
            displayName: 'QA Client',
            role: role,
            status: 'active'),
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets(
      'conversation confirms a message whose send acknowledgement was lost',
      (tester) async {
    final api = ApiClient();
    String? acceptedKey;
    var sends = 0;
    api.dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      if (r.method == 'POST' && r.path.endsWith('/messages')) {
        sends++;
        acceptedKey = r.data['client_message_id'] as String;
        h.reject(DioException(
            requestOptions: r, type: DioExceptionType.connectionError));
      } else if (r.path.endsWith('/read')) {
        h.resolve(Response(requestOptions: r, statusCode: 200, data: {}));
      } else {
        h.resolve(Response(requestOptions: r, statusCode: 200, data: {
          'conversation': conversation,
          'messages': [
            if (acceptedKey != null)
              {
                'id': 'accepted',
                'sequence': 1,
                'sender_id': 'client',
                'sender_name': 'QA Client',
                'sender_role': 'client',
                'client_message_id': acceptedKey,
                'text': 'Was my receipt received?',
                'sent_at': '2026-11-24T08:01:00Z',
              }
          ],
          'has_more': false,
        }));
      }
    }));
    await tester.pumpWidget(
        wrap(api, const ChatThreadScreen(conversation: conversation)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Was my receipt received?');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isNotEmpty);
    await tester.tap(find.text('Retry messages'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    expect(find.text('Was my receipt received?'), findsOneWidget);
    expect(sends, 1);
    expect(find.textContaining('Your message is kept below'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('finance does not receive unrestricted client support access', () {
    expect(canUseChat('finance'), isFalse);
    for (final role in [
      'client',
      'administrator',
      'claims_officer',
      'supervisor'
    ]) {
      expect(canUseChat(role), isTrue);
    }
  });

  testWidgets('client starts support conversation from the empty inbox',
      (tester) async {
    final api = ApiClient();
    var creates = 0;
    api.dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      dynamic data;
      if (r.method == 'POST' && r.path == '/chat/conversations') {
        creates++;
        data = conversation;
      } else if (r.path.endsWith('/messages')) {
        data = {
          'conversation': conversation,
          'messages': [],
          'has_more': false
        };
      } else {
        data = {'conversations': [], 'next_before': null};
      }
      h.resolve(Response(requestOptions: r, statusCode: 200, data: data));
    }));
    await tester.pumpWidget(wrap(api, const ChatInboxScreen()));
    await tester.pumpAndSettle();
    expect(
        find.text(
            'No messages yet. Start a conversation with your support team.'),
        findsOneWidget);
    await tester.tap(find.text('Ask a question'));
    await tester.pumpAndSettle();
    expect(creates, 1);
    expect(find.text('ClaimLens support'), findsOneWidget);
    expect(find.byTooltip('Send message'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'failed send keeps the draft and retry key; successful retry appears once',
      (tester) async {
    final api = ApiClient();
    final sends = <Map<String, dynamic>>[];
    var saved = false;
    final own = {
      'id': 'msg-2',
      'sequence': 2,
      'sender_id': 'client',
      'sender_name': 'QA Client',
      'sender_role': 'client',
      'text': 'Which receipt should I upload?',
      'sent_at': '2026-11-24T08:01:00Z'
    };
    final reads = <int>[];
    api.dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      if (r.method == 'POST' && r.path.endsWith('/messages')) {
        sends.add(Map<String, dynamic>.from(r.data as Map));
        if (sends.length == 1) {
          h.reject(DioException(
              requestOptions: r, type: DioExceptionType.connectionError));
          return;
        }
        saved = true;
        h.resolve(Response(requestOptions: r, statusCode: 201, data: own));
      } else if (r.path.endsWith('/read')) {
        reads.add(r.data['through_sequence'] as int);
        h.resolve(Response(requestOptions: r, statusCode: 200, data: {}));
      } else {
        final after = r.queryParameters['after'] as int? ?? 0;
        h.resolve(Response(requestOptions: r, statusCode: 200, data: {
          'conversation': conversation,
          'messages': [
            if (after < 1) staffMessage,
            if (saved && after < 2) own
          ],
          'has_more': false,
        }));
      }
    }));
    await tester.pumpWidget(
        wrap(api, const ChatThreadScreen(conversation: conversation)));
    await tester.pumpAndSettle();
    expect(find.textContaining('QA Officer'), findsOneWidget);
    expect(reads, contains(1));
    await tester.enterText(find.byType(TextField), own['text'] as String);
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your message is kept below'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        own['text']);
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(sends.length, 2);
    expect(sends[0]['client_message_id'], sends[1]['client_message_id']);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    expect(find.text(own['text'] as String), findsOneWidget);
    expect(reads, contains(2));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('chat bubbles and composer fit narrow screens with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final api = ApiClient();
    api.dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      h.resolve(Response(
          requestOptions: r,
          statusCode: 200,
          data: r.path.endsWith('/read')
              ? {}
              : {
                  'conversation': conversation,
                  'messages': [staffMessage],
                  'has_more': false,
                }));
    }));
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AuthProvider(api)
        ..user = const UserProfile(
            id: 'client',
            displayName: 'QA Client',
            role: 'client',
            status: 'active'),
      child: MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!),
          home: const ChatThreadScreen(conversation: conversation)),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getBottomLeft(find.byTooltip('Send message')).dy,
        lessThanOrEqualTo(752));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
