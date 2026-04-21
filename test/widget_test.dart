import 'package:flutter_test/flutter_test.dart';
import 'package:urbaos_gestor/main.dart';

void main() {
  testWidgets('UrbaOS Admin inicializa corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(const UrbaOSAdminApp());
    // Verificar que a aplicação foi inicializada

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
