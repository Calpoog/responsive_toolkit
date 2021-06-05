library flutter_responsive;

import 'package:flutter/widgets.dart';

class Breakpoints<T> extends BaseBreakpoints<T> {
  Breakpoints({
    required T xs,
    T? sm,
    T? md,
    T? lg,
    T? xl,
    T? xxl,
    Map<int, T>? custom,
  }) : super(
          breakpoints: [0, 576, 768, 992, 1200, 1400],
          values: [xs, sm, md, lg, xl, xxl],
          custom: custom,
        );
}

/// A set of breakpoints and associated values.
///
/// Extend this class to create custom breakpoint names and sizes.
class BaseBreakpoints<T> {
  /// The integer widths at which layout changes will occur.
  List<int> breakpoints = [];

  /// The values used at each breakpoint.
  List<T?> values;

  /// Creates a new set of breakpoints and associated values.
  BaseBreakpoints({
    required List<int> breakpoints,
    required this.values,
    Map<int, T>? custom,
  }) {
    // Check conditions – an extending class could try to break these rules
    if (breakpoints.first != 0) {
      throw ArgumentError('The smallest breakpoint width must be 0.');
    }
    if (values.first == null) {
      throw ArgumentError('The smallest breakpoint widget cannot be null.');
    }

    _combineCustomBreakpoints(breakpoints, custom);
  }

  // Combine the custom breakpoints into the existing breakpoint and values
  // lists
  _combineCustomBreakpoints(List<int> bps, Map<int, T>? custom) {
    breakpoints = List.from(bps);
    if (custom != null) {
      custom.keys.forEach((size) {
        for (int i = 0; i < breakpoints.length; i++) {
          if (size < breakpoints[i]) {
            breakpoints.insert(i, size);
            values.insert(i, custom[size]!);
            return;
          }
        }
        breakpoints.add(size);
        values.add(custom[size]!);
      });
    }
  }

  /// Create a new [BaseBreakpoints] with its [values] mapped to a new type.
  BaseBreakpoints<V> map<V>(V Function(T?) f) {
    return BaseBreakpoints(
      breakpoints: breakpoints,
      values: values.map<V>((v) => f(v)).toList(),
    );
  }
}

/// A Widget that chooses another Widget to display based on the screen size.
///
/// The displayed Widget is chosen based on the greatest provided breakpoint
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
///   Breakpoints(
///     sm: Text('>= 576'),
///     md: Text('>= 768'),
///     xl: Text('>= 1200'),
///     custom: { 1600: Text('>= 1600') },
///   ),
/// );
/// ```
///
/// WidgetBuilders can be used instead of Widgets to avoid building the Widget
/// prior to [ResponsiveLayout] deciding which to display.
/// ```
/// ResponsiveLayout.builder(
///   Breakpoints(
///     sm: (context) => Text('>= 576'),
///     md: (context) => Text('>= 768'),
///     xl: (context) => Text('>= 1200'),
///     custom: { 1600: (context) => Text('>= 1600') },
///   ),
/// );
/// ```
class ResponsiveLayout extends StatelessWidget {
  final BaseBreakpoints<WidgetBuilder?> _breakpoints;

  /// Creates a Widget that chooses another Widget to display based on the
  /// screen size.
  ResponsiveLayout(
    BaseBreakpoints<Widget> breakpoints, {
    Key? key,
  }) : _breakpoints = breakpoints.map(
            (widget) => widget == null ? null : (BuildContext _) => widget);

  /// Creates a Widget that chooses another Widget to display based on the
  /// screen size using a WidgetBuilder.
  ResponsiveLayout.builder(
    BaseBreakpoints<WidgetBuilder?> breakpoints, {
    Key? key,
  }) : _breakpoints = breakpoints;

  static T value<T>(BuildContext context, BaseBreakpoints<T?> breakpoints) {
    return _choose(
      breakpoints,
      MediaQuery.of(context).size.width,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _choose(
      _breakpoints,
      MediaQuery.of(context).size.width,
    )(context);
  }
}

/// Chooses a value based on which of [breakpoints] is satisfied by the current
/// screen [width].
T _choose<T>(BaseBreakpoints<T?> breakpoints, double width) {
  final sizes = breakpoints.breakpoints;
  final values = breakpoints.values;
  for (int i = sizes.length - 1; i >= 0; i--) {
    if (width >= sizes[i] && values[i] != null) {
      // It's been checked above that the value is non-null
      return values[i]!;
    }
  }
  // it is enforced that the smallest breakpoint Widget/value must be provided
  return values[0]!;
}
