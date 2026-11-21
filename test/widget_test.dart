
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketvault_mess_manager/main.dart';

void main() {
  testWidgets('MessMate login screen loads successfully',
          (WidgetTester tester) async {

        await tester.pumpWidget(const MessMateApp());

        expect(find.text('PocketVault Mess'), findsOneWidget);
        expect(find.text('Welcome Back!'), findsOneWidget);
        expect(find.text('Email Address'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
      });
}
