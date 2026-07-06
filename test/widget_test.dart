import 'package:eticketing/providers/app_provider.dart';
import 'package:eticketing/screens/forgot_password_screen.dart';
import 'package:eticketing/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('tap lupa password opens forgot password screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.tap(find.text('Lupa Password?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(find.text('Kirim Link Reset'), findsOneWidget);
  });
}
