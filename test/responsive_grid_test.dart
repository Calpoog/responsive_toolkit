import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:responsive_toolkit/responsive_toolkit.dart';

const textWidth = 56.0;
const textLongWidth = textWidth * 3;
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
ResponsiveColumn auto({
  double width = textWidth,
  int offset = 0,
  double? height = 50,
}) => ResponsiveColumn.auto(
  offset: offset,
  child: container(width: width, height: height),
);
ResponsiveColumn fill({String? text, int offset = 0, Widget? child}) =>
    ResponsiveColumn.fill(
      offset: offset,
      child: child ?? (text == null ? SizedBox.shrink() : Text(text)),
    );

Widget container({
  Color color = Colors.grey,
  Widget? child,
  String? text,
  double? width,
  double? height = 50.0,
}) => Container(
  height: height,
  width: width,
  decoration: BoxDecoration(color: color, border: Border.all()),
  child: child ?? (text == null ? null : Text(text)),
);

Widget full(Widget child) => ColoredBox(
  color: Colors.white,
  child: SizedBox(width: double.infinity, child: child),
);

GoldenTestScenario scenario(String name, Widget child) =>
    GoldenTestScenario(name: name, child: full(child));

Widget breakpointScenario(double width, Widget child) => MediaQuery(
  data: MediaQueryData(size: Size(width, 70)),
  child: ColoredBox(
    color: Colors.white,
    child: ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: width, height: 70),
      child: child,
    ),
  ),
);

Widget content(double width, [double height = 50]) => Align(
  alignment: Alignment.center,
  child: Container(color: Colors.green, height: height, width: width),
);

