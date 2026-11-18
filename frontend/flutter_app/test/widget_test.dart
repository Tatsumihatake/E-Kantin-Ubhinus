import 'package:e_kantin/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shows login page when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EKantinApp()));
    await tester.pump();

    expect(find.text('E-Kantin'), findsWidgets);
    expect(find.text('Masuk ke akun'), findsOneWidget);
  });

  testWidgets('can open register page from login', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EKantinApp()));
    await tester.pump();

    await tester.tap(find.byKey(const Key('login_to_register')));
    await tester.pumpAndSettle();

    expect(find.text('Daftar akun baru'), findsOneWidget);
    expect(find.byKey(const Key('register_submit')), findsOneWidget);
  });
}
