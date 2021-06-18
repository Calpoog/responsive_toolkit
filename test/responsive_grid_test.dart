import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:responsive_toolkit/responsive_toolkit.dart';

const text = 'Test';
const textLong = text + text + text;
final colors = [
  Colors.white,
  Colors.blue.shade50,
  Colors.blue.shade100,
  Colors.blue.shade200,
  Colors.blue.shade300,
  Colors.blue.shade400,
  Colors.blue.shade500,
  Colors.blue.shade600,
  Colors.blue.shade700,
  Colors.blue.shade800,
  Colors.blue.shade900,
  Colors.black,
];

ResponsiveColumn span(int span, {int offset = 0}) =>
    ResponsiveColumn.span(span: span, offset: offset, child: container());
ResponsiveColumn auto({String text = text, int offset = 0}) =>
    ResponsiveColumn.auto(offset: offset, child: container(text: text));
ResponsiveColumn fill({String? text, int offset = 0, Widget? child}) =>
    ResponsiveColumn.fill(offset: offset, child: child ?? (text == null ? SizedBox.shrink() : Text(text)));

Widget container({Color color = Colors.grey, Widget? child, String? text, double? width}) => Container(
      height: 50,
      width: width,
      decoration: BoxDecoration(color: color, border: Border.all()),
      child: child ?? (text == null ? null : Text(text)),
    );

Widget full(child) => Container(
    width: double.infinity,
    child: DefaultTextStyle(
      style: TextStyle(fontFamily: 'Ahem'),
      child: child,
    ));

Widget content(double width) => Align(
      alignment: Alignment.center,
      child: Container(
        color: Colors.green,
        height: 50,
        width: width,
      ),
    );

