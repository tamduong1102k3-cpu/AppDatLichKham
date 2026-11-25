import 'package:datlichkham/widgets/zoomable_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('viewer zoom controls and page swipes reset per image', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ZoomableImageViewer(
          images: const [
            'https://example.test/first.png',
            'https://example.test/second.png',
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('1.0x'), findsOneWidget);

    await tester.tap(find.byTooltip('Phóng to'));
    await tester.pump();
    expect(find.text('1.5x'), findsOneWidget);

    await tester.tap(find.byTooltip('Đặt lại'));
    await tester.pump();
    expect(find.text('1.0x'), findsOneWidget);

    final pageViewCenter = tester.getCenter(find.byType(PageView));
    await tester.tapAt(pageViewCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(pageViewCenter);
    await tester.pumpAndSettle();
    expect(find.text('2.5x'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Đặt lại'));
    await tester.pump();
    expect(find.text('1.0x'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('1.0x'), findsOneWidget);
  });
}
