import 'package:flutter_test/flutter_test.dart';

import 'package:insyte_mobile/app/app.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const VesperApp());
  });
}
