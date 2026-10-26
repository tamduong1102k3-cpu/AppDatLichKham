import 'package:flutter_test/flutter_test.dart';

import 'package:datlichkham/main.dart';
import 'package:datlichkham/screens/main_screen.dart';

void main() {
  testWidgets('renders the appointment app', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MainScreen), findsOneWidget);
  });
}
