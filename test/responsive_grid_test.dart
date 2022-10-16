import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:responsive_toolkit/responsive_toolkit.dart';

Widget container({Color? color, Widget? child, String? text, double? width, double height = 50}) => Container(
      height: height,
      width: width,
      decoration:
          BoxDecoration(color: color ?? Colors.blueGrey[100], border: Border.all(color: Colors.blueGrey.shade600)),
      child: child ?? (text == null ? null : Center(child: Text(text))),
    );

Widget full(child) => Container(
    width: double.infinity,
    child: DefaultTextStyle(
      style: TextStyle(fontFamily: 'Ahem'),
      child: child,
    ));

void main() {
  group('ResponsiveGrid', () {
    testGoldens('matches goldens', (WidgetTester tester) async {
      final golden = GoldenBuilder.column(wrap: full);
      final children = List.generate(11, (index) => ResponsiveGridItem(child: container(text: '$index')));

      golden.addScenario(
        'Auto placements - 3 flex columns',
        ResponsiveGrid(
          columns: [GridTrack.flex(), GridTrack.flex(), GridTrack.flex(2)],
          children: children,
        ),
      );

      golden.addScenario(
        'Auto placements - 3 fixed columns',
        ResponsiveGrid(
          columns: [GridTrack.fixed(100), GridTrack.fixed(100), GridTrack.fixed(100)],
          children: children,
        ),
      );

      golden.addScenario(
        'Auto placements - 3 auto columns',
        ResponsiveGrid(
          columns: [GridTrack.auto(), GridTrack.auto(), GridTrack.auto()],
          children: List.generate(
              11, (index) => ResponsiveGridItem(child: container(text: '$index', width: index * 10 + 50))),
        ),
      );

      golden.addScenario(
        'Auto placements - auto/fixed/flex columns',
        ResponsiveGrid(
          columns: [GridTrack.auto(), GridTrack.fixed(100), GridTrack.flex()],
          children: List.generate(
              11, (index) => ResponsiveGridItem(child: container(text: '$index', width: index * 10 + 50))),
        ),
      );

      golden.addScenario(
        'Auto placements - Cross axis align end',
        ResponsiveGrid(
          columns: [GridTrack.auto(), GridTrack.fixed(100), GridTrack.flex()],
          crossAxisAlignment: ResponsiveCrossAlignment.end,
          children: List.generate(
            11,
            (index) => ResponsiveGridItem(
              child: container(
                text: '$index',
                width: index * 10 + 50,
                height: index * 10 + 50,
              ),
            ),
          ),
        ),
      );

      golden.addScenario(
        'Auto placements - Rows with flex height',
        ResponsiveGrid(
          columns: [GridTrack.auto(), GridTrack.fixed(100), GridTrack.flex()],
          rows: [GridTrack.flex(), GridTrack.flex(), GridTrack.flex(2), GridTrack.flex()],
          children: List.generate(
            11,
            (index) => ResponsiveGridItem(
              child: container(
                text: '$index',
                width: index * 10 + 50,
                height: index * 10 + 50,
              ),
            ),
          ),
        ),
      );

      golden.addScenario(
        'Auto placements - Cross axis stretch',
        ResponsiveGrid(
          columns: [GridTrack.auto(), GridTrack.fixed(100), GridTrack.flex()],
          crossAxisAlignment: ResponsiveCrossAlignment.stretch,
          children: List.generate(
            11,
            (index) => ResponsiveGridItem(
              child: container(
                text: '$index',
                width: index * 10 + 50,
                height: index * 10 + 50,
              ),
            ),
          ),
        ),
      );

      golden.addScenario(
        'Complicated scenario',
        ResponsiveGrid(
          spacing: 10,
          columns: [
            GridTrack.auto(),
            GridTrack.fixed(50),
            GridTrack.flex(),
            GridTrack.flex(),
          ],
          rows: [
            GridTrack.auto(),
            GridTrack.fixed(70),
            GridTrack.auto(),
            GridTrack.auto(),
            GridTrack.flex(3),
            GridTrack.flex(),
          ],
          children: [
            ResponsiveGridItem(
              child: container(text: 'grid item 1', width: 250, height: 100),
              columnStart: 0,
              columnSpan: 2,
              rowStart: 0,
            ),
            ResponsiveGridItem(
              child: container(text: 'grid item 1.5', width: 300),
              columnStart: 0,
              columnSpan: 3,
              rowStart: 3,
            ),
            ResponsiveGridItem(
              child: container(text: 'grid item big', width: 300, height: 200),
              columnStart: 0,
              columnSpan: 2,
              rowStart: 1,
              rowSpan: 2,
            ),
            ResponsiveGridItem(child: container(text: 'grid item 2'), rowStart: 1),
            ResponsiveGridItem(
              child: container(text: 'grid item 3'),
              rowStart: 2,
            ),
            ResponsiveGridItem(
              child: container(text: 'grid item 3.5'),
              columnStart: 0,
              columnSpan: 2,
              rowStart: 4,
            ),
            ResponsiveGridItem(
              child: container(text: 'grid item 4', height: 250),
              columnStart: 2,
              rowStart: 0,
              rowSpan: 3,
            ),
            ResponsiveGridItem(
              child: container(text: 'grid item 5', height: 200),
              columnStart: 3,
              rowStart: 0,
              // rowSpan: 3,
            ),
            ResponsiveGridItem(
              child: container(text: 'Flex 1', height: 50),
              columnStart: 0,
              rowStart: 4,
            ),
            ResponsiveGridItem(
              child: container(text: 'Flex 1', height: 100),
              columnStart: 0,
              rowStart: 5,
            ),
            // ...List.generate(
            //     11, (index) => container(text: 'Cell $index', width: index * 10 + 50, height: index * 10 + 50)),
          ],
        ),
      );

      await tester.pumpWidgetBuilder(
        golden.build(),
        surfaceSize: Size(500, 5000),
      );

      await screenMatchesGolden(tester, 'grid');
    });
  });
}
