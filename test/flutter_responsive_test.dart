import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_responsive/flutter_responsive.dart';

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
        tester.binding.window.physicalSizeTestValue = Size(width, 500);
        tester.binding.window.devicePixelRatioTestValue = 1;
        await tester.pumpWidget(wrap(ResponsiveLayout(
          xs: Text('xs'),
          sm: Text('sm'),
          md: Text('md'),
          lg: Text('lg'),
          xl: Text('xl'),
          xxl: Text('xxl'),
        )));

        expect(find.text(name), findsOneWidget);
        expect(find.byType(Text), findsOneWidget);
      });
    });

    testWidgets('shows xs widget when only xs and lg are specified',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = Size(800, 500);
      await tester.pumpWidget(wrap(ResponsiveLayout(
        xs: Text('xs'),
        lg: Text('lg'),
      )));

      expect(find.text('xs'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('enforces a 0 size and 6 sizes when changing the breakpoints',
        (WidgetTester tester) async {
      expect(() => ResponsiveLayout.breakpoints = [1, 2, 3, 4, 5, 6],
          throwsArgumentError);

      expect(() => ResponsiveLayout.breakpoints = [0, 1, 2, 3],
          throwsArgumentError);
    });

    testWidgets('can change breakpoints', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(ResponsiveLayout(
        xs: Text('xs'),
        lg: Text('lg'),
      )));

      expect(find.text('xs'), findsOneWidget);

      final old = ResponsiveLayout.breakpoints;
      ResponsiveLayout.breakpoints = [0, 100, 200, 300, 400, 500];

      await tester.pumpWidget(wrap(ResponsiveLayout(
        xs: Text('xs'),
        lg: Text('lg'),
      )));

      expect(find.text('lg'), findsOneWidget);

      ResponsiveLayout.breakpoints = old;
    });

    testWidgets('changes rendered widget when screen size changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(ResponsiveLayout(
        xs: Text('xs'),
        lg: Text('lg'),
      )));

      expect(find.text('xs'), findsOneWidget);

      tester.binding.window.physicalSizeTestValue = Size(1000, 500);

      await tester.pump();

      expect(find.text('lg'), findsOneWidget);
    });

    testWidgets('can use custom sizes', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = Size(500, 500);
      await tester.pumpWidget(wrap(ResponsiveLayout(
        xs: Text('xs'),
        lg: Text('lg'),
        custom: {700: Text('700')},
      )));

      expect(find.text('xs'), findsOneWidget);

      tester.binding.window.physicalSizeTestValue = Size(800, 500);

      await tester.pump();

      expect(find.text('700'), findsOneWidget);
    });

    testWidgets('.builder works using WidgetBuilders',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = Size(300, 500);
      await tester.pumpWidget(wrap(ResponsiveLayout.builder(
        xs: (_) => Text('xs'),
        lg: (_) => Text('lg'),
      )));

      expect(find.text('xs'), findsOneWidget);

      tester.binding.window.physicalSizeTestValue = Size(1000, 500);

      await tester.pump();

      expect(find.text('lg'), findsOneWidget);
    });

    testWidgets('.builder can use custom sizes', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = Size(500, 500);
      await tester.pumpWidget(wrap(ResponsiveLayout.builder(
        xs: (_) => Text('xs'),
        lg: (_) => Text('lg'),
        custom: {700: (_) => Text('700')},
      )));

      expect(find.text('xs'), findsOneWidget);

      tester.binding.window.physicalSizeTestValue = Size(800, 500);

      await tester.pump();

      expect(find.text('700'), findsOneWidget);
    });

    sizes.forEach((name, width) {
      testWidgets('.value changes Text to $name', (WidgetTester tester) async {
        tester.binding.window.physicalSizeTestValue = Size(width, 500);
        tester.binding.window.devicePixelRatioTestValue = 1;
        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (BuildContext context) => Text(
                ResponsiveLayout.value(
                  context,
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
        );

        expect(find.text(name), findsOneWidget);
        expect(find.byType(Text), findsOneWidget);
      });
    });

    testWidgets('.value can use custom sizes', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = Size(500, 500);
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (BuildContext context) => Text(
              ResponsiveLayout.value(
                context,
                xs: 'xs',
                lg: 'lg',
                custom: {700: '700'},
              ),
            ),
          ),
        ),
      );

      expect(find.text('xs'), findsOneWidget);

      tester.binding.window.physicalSizeTestValue = Size(800, 500);

      await tester.pump();

      expect(find.text('700'), findsOneWidget);
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
        tester.binding.window.physicalSizeTestValue = Size(width, 500);
        tester.binding.window.devicePixelRatioTestValue = 1;
        await tester.pumpWidget(wrap(MyResponsiveLayout(
          watch: Text('watch'),
          phone: Text('phone'),
          tablet: Text('tablet'),
          desktop: Text('desktop'),
        )));

        expect(find.text(name), findsOneWidget);
        expect(find.byType(Text), findsOneWidget);
      });
    });

    testWidgets('NoZeroResponsiveLayout throws errors',
        (WidgetTester tester) async {
      expect(
          () => NoZeroResponsiveLayout(
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
          () => NullSmallestSizeResponsiveLayout(
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

class MyResponsiveLayout extends BaseResponsiveLayout {
  static final List<int> breakpoints = [0, 200, 600, 900];

  MyResponsiveLayout({
    required Widget watch,
    Widget? phone,
    Widget? tablet,
    Widget? desktop,
    Map<int, Widget>? custom,
    Key? key,
  }) : super(
          [watch, phone, tablet, desktop],
          breakpoints,
          custom: custom,
          key: key,
        );

  MyResponsiveLayout.builder({
    required WidgetBuilder watch,
    WidgetBuilder? phone,
    WidgetBuilder? tablet,
    WidgetBuilder? desktop,
    Map<int, WidgetBuilder>? custom,
    Key? key,
  }) : super.builder(
          [watch, phone, tablet, desktop],
          breakpoints,
          custom: custom,
          key: key,
        );

  static T value<T>(
    BuildContext context, {
    required T watch,
    T? phone,
    T? tablet,
    T? desktop,
    Map<int, T>? custom,
  }) {
    return BaseResponsiveLayout.value(
      context,
      [watch, phone, tablet, desktop],
      breakpoints,
      custom: custom,
    );
  }
}

class NoZeroResponsiveLayout extends BaseResponsiveLayout {
  static final List<int> breakpoints = [100, 200, 600, 900];

  NoZeroResponsiveLayout({
    required Widget watch,
    Widget? phone,
    Widget? tablet,
    Widget? desktop,
    Map<int, Widget>? custom,
    Key? key,
  }) : super(
          [watch, phone, tablet, desktop],
          breakpoints,
          custom: custom,
          key: key,
        );

  NoZeroResponsiveLayout.builder({
    required WidgetBuilder watch,
    WidgetBuilder? phone,
    WidgetBuilder? tablet,
    WidgetBuilder? desktop,
    Map<int, WidgetBuilder>? custom,
    Key? key,
  }) : super.builder(
          [watch, phone, tablet, desktop],
          breakpoints,
          custom: custom,
          key: key,
        );

  static T value<T>(
    BuildContext context, {
    required T watch,
    T? phone,
    T? tablet,
    T? desktop,
    Map<int, T>? custom,
  }) {
    return BaseResponsiveLayout.value(
      context,
      [watch, phone, tablet, desktop],
      breakpoints,
      custom: custom,
    );
  }
}

class NullSmallestSizeResponsiveLayout extends BaseResponsiveLayout {
  static final List<int> breakpoints = [0, 200, 600, 900];

  NullSmallestSizeResponsiveLayout({
    Widget? watch,
    Widget? phone,
    Widget? tablet,
    Widget? desktop,
    Map<int, Widget>? custom,
    Key? key,
  }) : super(
          [watch, phone, tablet, desktop],
          breakpoints,
          custom: custom,
          key: key,
        );

  NullSmallestSizeResponsiveLayout.builder({
    WidgetBuilder? watch,
    WidgetBuilder? phone,
    WidgetBuilder? tablet,
    WidgetBuilder? desktop,
    Map<int, WidgetBuilder>? custom,
    Key? key,
  }) : super.builder(
          [watch, phone, tablet, desktop],
          breakpoints,
          custom: custom,
          key: key,
        );

  static T value<T>(
    BuildContext context, {
    required T watch,
    T? phone,
    T? tablet,
    T? desktop,
    Map<int, T>? custom,
  }) {
    return BaseResponsiveLayout.value(
      context,
      [watch, phone, tablet, desktop],
      breakpoints,
      custom: custom,
    );
  }
}