void main() {
  group('ResponsiveRow Breakpoints', () {
    goldenTest(
      'fills match goldens',
      fileName: 'responsive_row_breakpoints',
      constraints: const BoxConstraints(maxWidth: 1532),
      builder: () {
        final cases = <(String, double)>[
          ('xs', 400),
          ('sm', 600),
          ('md', 800),
          ('lg', 1000),
          ('xl', 1300),
          ('xxl', 1500),
        ];
        final scenarios = <GoldenTestScenario>[];

        for (final (name, width) in cases) {
          scenarios.add(
            GoldenTestScenario(
              name: 'Span and offset - $name',
              child: breakpointScenario(
                width,
                ResponsiveRow(
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
                      child: container(),
                    ),
                  ],
                ),
              ),
            ),
          );
          scenarios.add(
            GoldenTestScenario(
              name: 'Swapping types - $name',
              child: breakpointScenario(
                width,
                ResponsiveRow(
                  breakOnConstraints: true,
                  columns: [
                    ResponsiveColumn(
                      Breakpoints(
                        xs: ResponsiveColumnConfig(),
                        sm: ResponsiveColumnConfig(
                          type: ResponsiveColumnType.fill,
                        ),
                        md: ResponsiveColumnConfig(
                          type: ResponsiveColumnType.auto,
                        ),
                        lg: ResponsiveColumnConfig(
                          type: ResponsiveColumnType.fill,
                        ),
                        xl: ResponsiveColumnConfig(
                          type: ResponsiveColumnType.auto,
                        ),
                        xxl: ResponsiveColumnConfig(
                          type: ResponsiveColumnType.fill,
                        ),
                      ),
                      child: container(text: 'Hello'),
                    ),
                    ResponsiveColumn.span(span: 1, child: container()),
                  ],
                ),
              ),
            ),
          );
          scenarios.add(
            GoldenTestScenario(
              name: 'Reordering - $name',
              child: breakpointScenario(
                width,
                ResponsiveRow(
                  breakOnConstraints: true,
                  columns: [
                    ResponsiveColumn(
                      Breakpoints(
                        xs: ResponsiveColumnConfig(span: 1),
                        sm: ResponsiveColumnConfig(span: 1, order: 2),
                        md: ResponsiveColumnConfig(span: 1, order: 4),
                        lg: ResponsiveColumnConfig(span: 1, order: 6),
                        xl: ResponsiveColumnConfig(span: 1, order: 8),
                        xxl: ResponsiveColumnConfig(span: 1, order: 10),
                      ),
                      child: container(color: colors.last),
                    ),
                    ...List.generate(
                      11,
                      (i) => ResponsiveColumn.span(
                        span: 1,
                        order: i,
                        child: container(color: colors[i]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return GoldenTestGroup(columns: 1, children: scenarios);
      },
    );
  });

  group('ResponsiveColumn', () {
    testWidgets('config sets type to span if not provided', (
      WidgetTester tester,
    ) async {
      final col = ResponsiveColumnConfig(span: 2);
      expect(col.type, equals(ResponsiveColumnType.span));
    });

    testWidgets('config sets type to span if not provided when composed', (
      WidgetTester tester,
    ) async {
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

    testWidgets('can compose multiple breakpoints', (
      WidgetTester tester,
    ) async {
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
    testWidgets(
      'dry layout uses supplied constraints without changing layout',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 300,
                child: ResponsiveRow(
                  breakOnConstraints: true,
                  columns: [span(6), span(6)],
                ),
              ),
            ),
          ),
        );

        final renderBox = tester.renderObject<RenderBox>(
          find.byType(ResponsiveRow),
        );
        final firstChild = tester.renderObject<RenderBox>(
          find.byType(Container).first,
        );
        final originalSize = renderBox.size;
        final originalOffset = (firstChild.parentData! as BoxParentData).offset;

        expect(
          renderBox.getDryLayout(const BoxConstraints.tightFor(width: 120)),
          const Size(120, 50),
        );
        expect(renderBox.size, originalSize);
        expect(
          (firstChild.parentData! as BoxParentData).offset,
          originalOffset,
        );
      },
    );

    testWidgets('empty row has no phantom run spacing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              child: ResponsiveRow(runSpacing: 20, columns: []),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(ResponsiveRow)).height, 0);
    });

    testWidgets(
      'constraint breakpoints remain constraint based after rebuild',
      (WidgetTester tester) async {
        Widget build(double width) => MaterialApp(
          home: Center(
            child: SizedBox(
              width: width,
              child: ResponsiveRow(
                key: const ValueKey('constraint-row'),
                breakOnConstraints: true,
                columns: [
                  ResponsiveColumn(
                    Breakpoints(
                      xs: const ResponsiveColumnConfig(span: 12),
                      sm: const ResponsiveColumnConfig(span: 6),
                    ),
                    child: container(),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpWidget(build(300));
        expect(tester.getSize(find.byType(Container)).width, 300);
        await tester.pumpWidget(build(600));
        expect(tester.getSize(find.byType(Container)).width, 300);
      },
    );

    goldenTest(
      'spans match goldens',
      fileName: 'span_columns',
      constraints: const BoxConstraints(maxWidth: 1232),
      builder: () {
        final golden = <GoldenTestScenario>[];
        void add(String name, Widget child) =>
            golden.add(scenario(name, child));
        add('12 columns', ResponsiveRow(columns: List.filled(12, span(1))));

        for (int i = 1; i < 12; i++) {
          add(
            '$i/${12 - i} columns',
            ResponsiveRow(
              columns: [
                ResponsiveColumn.span(span: i, child: container()),
                ResponsiveColumn.span(span: 12 - i, child: container()),
              ],
            ),
          );
        }

        for (int i = 1; i < 12; i++) {
          add(
            '$i offset',
            ResponsiveRow(
              columns: [
                ResponsiveColumn.span(span: 1, offset: i, child: container()),
              ],
            ),
          );
        }

        add(
          'Wrapping span columns',
          ResponsiveRow(columns: [span(7), span(6)]),
        );

        add(
          'Muliple runs wrapping span columns',
          ResponsiveRow(columns: [span(7), span(3), span(3), span(8), span(5)]),
        );

        add(
          'Span with fill',
          ResponsiveRow(
            columns: [
              span(4),
              fill(child: container()),
            ],
          ),
        );

        add(
          'Span with multiple fills',
          ResponsiveRow(
            columns: [
              span(4),
              fill(child: container()),
              fill(child: container()),
              fill(child: container()),
            ],
          ),
        );

        add(
          'Fill before span',
          ResponsiveRow(
            columns: [
              fill(child: container()),
              span(4),
            ],
          ),
        );

        add(
          'Supports other column counts',
          ResponsiveRow(
            maxColumns: 10,
            columns: List.generate(
              10,
              (i) => ResponsiveColumn.span(
                span: 1,
                order: 1,
                child: container(color: colors[i]),
              ),
            ),
          ),
        );

        add(
          '12 ordinal 1 columns',
          ResponsiveRow(
            columns: List.generate(
              12,
              (i) => ResponsiveColumn.span(
                span: 1,
                order: 1,
                child: container(color: colors[i]),
              ),
            ),
          ),
        );

        List<ResponsiveColumn> ordered = List.generate(
          11,
          (i) => ResponsiveColumn.span(
            span: 1,
            order: i + 1,
            child: container(color: colors[i]),
          ),
        );

        add(
          'One column reordered to front',
          ResponsiveRow(
            columns: List.from(ordered)
              ..add(
                ResponsiveColumn.span(
                  span: 1,
                  order: 0,
                  child: container(color: colors[11]),
                ),
              ),
          ),
        );

        add(
          'One column reordered to middle',
          ResponsiveRow(
            columns: List.from(ordered)
              ..add(
                ResponsiveColumn.span(
                  span: 1,
                  order: 5,
                  child: container(color: colors[11]),
                ),
              ),
          ),
        );

        final spans = List.generate(
          12,
          (i) => ResponsiveColumn.span(
            span: 2,
            child: container(height: 10 * (i + 1)),
          ),
        );
        add('Cross axis alignment start', ResponsiveRow(columns: spans));

        add(
          'Cross axis alignment end',
          ResponsiveRow(
            crossAxisAlignment: ResponsiveCrossAlignment.end,
            columns: spans,
          ),
        );

        add(
          'Cross axis alignment center',
          ResponsiveRow(
            crossAxisAlignment: ResponsiveCrossAlignment.center,
            columns: spans,
          ),
        );

        add(
          'Cross axis alignment stretch',
          ResponsiveRow(
            crossAxisAlignment: ResponsiveCrossAlignment.stretch,
            columns: spans,
          ),
        );

        return GoldenTestGroup(
          columns: 1,
          columnWidthBuilder: (_) => const FixedColumnWidth(1216),
          scenarioConstraints: const BoxConstraints.tightFor(width: 1200),
          children: golden,
        );
      },
    );

    goldenTest(
      'autos match goldens',
      fileName: 'auto_columns',
      constraints: const BoxConstraints(maxWidth: 1232),
      builder: () {
        final golden = <GoldenTestScenario>[];
        void add(String name, Widget child) =>
            golden.add(scenario(name, child));
        add('Auto columns', ResponsiveRow(columns: [auto(), auto()]));

        add(
          'Wrapping auto columns',
          ResponsiveRow(columns: List.filled(10, auto(width: textLongWidth))),
        );

        add(
          'Offset auto columns',
          ResponsiveRow(
            columns: [
              auto(offset: 1, width: textLongWidth),
              auto(offset: 2, width: textLongWidth),
              auto(offset: 3, width: textLongWidth),
            ],
          ),
        );

        add(
          'Auto columns with fill',
          ResponsiveRow(
            columns: [
              auto(width: textLongWidth),
              fill(child: container()),
            ],
          ),
        );

        add(
          'Auto columns with multiple fills',
          ResponsiveRow(
            columns: [
              auto(width: textLongWidth),
              fill(child: container()),
              fill(child: container()),
              fill(child: container()),
            ],
          ),
        );

        final autos = List.generate(
          12,
          (i) => auto(height: 10 * (i + 1), width: 28.0 * (i + 1)),
        );
        add('Cross axis alignment start', ResponsiveRow(columns: autos));

        add(
          'Cross axis alignment end',
          ResponsiveRow(
            crossAxisAlignment: ResponsiveCrossAlignment.end,
            columns: autos,
          ),
        );

        add(
          'Cross axis alignment center',
          ResponsiveRow(
            crossAxisAlignment: ResponsiveCrossAlignment.center,
            columns: autos,
          ),
        );

        add(
          'Cross axis alignment stretch',
          ResponsiveRow(
            crossAxisAlignment: ResponsiveCrossAlignment.stretch,
            columns: autos,
          ),
        );

        return GoldenTestGroup(
          columns: 1,
          columnWidthBuilder: (_) => const FixedColumnWidth(1216),
          scenarioConstraints: const BoxConstraints.tightFor(width: 1200),
          children: golden,
        );
      },
    );

    goldenTest(
      'fills match goldens',
      fileName: 'fill_columns',
      constraints: const BoxConstraints(maxWidth: 1232),
      builder: () {
        final golden = <GoldenTestScenario>[];
        void add(String name, Widget child) =>
            golden.add(scenario(name, child));

        add(
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

        add(
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
            // Override one specific alignment
            crossAxisAlignment: i == 1 ? ResponsiveCrossAlignment.end : null,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                border: Border.all(),
              ),
              child: content(50, 10 * (i + 1)),
            ),
          ),
        );
        add('Cross axis alignment start', ResponsiveRow(columns: fills));

        add(
          'Cross axis alignment end',
          ResponsiveRow(
            crossAxisAlignment: ResponsiveCrossAlignment.end,
            columns: fills,
          ),
        );

        add(
          'Cross axis alignment center',
          ResponsiveRow(
            crossAxisAlignment: ResponsiveCrossAlignment.center,
            columns: fills,
          ),
        );

        add(
          'Cross axis alignment stretch',
          ResponsiveRow(
            crossAxisAlignment: ResponsiveCrossAlignment.stretch,
            columns: fills,
          ),
        );

        return GoldenTestGroup(
          columns: 1,
          columnWidthBuilder: (_) => const FixedColumnWidth(1216),
          scenarioConstraints: const BoxConstraints.tightFor(width: 1200),
          children: golden,
        );
      },
    );
  });
}
