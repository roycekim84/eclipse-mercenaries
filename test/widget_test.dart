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

  testWidgets('contract flows into mercenary selection', (tester) async {
    await tester.pumpWidget(const EclipseMercenariesApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('전쟁터 출전'));
    await tester.pumpAndSettle();
    expect(find.text('전쟁 계약'), findsOneWidget);

    await tester.tap(find.text('계약 수락 · 출전'));
    await tester.pumpAndSettle();
    expect(find.text('출전 용병 선택'), findsOneWidget);
    expect(find.text('루나 벨하르트'), findsWidgets);
    expect(find.text('카일 로젠팽'), findsOneWidget);
    expect(find.text('세라 이나리온'), findsOneWidget);
  });

  testWidgets('equipment screen exposes alpha weapon set', (tester) async {
    await tester.pumpWidget(const EclipseMercenariesApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('장비'));
    await tester.pumpAndSettle();
    expect(find.text('장비 / 무기'), findsOneWidget);
    expect(find.text('월광쌍검'), findsWidgets);
    expect(find.text('혈아대검'), findsOneWidget);
    expect(find.text('유리불꽃 지팡이'), findsOneWidget);
  });
}
