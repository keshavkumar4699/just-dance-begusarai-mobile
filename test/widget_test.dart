import 'package:flutter_test/flutter_test.dart';
import 'package:studio_crow/app/app.dart';

void main() {
  testWidgets('StudioCrowApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StudioCrowApp());
    expect(find.byType(StudioCrowApp), findsOneWidget);
  });
}
