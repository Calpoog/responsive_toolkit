/// A set of breakpoints and associated values.
///
/// The xs breakpoint is required.
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
/// The smallest breakpoint must be 0. The value provided for the smallest
/// breakpoint must not be null.
///
/// Extend this class to create custom breakpoint names and sizes.
class BaseBreakpoints<T> {
  /// The integer widths at which layout changes will occur.
  final List<int> breakpoints = [];

  /// The values used at each breakpoint.
  final List<T?> values;

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
      throw ArgumentError('The smallest breakpoint value cannot be null.');
    }

    _combineCustomBreakpoints(breakpoints, custom);
  }

  // Combine the custom breakpoints into the existing breakpoint and values
  // lists
  _combineCustomBreakpoints(List<int> bps, Map<int, T>? custom) {
    breakpoints.addAll(bps);
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

  /// Returns a new [BaseBreakpoints] with its [values] mapped to a new type.
  BaseBreakpoints<V> map<V>(V Function(T?) f) {
    return BaseBreakpoints(
      breakpoints: breakpoints,
      values: values.map<V>((v) => f(v)).toList(),
    );
  }

  /// Chooses a value based on which of [breakpoints] is satisfied by [width].
  T choose(double width) {
    for (int i = breakpoints.length - 1; i >= 0; i--) {
      if (width >= breakpoints[i] && values[i] != null) {
        // It's been checked above that the value is non-null
        return values[i]!;
      }
    }
    // it is enforced that the smallest breakpoint Widget/value must be provided
    return values[0]!;
  }
}
