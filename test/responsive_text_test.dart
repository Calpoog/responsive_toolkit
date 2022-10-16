import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:responsive_toolkit/responsive_toolkit.dart';

void main() {
  group('FluidText', () {
    testGoldens('spans match goldens', (WidgetTester tester) async {
      final builder = GoldenBuilder.column();

      final text = FluidText(
        'Test',
        minWidth: 200,
        maxWidth: 500,
        minFontSize: 10,
        maxFontSize: 30,
      );

      builder.addScenario('100 (below minWidth)', wrap(text, 100));
      builder.addScenario('200 (at minWidth)', wrap(text, 200));
      builder.addScenario('300 (in range)', wrap(text, 300));
      builder.addScenario('400 (in range)', wrap(text, 400));
      builder.addScenario('500 (at maxWidth)', wrap(text, 500));
      builder.addScenario('600 (above maxWidth)', wrap(text, 600));

      await tester.pumpWidgetBuilder(
        builder.build(),
        surfaceSize: Size(200, 6 * 70),
      );

      await screenMatchesGolden(tester, 'responsive_text_fluid_text');
    });
  });
}

Widget wrap(Widget widget, double width) {
  return MediaQuery(
    child: widget,
    data: MediaQueryData(size: Size(width, 70)),
  );
}
