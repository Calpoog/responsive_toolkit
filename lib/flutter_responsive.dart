library flutter_responsive;

import 'dart:collection';

import 'package:flutter/widgets.dart';

class ResponsiveBuilder extends StatelessWidget {
  /// Default breakpoint names and sizes.
  static Map<String, int> _config = {
    'xs': 0,
    'sm': 576,
    'md': 768,
    'lg': 992,
    'xl': 1200,
    'xxl': 1400,
  };

  /// Creates a new default set of [breakpoints] names and sizes.
  ///
  /// A breakpoint with a width of `0` *must* be provided.
  static setBreakpoints(Map<String, int> breakpoints) {
    _checkSmallestBreakpoint(breakpoints);
    _config = breakpoints;
  }

  /// Overrides existing [breakpoints] names and sizes, adding new ones if the
  /// string names do not match.
  static patchBreakpoints(Map<String, int> breakpoints) {
    _config.addAll(breakpoints);
    // They could override the 0 sized one with a new value, so check afterward
    _checkSmallestBreakpoint(_config);
  }

  /// The breakpoints used for this instance. All names are mapped to integer
  /// sizes and ordered for simplification.
  late final SplayTreeMap<int, Widget> _breakpoints;

  /// Creates a Widget that chooses one of [breakpoints] widgets to display
  /// based on the current width of the screen.
  ///
  /// Throws an [ArgumentError] if a string name in [breakpoints] does not exist
  /// in the default set of breakpoints.
  /// Throws an [ArgumentError] if a key in [breakpoints] is not a String or
  /// int.
  ///
  /// The returned Widget is chosen based on the greatest provided size of a key
  /// in [breakpoints] that satisfies `current screen width > size`
  ///
  /// The default breakpoints are:
  /// * xs:  < 576
  /// * sm:  >= 578
  /// * md:  >= 768
  /// * lg:  >= 992
  /// * xl:  >= 1200
  /// * xxl: >= 1400
  ///
  /// A value of `Text('>= 768')` will be returned by the following call when
  /// the screen width is 800px. If the width was 1150px the result would still
  /// be `Text('>= 768')`, as no 'lg' key was provided and it defaults to the
  /// next smallest. One-off sizes can be provided as integer keys.
  /// ```
  /// ResponsiveBuilder(
  ///   breakpoints: {
  ///     'sm': Text('>= 576'),
  ///     'md': Text('>= 768'),
  ///     'xl': Text('>= 1200'),
  ///     1600: Text('>= 1600'),
  ///   },
  /// );
  /// ```
  ///
  /// To modify the default set of breakpoint names and sizes, use
  /// [setBreakpoints] or [patchBreakpoints]
  ResponsiveBuilder({
    required Map<dynamic, Widget> breakpoints,
    Key? key,
  }) : super(key: key) {
    _checkSmallestBreakpoint(breakpoints);
    this._breakpoints = _mapToSplayMap<Widget>(breakpoints);
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return _chooseBySize(width, _breakpoints);
  }
}

/// Returns a value of type [T] from the provided [breakpoints] based on the
/// current screen width.
///
/// Throws an [ArgumentError] if a string name in [breakpoints] does not exist
/// in the default set of breakpoints.
/// Throws an [ArgumentError] if a key in [breakpoints] is not a String or
/// int.
///
/// The returned [T] is chosen based on the greatest provided size of a key
/// in [breakpoints] that satisfies `current screen width > size`
///
/// A value of `Colors.red` will be returned by the following call when the
/// screen width is 800px. If the width was 1150px the result would still be
/// `Colors.red`, as no 'lg' key was provided and it defaults to the next
/// smallest. One-off sizes can be provided as integer keys.
/// ```
/// responsiveValue(context, {
///   'sm': Colors.green,
///   'md': Colors.red,
///   'xl': Colors.blue,
///   1600: Colors.purple,
/// });
/// ```
///
/// To modify the default set of breakpoint names and sizes, use
/// [setBreakpoints] or [patchBreakpoints]
T responsiveValue<T>(BuildContext context, Map<dynamic, T> breakpoints) {
  _checkSmallestBreakpoint(breakpoints);
  return _chooseBySize(
      MediaQuery.of(context).size.width, _mapToSplayMap(breakpoints));
}

/// Throws an error if [breakpoints] does not contain a 0 size breakpoint.
void _checkSmallestBreakpoint<T>(Map<dynamic, T> breakpoints) {
  breakpoints.keys.firstWhere((size) => _sizeToInt(size) == 0, orElse: () {
    throw ArgumentError('There must be a breakpoint with a size value of 0');
  });
}

/// Converts a map of breakpoint name/size keys to a SplayTreeMap of the same
/// values but with all keys set to a corresponding size.
SplayTreeMap<int, T> _mapToSplayMap<T>(Map<dynamic, T> map) {
  return SplayTreeMap.from(
    map.map((size, value) => MapEntry(_sizeToInt(size), value)),
    (a, b) {
      return _sizeToInt(a) - _sizeToInt(b);
    },
  );
}

/// Chooses a [T] in breakpoints mapping based on the [width].
T _chooseBySize<T>(double width, SplayTreeMap<int, T> breakpoints) {
  List<int> bp = breakpoints.keys.map((size) => _sizeToInt(size)).toList();

  for (int i = bp.length - 1; i >= 0; i--) {
    if (width >= bp[i]) {
      return breakpoints.values.elementAt(i);
    }
  }
  return breakpoints.values.first;
}

/// Converts size to an int value using the default breakpoints name to size
/// mappings.
int _sizeToInt(dynamic size) {
  if (size is String) {
    return ResponsiveBuilder._config[size] ??
        (throw ArgumentError('Breakpoint named \'$size\' not found'));
  } else if (size is int) {
    return size;
  } else {
    throw ArgumentError(
      '${size.runtimeType} $size is not a breakpoint. Must be type String or int',
    );
  }
}
