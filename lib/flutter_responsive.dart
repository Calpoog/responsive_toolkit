library flutter_responsive;

import 'package:flutter/widgets.dart';

/// A Widget that chooses a widget to display based on the screen size.
///
/// The returned Widget is chosen based on the greatest provided breakpoint
/// that satisfies `current screen width > breakpoint`
///
/// The default breakpoints are:
/// * xs:  < 576
/// * sm:  >= 578
/// * md:  >= 768
/// * lg:  >= 992
/// * xl:  >= 1200
/// * xxl: >= 1400
///
/// A Text Widget reading '>= 768' will be displayed by the following example
/// if the screen width is 800px. If the width was 1150px the result would still
/// be be the same as no 'lg' breakpoint was provided and it defaults to the
/// next smallest. One-off sizes can be provided using a [custom] mapping.
/// ```
/// ResponsiveLayout(
///   sm: Text('>= 576'),
///   md: Text('>= 768'),
///   xl: Text('>= 1200'),
///   custom: { 1600: Text('>= 1600') },
/// );
/// ```
///
/// WidgetBuilders can be used instead of Widgets to avoid building the Widget
/// prior to [ResponsiveLayout] deciding which to display.
/// ```
/// ResponsiveLayout.builder(
///   sm: (context) => Text('>= 576'),
///   md: (context) => Text('>= 768'),
///   xl: (context) => Text('>= 1200'),
///   custom: { 1600: (context) => Text('>= 1600') },
/// );
/// ```
class ResponsiveLayout extends BaseResponsiveLayout {
  /// The screen widths associated with the named paramater sizings.
  final List<int> breakpoints = [0, 576, 768, 992, 1200, 1400];

  /// Creates a Widget that chooses another widget to display based on the
  /// screen size.
  ///
  /// The xs breakpoint Widget is required.
  ResponsiveLayout({
    required Widget xs,
    Widget? sm,
    Widget? md,
    Widget? lg,
    Widget? xl,
    Widget? xxl,
    Map<int, Widget>? custom,
    Key? key,
  }) : super(
          [xs, sm, md, lg, xl, xxl],
          custom: custom,
          key: key,
        );

  /// Creates a Widget that chooses another widget to display based on the
  /// screen size using a WidgetBuilder.
  ///
  /// The xs breakpoint WidgetBuilder is required.
  ResponsiveLayout.builder({
    required WidgetBuilder xs,
    WidgetBuilder? sm,
    WidgetBuilder? md,
    WidgetBuilder? lg,
    WidgetBuilder? xl,
    WidgetBuilder? xxl,
    Map<int, WidgetBuilder>? custom,
    Key? key,
  }) : super.builder(
          [xs, sm, md, lg, xl, xxl],
          custom: custom,
          key: key,
        );
}

abstract class BaseResponsiveLayout extends StatelessWidget {
  final List<int> breakpoints = [0];

  final List<WidgetBuilder?> _widgets;

  BaseResponsiveLayout(
    List<Widget?> widgets, {
    Map<int, Widget>? custom,
    Key? key,
  })  : _widgets = _widgetToBuilder(widgets),
        super(key: key) {
    _checkConditions();
    _combineCustomBreakpoints(custom, isWidget: true);
  }

  BaseResponsiveLayout.builder(
    List<WidgetBuilder?> widgets, {
    Map<int, WidgetBuilder>? custom,
    Key? key,
  })  : _widgets = widgets,
        super(key: key) {
    _checkConditions();
    _combineCustomBreakpoints(custom);
  }

  _checkConditions() {
    if (breakpoints.first != 0) {
      throw ArgumentError('The smallest breakpoint width must be 0.');
    }
    if (_widgets.first == null) {
      throw ArgumentError('The smallest breakpoint widget cannot be null.');
    }
    if (_widgets.length != breakpoints.length) {
      throw ArgumentError(
          'The list of widgets and breakpoint config must be the same length.');
    }
  }

  _combineCustomBreakpoints(dynamic custom, {bool isWidget = false}) {
    // Splice the custom breakpoint sizes and widgets in with ordering
    if (custom != null) {
      custom.keys.forEach((size) {
        for (int i = 0; i < breakpoints.length; i++) {
          if (size < breakpoints[i]) {
            breakpoints.insert(i, size);
            _widgets.insert(i,
                isWidget ? (BuildContext _) => custom![size]! : custom[size]);
            break;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _choose(
      breakpoints,
      _widgets,
      MediaQuery.of(context).size.width,
    )(context);
  }
}

List<WidgetBuilder?> _widgetToBuilder(List<Widget?> widgets) {
  final List<WidgetBuilder?> result = [];
  widgets.forEach(
      (widget) => result.add(widget == null ? null : (context) => widget));
  return result;
}

T _choose<T>(List<int> sizes, List<T?> values, double width) {
  for (int i = sizes.length - 1; i >= 0; i--) {
    if (width >= sizes[i] && values[i] != null) {
      // It's been checked above that the value is non-null
      return values[i]!;
    }
  }
  // it is enforced that the smallest breakpoint Widget/value must be provided
  return values[0]!;
}
