import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:responsive_toolkit/responsive_toolkit.dart';

void main() {
  group('FluidText', () {
    test('validates width and font size ranges', () {
      expect(
        () => FluidText(
          'invalid',
          minWidth: 100,
          maxWidth: 100,
          minFontSize: 10,
          maxFontSize: 20,
        ),
        throwsArgumentError,
      );
      expect(
        () => FluidText(
          'invalid',
          minWidth: 100,
          maxWidth: 200,
          minFontSize: 20,
          maxFontSize: 10,
        ),
        throwsArgumentError,
      );
    });

    testWidgets('forwards TextScaler and key', (WidgetTester tester) async {
      const key = ValueKey('fluid-text');
      await tester.pumpWidget(
        wrap(
          FluidText(
            'scaled',
            key: key,
            minWidth: 100,
            maxWidth: 200,
            minFontSize: 10,
            maxFontSize: 20,
            textScaler: TextScaler.noScaling,
          ),
          150,
        ),
      );

      final text = tester.widget<Text>(find.byKey(key));
      expect(text.textScaler, TextScaler.noScaling);
    });

    goldenTest(
      'spans match goldens',
      fileName: 'responsive_text_fluid_text',
      constraints: const BoxConstraints(maxWidth: 640),
      builder: () {
        final text = FluidText(
          'Test',
          minWidth: 200,
          maxWidth: 500,
          minFontSize: 10,
          maxFontSize: 30,
        );

        return GoldenTestGroup(
          columns: 1,
          children: [
            GoldenTestScenario(
              name: '100 (below minWidth)',
              child: wrap(text, 100),
            ),
            GoldenTestScenario(
              name: '200 (at minWidth)',
              child: wrap(text, 200),
            ),
            GoldenTestScenario(name: '300 (in range)', child: wrap(text, 300)),
            GoldenTestScenario(name: '400 (in range)', child: wrap(text, 400)),
            GoldenTestScenario(
              name: '500 (at maxWidth)',
              child: wrap(text, 500),
            ),
            GoldenTestScenario(
              name: '600 (above maxWidth)',
              child: wrap(text, 600),
            ),
          ],
        );
      },
    );
  });
}

Widget wrap(Widget widget, double width) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 70)),
    child: Directionality(textDirection: TextDirection.ltr, child: widget),
  );
}
