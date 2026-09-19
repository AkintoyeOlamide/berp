import 'package:flutter_test/flutter_test.dart';

import 'package:vmo_staff/app.dart';
import 'package:vmo_staff/core/settings/app_settings.dart';

void main() {
  testWidgets('Bitachon splash shows branding', (tester) async {
    await tester.pumpWidget(VmoStaffApp(settings: AppSettings()));
    await tester.pump();

    expect(find.textContaining('BITACHON'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('BITACHON'), findsWidgets);
  });
}
