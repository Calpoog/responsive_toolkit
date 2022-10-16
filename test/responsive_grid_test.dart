import 'package:flutter/material.dart';
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
ResponsiveColumn auto({String text = text, int offset = 0, double? height}) =>
    ResponsiveColumn.auto(
        offset: offset, child: container(text: text, height: height));
ResponsiveColumn fill({String? text, int offset = 0, Widget? child}) =>
    ResponsiveColumn.fill(
        offset: offset,
        child: child ?? (text == null ? SizedBox.shrink() : Text(text)));

Widget container(
        {Color color = Colors.grey,
        Widget? child,
        String? text,
        double? width,
        double? height = 50.0}) =>
    Container(
      height: height,
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

Widget content(double width, [double height = 50]) => Align(
      alignment: Alignment.center,
      child: Container(
        color: Colors.green,
        height: height,
        width: width,
      ),
    );

void main() {
  group('ResponsiveRow Breakpoints', () {
    testGoldens('fills match goldens', (WidgetTester tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device(name: 'xs', size: Size(400, 70)),
          Device(name: 'sm', size: Size(600, 70)),
          Device(name: 'md', size: Size(800, 70)),
          Device(name: 'lg', size: Size(1000, 70)),
          Device(name: 'xl', size: Size(1300, 70)),
          Device(name: 'xxl', size: Size(1500, 70)),
        ]);

      builder.addScenario(
        name: 'Span and offset',
        widget: ResponsiveRow(
          breakOnConstraints: true,
          columns: [
            ResponsiveColumn(
                Breakpoints(
                  xs: ResponsiveColumnConfig(span: 12),
                  sm: ResponsiveColumnConfig(span: 10, offset: 2),
                  md: ResponsiveColumnConfig(span: 8, offset: 4),
                  lg: ResponsiveColumnConfig(span: 6, offset: 6),
                  xl: ResponsiveColumnConfig(span: 4, offset: 8),
                  xxl: ResponsiveColumnConfig(span: 2, offset: 10),
                ),
                child: container()),
          ],
        ),
      );

      builder.addScenario(
        name: 'Swapping types',
        widget: ResponsiveRow(
          breakOnConstraints: true,
          columns: [
            ResponsiveColumn(
              Breakpoints(
                xs: ResponsiveColumnConfig(), // auto
                sm: ResponsiveColumnConfig(type: ResponsiveColumnType.fill),
                md: ResponsiveColumnConfig(type: ResponsiveColumnType.auto),
                lg: ResponsiveColumnConfig(type: ResponsiveColumnType.fill),
                xl: ResponsiveColumnConfig(type: ResponsiveColumnType.auto),
                xxl: ResponsiveColumnConfig(type: ResponsiveColumnType.fill),
              ),
              child: container(text: 'Hello'),
            ),
            ResponsiveColumn.span(span: 1, child: container()),
          ],
        ),
      );

      builder.addScenario(
        name: 'Reordering',
        widget: ResponsiveRow(
          breakOnConstraints: true,
          columns: [
            ResponsiveColumn(
                Breakpoints(
                  xs: ResponsiveColumnConfig(span: 1), // auto
                  sm: ResponsiveColumnConfig(span: 1, order: 2),
                  md: ResponsiveColumnConfig(span: 1, order: 4),
                  lg: ResponsiveColumnConfig(span: 1, order: 6),
                  xl: ResponsiveColumnConfig(span: 1, order: 8),
                  xxl: ResponsiveColumnConfig(span: 1, order: 10),
                ),
                child: container(color: colors.last)),
            ...List.generate(
                11,
                (i) => ResponsiveColumn.span(
                    span: 1, order: i, child: container(color: colors[i]))),
          ],
        ),
      );

      await tester.pumpDeviceBuilder(builder);

      await screenMatchesGolden(tester, 'responsive_row_breakpoints');
    });
  });

  group('ResponsiveColumn', () {
    testWidgets('config sets type to span if not provided',
        (WidgetTester tester) async {
      final col = ResponsiveColumnConfig(span: 2);
      expect(col.type, equals(ResponsiveColumnType.span));
    });

    testWidgets('config sets type to span if not provided when composed',
        (WidgetTester tester) async {
      final col = ResponsiveColumn(
        Breakpoints(
          xs: ResponsiveColumnConfig(),
          md: ResponsiveColumnConfig(type: ResponsiveColumnType.fill),
          xl: ResponsiveColumnConfig(span: 2),
        ),
        child: container(),
      );

      ResponsiveColumnConfig config = col.breakpoints.values[4]!;
      expect(config.type, equals(ResponsiveColumnType.span));
    });

    testWidgets('accepts a single breakpoint', (WidgetTester tester) async {
      final col = ResponsiveColumn(
        Breakpoints(xs: ResponsiveColumnConfig(span: 2)),
        child: container(),
      );

      ResponsiveColumnConfig config = col.breakpoints.values.first!;
      expect(config.type, equals(ResponsiveColumnType.span));
      expect(config.span, equals(2));
      expect(config.offset, equals(0));
      expect(config.order, equals(0));
    });

    testWidgets('can compose multiple breakpoints',
        (WidgetTester tester) async {
      final col = ResponsiveColumn(
        Breakpoints(
          xs: ResponsiveColumnConfig(span: 2),
          md: ResponsiveColumnConfig(span: 3, type: ResponsiveColumnType.fill),
          xl: ResponsiveColumnConfig(type: ResponsiveColumnType.span, order: 4),
        ),
        child: container(),
      );

      ResponsiveColumnConfig md = col.breakpoints.values[2]!;
      expect(md.type, equals(ResponsiveColumnType.fill));
      expect(md.span, equals(3));
      expect(md.offset, equals(0));
      expect(md.order, equals(0));

      ResponsiveColumnConfig xl = col.breakpoints.values[4]!;
      expect(xl.type, equals(ResponsiveColumnType.span));
      expect(xl.span, equals(3));
      expect(xl.offset, equals(0));
      expect(xl.order, equals(4));
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
        'Supports other column counts',
        ResponsiveRow(
          maxColumns: 10,
          columns: List.generate(
              10,
              (i) => ResponsiveColumn.span(
                  span: 1, order: 1, child: container(color: colors[i]))),
        ),
      );

      golden.addScenario(
        '12 ordinal 1 columns',
        ResponsiveRow(
          columns: List.generate(
              12,
              (i) => ResponsiveColumn.span(
                  span: 1, order: 1, child: container(color: colors[i]))),
        ),
      );

      List<ResponsiveColumn> ordered = List.generate(
          11,
          (i) => ResponsiveColumn.span(
              span: 1, order: i + 1, child: container(color: colors[i])));

      golden.addScenario(
        'One column reordered to front',
        ResponsiveRow(
          columns: List.from(ordered)
            ..add(ResponsiveColumn.span(
                span: 1, order: 0, child: container(color: colors[11]))),
        ),
      );

      golden.addScenario(
        'One column reordered to middle',
        ResponsiveRow(
          columns: List.from(ordered)
            ..add(ResponsiveColumn.span(
                span: 1, order: 5, child: container(color: colors[11]))),
        ),
      );

      final spans = List.generate(
          12,
          (i) => ResponsiveColumn.span(
              span: 2, child: container(height: 10 * (i + 1))));
      golden.addScenario(
        'Cross axis alignment start',
        ResponsiveRow(
          columns: spans,
        ),
      );

      golden.addScenario(
        'Cross axis alignment end',
        ResponsiveRow(
          crossAxisAlignment: ResponsiveCrossAlignment.end,
          columns: spans,
        ),
      );

      golden.addScenario(
        'Cross axis alignment center',
        ResponsiveRow(
          crossAxisAlignment: ResponsiveCrossAlignment.center,
          columns: spans,
        ),
      );

      golden.addScenario(
        'Cross axis alignment stretch',
        ResponsiveRow(
          crossAxisAlignment: ResponsiveCrossAlignment.stretch,
          columns: spans,
        ),
      );

      await tester.pumpWidgetBuilder(
        golden.build(),
        surfaceSize: Size(1200, 4500),
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

      final autos = List.generate(12,
          (i) => auto(height: 10 * (i + 1), text: 'XX'.padLeft(i * 2, 'X')));
      golden.addScenario(
        'Cross axis alignment start',
        ResponsiveRow(
          columns: autos,
        ),
      );

      golden.addScenario(
        'Cross axis alignment end',
        ResponsiveRow(
          crossAxisAlignment: ResponsiveCrossAlignment.end,
          columns: autos,
        ),
      );

      golden.addScenario(
        'Cross axis alignment center',
        ResponsiveRow(
          crossAxisAlignment: ResponsiveCrossAlignment.center,
          columns: autos,
        ),
      );

      golden.addScenario(
        'Cross axis alignment stretch',
        ResponsiveRow(
          crossAxisAlignment: ResponsiveCrossAlignment.stretch,
          columns: autos,
        ),
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

      final fills = List.generate(
        4,
        (i) => ResponsiveColumn.fill(
          crossAxisAlignment: i == 1 ? ResponsiveCrossAlignment.end : null,
          child: Container(
              decoration:
                  BoxDecoration(color: Colors.grey, border: Border.all()),
              child: content(50, 10 * (i + 1))),
        ),
      );
      golden.addScenario(
        'Cross axis alignment start',
        ResponsiveRow(
          columns: fills,
        ),
      );

      golden.addScenario(
        'Cross axis alignment end',
        ResponsiveRow(
          crossAxisAlignment: ResponsiveCrossAlignment.end,
          columns: fills,
        ),
      );

      golden.addScenario(
        'Cross axis alignment center',
        ResponsiveRow(
          crossAxisAlignment: ResponsiveCrossAlignment.center,
          columns: fills,
        ),
      );

      golden.addScenario(
        'Cross axis alignment stretch',
        ResponsiveRow(
          crossAxisAlignment: ResponsiveCrossAlignment.stretch,
          columns: fills,
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
