import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:responsive_toolkit/responsive_toolkit.dart';

void main() {
  group('ResponsiveLayout', () {
    final Map<String, double> sizes = {
      'xs': 300,
      'sm': 600,
      'md': 800,
      'lg': 1000,
      'xl': 1250,
      'xxl': 1500
    };

    sizes.forEach((name, width) {
      testWidgets('shows $name widget', (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 500);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(wrap(ResponsiveLayout(
          Breakpoints(
            xs: Text('xs'),
            sm: Text('sm'),
            md: Text('md'),
            lg: Text('lg'),
            xl: Text('xl'),
            xxl: Text('xxl'),
          ),
        )));

        expect(find.text(name), findsOneWidget);
        expect(find.byType(Text), findsOneWidget);
      });
    });

    testWidgets('shows xs widget when only xs and lg are specified',
        (WidgetTester tester) async {
      tester.view.physicalSize = Size(800, 500);
      await tester.pumpWidget(wrap(ResponsiveLayout(
        Breakpoints(
          xs: Text('xs'),
          lg: Text('lg'),
        ),
      )));

      expect(find.text('xs'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('changes rendered widget when screen size changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(ResponsiveLayout(
        Breakpoints(
          xs: Text('xs'),
          lg: Text('lg'),
        ),
      )));

      expect(find.text('xs'), findsOneWidget);

      tester.view.physicalSize = Size(1000, 500);

      await tester.pump();

      expect(find.text('lg'), findsOneWidget);
    });

    testWidgets('can use custom sizes', (WidgetTester tester) async {
      tester.view.physicalSize = Size(500, 500);
      await tester.pumpWidget(wrap(ResponsiveLayout(
        Breakpoints(
          xs: Text('xs'),
          lg: Text('lg'),
          custom: {
            700: Text('700'),
            800: Text('800'),
            1050: Text('1050'),
          },
        ),
      )));

      expect(find.text('xs'), findsOneWidget);

      tester.view.physicalSize = Size(750, 500);
      await tester.pump();
      expect(find.text('700'), findsOneWidget);

      tester.view.physicalSize = Size(850, 500);
      await tester.pump();
      expect(find.text('800'), findsOneWidget);

      tester.view.physicalSize = Size(1000, 500);
      await tester.pump();
      expect(find.text('lg'), findsOneWidget);

      tester.view.physicalSize = Size(1100, 500);
      await tester.pump();
      expect(find.text('1050'), findsOneWidget);
    });

    testWidgets('.builder works using WidgetBuilders',
        (WidgetTester tester) async {
      tester.view.physicalSize = Size(300, 500);
      await tester.pumpWidget(wrap(ResponsiveLayout.builder(
        Breakpoints(
          xs: (_) => Text('xs'),
          lg: (_) => Text('lg'),
        ),
      )));

      expect(find.text('xs'), findsOneWidget);

      tester.view.physicalSize = Size(1000, 500);

      await tester.pump();

      expect(find.text('lg'), findsOneWidget);
    });

    testWidgets('.builder can use custom sizes', (WidgetTester tester) async {
      tester.view.physicalSize = Size(500, 500);
      await tester.pumpWidget(wrap(ResponsiveLayout.builder(
        Breakpoints(
          xs: (_) => Text('xs'),
          lg: (_) => Text('lg'),
          custom: {
            700: (_) => Text('700'),
            800: (_) => Text('800'),
            1050: (_) => Text('1050'),
          },
        ),
      )));

      expect(find.text('xs'), findsOneWidget);

      tester.view.physicalSize = Size(750, 500);
      await tester.pump();
      expect(find.text('700'), findsOneWidget);

      tester.view.physicalSize = Size(850, 500);
      await tester.pump();
      expect(find.text('800'), findsOneWidget);

      tester.view.physicalSize = Size(1000, 500);
      await tester.pump();
      expect(find.text('lg'), findsOneWidget);

      tester.view.physicalSize = Size(1100, 500);
      await tester.pump();
      expect(find.text('1050'), findsOneWidget);
    });

    sizes.forEach((name, width) {
      testWidgets('.value changes Text to $name', (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 500);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (BuildContext context) => Text(
                ResponsiveLayout.value(
                  context,
                  Breakpoints(
                    xs: 'xs',
                    sm: 'sm',
                    md: 'md',
                    lg: 'lg',
                    xl: 'xl',
                    xxl: 'xxl',
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text(name), findsOneWidget);
        expect(find.byType(Text), findsOneWidget);
      });
    });

    testWidgets('.value can use custom sizes', (WidgetTester tester) async {
      tester.view.physicalSize = Size(500, 500);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (BuildContext context) => Text(
              ResponsiveLayout.value(
                context,
                Breakpoints(
                  xs: 'xs',
                  lg: 'lg',
                  custom: {
                    700: '700',
                    800: '800',
                    1050: '1050',
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('xs'), findsOneWidget);

      tester.view.physicalSize = Size(750, 500);
      await tester.pump();
      expect(find.text('700'), findsOneWidget);

      tester.view.physicalSize = Size(850, 500);
      await tester.pump();
      expect(find.text('800'), findsOneWidget);

      tester.view.physicalSize = Size(1000, 500);
      await tester.pump();
      expect(find.text('lg'), findsOneWidget);

      tester.view.physicalSize = Size(1100, 500);
      await tester.pump();
      expect(find.text('1050'), findsOneWidget);
    });

    testWidgets('changes rendered widget on vertical axes',
        (WidgetTester tester) async {
      tester.view.physicalSize = Size(500, 500);
      await tester.pumpWidget(wrap(ResponsiveLayout(
        Breakpoints(
          xs: Text('xs vertical'),
          lg: Text('lg vertical'),
        ),
        axis: Axis.vertical,
      )));

      expect(find.text('xs vertical'), findsOneWidget);

      tester.view.physicalSize = Size(500, 1000);

      await tester.pump();

      expect(find.text('lg vertical'), findsOneWidget);
    });
  });

  group('ResponsiveConstraintLayout', () {
    testWidgets('changes rendered widget on horizontal axis',
        (WidgetTester tester) async {
      tester.view.physicalSize = Size(500, 500);

      final widget = wrap(
        Row(
          children: [
            Expanded(
              child: ResponsiveConstraintLayout(
                Breakpoints(
                  xs: Text('xs'),
                  sm: Text('sm'),
                  lg: Text('lg'),
                  custom: {300: Text('300')},
                ),
              ),
            ),
            Expanded(
              child: Container(),
            ),
          ],
        ),
      );
      await tester.pumpWidget(widget);

      expect(find.text('xs'), findsOneWidget);

      tester.view.physicalSize = Size(700, 500);
      await tester.pump();
      expect(find.text('300'), findsOneWidget);

      tester.view.physicalSize = Size(1200, 500);
      await tester.pump();
      expect(find.text('sm'), findsOneWidget);

      tester.view.physicalSize = Size(2000, 500);
      await tester.pump();
      expect(find.text('lg'), findsOneWidget);
    });

    testWidgets('changes rendered widget on vertical axis',
        (WidgetTester tester) async {
      tester.view.physicalSize = Size(500, 500);

      final widget = wrap(
        Column(
          children: [
            Expanded(
              child: ResponsiveConstraintLayout(
                Breakpoints(
                  xs: Text('xs'),
                  sm: Text('sm'),
                  lg: Text('lg'),
                  custom: {300: Text('300')},
                ),
                axis: Axis.vertical,
              ),
            ),
            Expanded(
              child: Container(),
            ),
          ],
        ),
      );
      await tester.pumpWidget(widget);

      expect(find.text('xs'), findsOneWidget);

      tester.view.physicalSize = Size(500, 700);
      await tester.pump();
      expect(find.text('300'), findsOneWidget);

      tester.view.physicalSize = Size(500, 1200);
      await tester.pump();
      expect(find.text('sm'), findsOneWidget);

      tester.view.physicalSize = Size(500, 2000);
      await tester.pump();
      expect(find.text('lg'), findsOneWidget);
    });
  });

  group('Extended Classes', () {
    final Map<String, double> sizes = {
      'watch': 100,
      'phone': 400,
      'tablet': 800,
      'desktop': 1200,
    };

    sizes.forEach((name, width) {
      testWidgets('MyResponsiveLayout shows $name widget',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 500);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(wrap(ResponsiveLayout(
          MyBreakpoints(
            watch: Text('watch'),
            phone: Text('phone'),
            tablet: Text('tablet'),
            desktop: Text('desktop'),
          ),
        )));

        expect(find.text(name), findsOneWidget);
        expect(find.byType(Text), findsOneWidget);
      });
    });

    testWidgets('NoZeroBreakpoints throws errors', (WidgetTester tester) async {
      expect(
          () => NoZeroBreakpoints(
                watch: Text('watch'),
                phone: Text('phone'),
                tablet: Text('tablet'),
                desktop: Text('desktop'),
              ),
          throwsArgumentError);
    });

    testWidgets('NullSmallestSizeResponsiveLayout throws errors',
        (WidgetTester tester) async {
      expect(
          () => NullSmallestBreakpoints(
                phone: Text('phone'),
                tablet: Text('tablet'),
                desktop: Text('desktop'),
              ),
          throwsArgumentError);
    });
  });
}

Widget wrap(Widget widget) {
  return MaterialApp(home: widget);
}

class MyBreakpoints<T> extends BaseBreakpoints<T> {
  MyBreakpoints({
    required T watch,
    T? phone,
    T? tablet,
    T? desktop,
    Map<int, T>? custom,
  }) : super(
          breakpoints: [0, 200, 600, 900],
          values: [watch, phone, tablet, desktop],
          custom: custom,
        );
}

class NoZeroBreakpoints<T> extends BaseBreakpoints<T> {
  NoZeroBreakpoints({
    required T watch,
    T? phone,
    T? tablet,
    T? desktop,
    Map<int, T>? custom,
  }) : super(
          breakpoints: [50, 200, 600, 900],
          values: [watch, phone, tablet, desktop],
          custom: custom,
        );
}

class NullSmallestBreakpoints<T> extends BaseBreakpoints<T> {
  NullSmallestBreakpoints({
    T? watch,
    T? phone,
    T? tablet,
    T? desktop,
    Map<int, T>? custom,
  }) : super(
          breakpoints: [0, 200, 600, 900],
          values: [watch, phone, tablet, desktop],
          custom: custom,
        );
}
