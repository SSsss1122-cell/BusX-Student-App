import 'package:flutter_test/flutter_test.dart';

import 'package:student_app_sgi/main.dart';

void main() {
  testWidgets('BusX app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentBusApp());

    expect(find.text('BusX'), findsNothing);
  });
}