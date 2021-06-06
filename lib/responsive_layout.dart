import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

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
/// be the same as no 'lg' breakpoint was provided and it defaults to the
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
    return breakpoints.choose(
      MediaQuery.of(context).size.width,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    return _breakpoints.choose(
      MediaQuery.of(context).size.width,
    )!(context);
  }
}
