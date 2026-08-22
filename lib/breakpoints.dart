import 'dart:collection';

import 'responsive_grid.dart';

/// A set of breakpoints and associated values.
///
/// The xs breakpoint is required.
class Breakpoints<T> extends BaseBreakpoints<T> {
  Breakpoints({required T xs, T? sm, T? md, T? lg, T? xl, T? xxl, super.custom})
    : super(
        breakpoints: const [0, 576, 768, 992, 1200, 1400],
        values: [xs, sm, md, lg, xl, xxl],
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
  late final List<int> breakpoints;

  /// The values used at each breakpoint.
  late final List<T?> values;

  /// Creates a new set of breakpoints and associated values.
  BaseBreakpoints({
    required List<int> breakpoints,
    required List<T?> values,
    Map<int, T>? custom,
  }) {
    if (breakpoints.isEmpty || values.isEmpty) {
      throw ArgumentError('Breakpoints and values cannot be empty.');
    }
    if (breakpoints.length != values.length) {
      throw ArgumentError('Breakpoints and values must have the same length.');
    }
    if (breakpoints.first != 0) {
      throw ArgumentError('The smallest breakpoint width must be 0.');
    }
    if (values.first == null) {
      throw ArgumentError('The smallest breakpoint value cannot be null.');
    }
    for (var index = 1; index < breakpoints.length; index++) {
      if (breakpoints[index] <= breakpoints[index - 1]) {
        throw ArgumentError('Breakpoint widths must be strictly increasing.');
      }
    }

    final combined = <int, T?>{
      for (var index = 0; index < breakpoints.length; index++)
        breakpoints[index]: values[index],
    };
    if (custom != null) {
      for (final entry in custom.entries) {
        if (entry.key < 0) {
          throw ArgumentError.value(
            entry.key,
            'custom',
            'Breakpoint widths cannot be negative.',
          );
        }
        combined[entry.key] = entry.value;
      }
    }

    final widths = combined.keys.toList()..sort();
    final composedValues = widths.map((width) => combined[width]).toList();
    for (var index = 0; index < composedValues.length; index++) {
      final value = composedValues[index];
      if (value is Composable<T>) {
        composedValues[index] = value.compose(
          composedValues.take(index).whereType<T>().toList(growable: false),
        );
      }
    }

    this.breakpoints = UnmodifiableListView(widths);
    this.values = UnmodifiableListView(composedValues);
  }

  /// Returns a new [BaseBreakpoints] with its [values] mapped to a new type.
  BaseBreakpoints<V> map<V>(V Function(T?) f) {
    return BaseBreakpoints<V>(
      breakpoints: breakpoints,
      values: values.map(f).toList(growable: false),
    );
  }

  /// Chooses a value based on which of [breakpoints] is satisfied by [width].
  T choose(double width) {
    if (width.isNaN) {
      throw ArgumentError.value(width, 'width', 'Width cannot be NaN.');
    }
    for (var index = breakpoints.length - 1; index >= 0; index--) {
      if (width >= breakpoints[index] && values[index] != null) {
        return values[index] as T;
      }
    }
    return values.first as T;
  }
}
