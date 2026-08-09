import 'package:eclipse_mercenaries/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('camp renders primary actions', (tester) async {
    await tester.pumpWidget(const EclipseMercenariesApp());
    await tester.pumpAndSettle();

    expect(find.text('전쟁터 출전'), findsOneWidget);
    expect(find.text('용병 모집'), findsOneWidget);
    expect(find.text('대장간'), findsOneWidget);
  });
}
