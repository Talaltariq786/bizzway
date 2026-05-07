import 'package:flutter_test/flutter_test.dart';
import 'package:bizlabel_pro/app.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BizLabelApp());
    // Let post-frame + short splash delays settle so the test framework
    // doesn't fail on pending timers when disposing the widget tree.
    await tester.pump(const Duration(seconds: 2));
    // Avoid pumpAndSettle here: app has ongoing animations/routes that can
    // keep scheduling frames and cause a timeout in a smoke test.
    await tester.pump(const Duration(seconds: 1));
  });
}
