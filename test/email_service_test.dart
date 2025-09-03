import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:untitled1/services/email_service.dart';
import 'email_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('EmailService', () {
    testWidgets('sendAnalysisToEmail returns true on successful request', (WidgetTester tester) async {
      final client = MockClient();

      when(client.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{}', 200));

      // Widget to provide valid context
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return TextButton(
                  onPressed: () {
                    EmailService.sendAnalysisToEmail(
                      context: context,
                      userName: 'Test User',
                      userEmail: 'test@example.com',
                      analysisResult: 'Sample analysis',
                      isEnglish: true,
                      client: client, // Pass mock client
                    );
                  },
                  child: const Text('Send Email'),
                );
              },
            ),
          ),
        ),
      );

      // Tap the button to call the function
      await tester.tap(find.text('Send Email'));
      await tester.pump(); // Start async ops
      await tester.pump(const Duration(seconds: 1)); // Allow SnackBar to appear

      // Verify result
      expect(find.text("Email sent successfully"), findsOneWidget);
    });
  });
}
