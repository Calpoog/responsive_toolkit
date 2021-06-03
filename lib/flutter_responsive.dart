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
  static List<int> _breakpoints = [0, 576, 768, 992, 1200, 1400];
  static set breakpoints(List<int> value) {
    if (value.length != 6)
      throw ArgumentError('You must specify all six breakpoints');
    if (value.first != 0) throw ArgumentError('The first breakpoint must be 0');

    _breakpoints = List.from(value);
    _breakpoints.sort((a, b) => a - b);
  }

  // maybe someone wants to retrieve the breakpoints for other reasons
  static List<int> get breakpoints => _breakpoints;

  /// Creates a Widget that chooses another Widget to display based on the
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
          breakpoints,
          custom: custom,
          key: key,
        );

  /// Creates a Widget that chooses another Widget to display based on the
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
          breakpoints,
          custom: custom,
          key: key,
        );

  static T value<T>(
    BuildContext context, {
    required T xs,
    T? sm,
    T? md,
    T? lg,
    T? xl,
    T? xxl,
    Map<int, T>? custom,
  }) {
    return BaseResponsiveLayout.value(
      context,
      [xs, sm, md, lg, xl, xxl],
      breakpoints,
      custom: custom,
    );
  }
}

class _BreakpointMap<T> {
  final List<int> breakpoints;
  final List<T?> values;

  _BreakpointMap(this.breakpoints, this.values);
}

/// The base responsive layout which allows any number of named breakpoints
/// and sizes.
abstract class BaseResponsiveLayout extends StatelessWidget {
  final _BreakpointMap<WidgetBuilder> _bps;

  BaseResponsiveLayout(
    List<Widget?> widgets,
    List<int> breakpoints, {
    Map<int, Widget>? custom,
    Key? key,
  })  : _bps = _combineCustomBreakpoints(
          breakpoints,
          widgets
              .map<WidgetBuilder?>(
                (widget) => widget == null ? null : (BuildContext _) => widget,
              )
              .toList(),
          custom?.map(
            (key, value) => MapEntry(key, (BuildContext _) => value),
          ),
        ),
        super(key: key) {
    _checkConditions();
  }

  BaseResponsiveLayout.builder(
    List<WidgetBuilder?> widgets,
    List<int> breakpoints, {
    Map<int, WidgetBuilder>? custom,
    Key? key,
  })  : _bps = _combineCustomBreakpoints(breakpoints, widgets, custom),
        super(key: key) {
    _checkConditions();
  }

  static T value<T>(
    BuildContext context,
    List<T?> values,
    List<int> breakpoints, {
    Map<int, T>? custom,
  }) {
    final _BreakpointMap<T> bps =
        _combineCustomBreakpoints(breakpoints, values, custom);
    return _choose(
      bps.breakpoints,
      bps.values,
      MediaQuery.of(context).size.width,
    );
  }

  /// Checks conditions that should be met by an extending class.
  _checkConditions() {
    if (_bps.breakpoints.first != 0) {
      throw ArgumentError('The smallest breakpoint width must be 0.');
    }
    if (_bps.values.first == null) {
      throw ArgumentError('The smallest breakpoint widget cannot be null.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _choose(
      _bps.breakpoints,
      _bps.values,
      MediaQuery.of(context).size.width,
    )(context);
  }
}

/// Mixes in the custom breakpoint with ordering
_BreakpointMap<T> _combineCustomBreakpoints<T>(
  List<int> breakpoints,
  List<T?> values,
  Map<int, T>? custom,
) {
  final List<int> bps = List.from(breakpoints);
  if (custom != null) {
    custom.keys.forEach((size) {
      for (int i = 0; i < bps.length; i++) {
        if (size < bps[i]) {
          bps.insert(i, size);
          values.insert(i, custom[size]!);
          return;
        }
      }
      bps.add(size);
      values.add(custom[size]!);
    });
  }

  return _BreakpointMap(bps, values);
}

/// Chooses a value from [values] based on which of [sizes] that [width]
/// satisfies
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
