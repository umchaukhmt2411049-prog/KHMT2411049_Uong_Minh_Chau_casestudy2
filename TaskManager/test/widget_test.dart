import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/main.dart';

void main() {
  testWidgets('Task Manager displays login screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TaskManagerApp());

    expect(find.text('TASK MANAGER'), findsOneWidget);
    expect(
      find.text('Dang nhap de xem cong viec'),
      findsOneWidget,
    );
  });
}