void main() {
  group('ResponsiveColumn', () {
    testWidgets('accepts a single breakpoint', (WidgetTester tester) async {
      final col = ResponsiveColumn(
        Breakpoints(xs: ResponsiveColumnConfig(span: 2)),
        child: container(),
      );

      ResponsiveColumnConfig config = col.breakpoints.values.first!;
      expect(config.type == ResponsiveColumnType.auto, isTrue);
      expect(config.span == 2, isTrue);
      expect(config.offset == 0, isTrue);
      expect(config.order == 0, isTrue);
    });

    testWidgets('can compose multiple breakpoints', (WidgetTester tester) async {
      final col = ResponsiveColumn(
        Breakpoints(
          xs: ResponsiveColumnConfig(span: 2),
          md: ResponsiveColumnConfig(span: 3, type: ResponsiveColumnType.fill),
          xl: ResponsiveColumnConfig(type: ResponsiveColumnType.span, order: 4),
        ),
        child: container(),
      );

      ResponsiveColumnConfig md = col.breakpoints.values[2]!;
      expect(md.type == ResponsiveColumnType.fill, isTrue);
      expect(md.span == 3, isTrue);
      expect(md.offset == 0, isTrue);
      expect(md.order == 0, isTrue);

      ResponsiveColumnConfig xl = col.breakpoints.values[4]!;
      expect(xl.type == ResponsiveColumnType.span, isTrue);
      expect(xl.span == 3, isTrue);
      expect(xl.offset == 0, isTrue);
      expect(xl.order == 4, isTrue);
    });
  });

  group('ResponsiveRow', () {
    testGoldens('spans match goldens', (WidgetTester tester) async {
      final golden = GoldenBuilder.column(wrap: full);
      golden.addScenario(
          '12 columns',
          ResponsiveRow(
            columns: List.filled(12, span(1)),
          ));

      for (int i = 1; i < 12; i++) {
        golden.addScenario(
            '$i/${12 - i} columns',
            ResponsiveRow(columns: [
              ResponsiveColumn.span(span: i, child: container()),
              ResponsiveColumn.span(span: 12 - i, child: container())
            ]));
      }

      for (int i = 1; i < 12; i++) {
        golden.addScenario(
            '$i offset',
            ResponsiveRow(columns: [
              ResponsiveColumn.span(span: 1, offset: i, child: container()),
            ]));
      }

      golden.addScenario(
          'Wrapping span columns',
          ResponsiveRow(
            columns: [span(7), span(6)],
          ));

      golden.addScenario(
          'Muliple runs wrapping span columns',
          ResponsiveRow(
            columns: [span(7), span(3), span(3), span(8), span(5)],
          ));

      golden.addScenario(
        'Span with fill',
        ResponsiveRow(columns: [
          span(4),
          fill(child: container()),
        ]),
      );

      golden.addScenario(
        'Span with multiple fills',
        ResponsiveRow(columns: [
          span(4),
          fill(child: container()),
          fill(child: container()),
          fill(child: container()),
        ]),
      );

      golden.addScenario(
        'Fill before span',
        ResponsiveRow(columns: [
          fill(child: container()),
          span(4),
        ]),
      );

      golden.addScenario(
        '12 ordinal 1 columns',
        ResponsiveRow(
          columns:
              List.generate(12, (i) => ResponsiveColumn.span(span: 1, order: 1, child: container(color: colors[i]))),
        ),
      );

      List<ResponsiveColumn> ordered =
          List.generate(11, (i) => ResponsiveColumn.span(span: 1, order: i + 1, child: container(color: colors[i])));

      golden.addScenario(
        'One column reordered to front',
        ResponsiveRow(
          columns: List.from(ordered)
            ..add(ResponsiveColumn.span(span: 1, order: 0, child: container(color: colors[11]))),
        ),
      );

      golden.addScenario(
        'One column reordered to middle',
        ResponsiveRow(
          columns: List.from(ordered)
            ..add(ResponsiveColumn.span(span: 1, order: 5, child: container(color: colors[11]))),
        ),
      );

      await tester.pumpWidgetBuilder(
        golden.build(),
        surfaceSize: Size(1200, 4000),
      );

      await screenMatchesGolden(tester, 'span_columns');
    });

    testGoldens('autos match goldens', (WidgetTester tester) async {
      final golden = GoldenBuilder.column(wrap: full);
      golden.addScenario(
        'Auto columns',
        ResponsiveRow(columns: [
          auto(),
          auto(text: text),
        ]),
      );

      golden.addScenario(
        'Wrapping auto columns',
        ResponsiveRow(columns: List.filled(10, auto(text: textLong))),
      );

      golden.addScenario(
        'Offset auto columns',
        ResponsiveRow(columns: [
          auto(offset: 1, text: textLong),
          auto(offset: 2, text: textLong),
          auto(offset: 3, text: textLong),
        ]),
      );

      golden.addScenario(
        'Auto columns with fill',
        ResponsiveRow(columns: [
          auto(text: textLong),
          fill(child: container()),
        ]),
      );

      golden.addScenario(
        'Auto columns with multiple fills',
        ResponsiveRow(columns: [
          auto(text: textLong),
          fill(child: container()),
          fill(child: container()),
          fill(child: container()),
        ]),
      );

      await tester.pumpWidgetBuilder(
        golden.build(),
        surfaceSize: Size(1200, 4000),
      );

      await screenMatchesGolden(tester, 'auto_columns');
    });

    testGoldens('fills match goldens', (WidgetTester tester) async {
      final golden = GoldenBuilder.column(wrap: full);

      golden.addScenario(
        'Fill columns reduced to their min widths',
        ResponsiveRow(
          columns: [
            fill(child: container(child: content(50))),
            fill(child: container(child: content(100))),
            fill(child: container(child: content(200))),
            fill(child: container(child: content(300))),
            fill(child: container(child: content(300))),
          ],
        ),
      );

      golden.addScenario(
        'Fill columns wrap when all min widths break',
        ResponsiveRow(
          columns: [
            fill(child: container(child: content(50))),
            fill(child: container(child: content(100))),
            fill(child: container(child: content(200))),
            fill(child: container(child: content(300))),
            fill(child: container(child: content(600))),
          ],
        ),
      );

      await tester.pumpWidgetBuilder(
        golden.build(),
        surfaceSize: Size(1200, 4000),
      );

      await screenMatchesGolden(tester, 'fill_columns');
    });
  });
}
