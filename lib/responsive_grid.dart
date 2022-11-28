import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:responsive_toolkit/breakpoints.dart';

/// A type of responsive column to determine layout in a [ResponsiveRow].
enum ResponsiveColumnType { span, auto, fill }

/// How [ResponsiveRow] should align objects.
///
/// Used both to align columns within a run in the main axis as well as to
/// align the runs themselves in the cross axis.
enum ResponsiveAlignment {
  /// Place the objects as close to the start of the axis as possible.
  start,

  /// Place the objects as close to the end of the axis as possible.
  end,

  /// Place the objects as close to the middle of the axis as possible.
  center,

  /// Place the free space evenly between the objects.
  spaceBetween,

  /// Place the free space evenly between the objects as well as half of that
  /// space before and after the first and last objects.
  spaceAround,

  /// Place the free space evenly between the objects as well as before and
  /// after the first and last objects.
  spaceEvenly,
}

/// How [Responsive] should align columns within a run in the cross axis.
enum ResponsiveCrossAlignment {
  /// Place the columns as close to the start of the run in the cross axis as
  /// possible.
  start,

  /// Place the columns as close to the end of the run in the cross axis as
  /// possible.
  end,

  /// Place the columns as close to the middle of the run in the cross axis as
  /// possible.
  center,

  /// Each column will be made to match in height to the tallest column before
  /// stetching. The columns will be placed to the start of the run in the cross
  /// axis.
  stretch,
}

/// A composable object allowing multiple defitions to be "stacked" where
/// defined properties override existing properties.
abstract class Composable<T> {
  /// Creates a new [T] by composing non-null properties of this onto [base]s
  /// with any completely undefined properties taken from [fallback]
  T compose(List<T> base, [T fallback]);
}

/// A collection of [ResponsiveColumn] properties intended for use with
/// `Breakpoints`.
///
/// If [span] is provided, [type] is automatically set to
/// `ResponsiveColumnType.span`.
///
/// If [span] is provided and [type] is not `ResponsiveColumnType.span`, the
/// [span] is ignored and will be treated as a [type] column.
class ResponsiveColumnConfig implements Composable<ResponsiveColumnConfig> {
  /// The type of column which controls how it fills the row
  final ResponsiveColumnType? type;

  /// The number of columns to span
  final int? span;

  /// The number of columns to offset (pushes from the left)
  final int? offset;

  /// The position of this column within [ResponsiveRow] relative to the [order]
  /// property of the other columns.
  final int? order;

  /// The alignment of this column within [ResponsiveRow] in the cross axis
  /// (vertical direction).
  final ResponsiveCrossAlignment? crossAxisAlignment;

  /// Creates a definition for the display of a [ResponsiveColumn]
  const ResponsiveColumnConfig({
    final ResponsiveColumnType? type,
    this.span,
    this.offset,
    this.order,
    this.crossAxisAlignment,
  }) : this.type = type ?? (span == null ? null : ResponsiveColumnType.span);

  /// Creates a new `ResponsiveColumnConfig` by composing non-null properties of
  /// this onto [base]s with any completely undefined properties taken from
  /// [fallback]
  @override
  ResponsiveColumnConfig compose(List<ResponsiveColumnConfig> base,
      [ResponsiveColumnConfig fallback = const ResponsiveColumnConfig(
          type: ResponsiveColumnType.auto, span: 0, offset: 0, order: 0)]) {
    List<ResponsiveColumnConfig> chain = base
      ..insert(0, fallback)
      ..add(this);
    return chain.reduce(
      (result, element) => ResponsiveColumnConfig(
        type: element.type ?? result.type,
        span: element.span ?? result.span,
        offset: element.offset ?? result.offset,
        order: element.order ?? result.order,
        crossAxisAlignment:
            element.crossAxisAlignment ?? result.crossAxisAlignment,
      ),
    );
  }

  @override
  String toString() {
    return 'ResponsiveColumnConfig(type: $type, span: $span, offset: $offset, order: $order)';
  }
}

/// A definition of a column's layout and child for use in [ResponsiveRow].
class ResponsiveColumn {
  /// The breakpoints at which the column's configurable properties can change.
  final Breakpoints<ResponsiveColumnConfig> breakpoints;

  /// The child to display in the column.
  final Widget child;

  /// Creates a consistent [ResponsiveColumn] from the multiple different ways
  /// to call via other constructors.
  ResponsiveColumn._({
    required ResponsiveColumnType type,
    int span = 0,
    int offset = 0,
    int order = 0,
    ResponsiveCrossAlignment? crossAxisAlignment,
    required this.child,
  }) : breakpoints = Breakpoints(
          xs: ResponsiveColumnConfig(
            type: type,
            span: span,
            offset: offset,
            order: order,
            crossAxisAlignment: crossAxisAlignment,
          ),
        );

  /// Creates a responsive column with its properties defined in [breakpoints].
  ResponsiveColumn(
    this.breakpoints, {
    required this.child,
  });

  /// Creates a column that takes [span] columns of space in the run of a
  /// [ResponsiveRow]
  ResponsiveColumn.span({
    required int span,
    int offset = 0,
    int order = 0,
    ResponsiveCrossAlignment? crossAxisAlignment,
    required Widget child,
  }) : this._(
          child: child,
          type: ResponsiveColumnType.span,
          offset: offset,
          order: order,
          span: span,
          crossAxisAlignment: crossAxisAlignment,
        );

  /// Creates a column that takes the space of its child in the run of a
  /// [ResponsiveRow]
  ResponsiveColumn.auto({
    int offset = 0,
    int order = 0,
    ResponsiveCrossAlignment? crossAxisAlignment,
    required Widget child,
  }) : this._(
          child: child,
          type: ResponsiveColumnType.auto,
          offset: offset,
          order: order,
          crossAxisAlignment: crossAxisAlignment,
        );

  /// Creates a column that fills the remaining space in the run of a
  /// [ResponsiveRow]
  ///
  /// A fill column won't become smaller than the `minIntrinsicWidth` of its
  /// child.
  ///
  /// If a run contains one or multiple fill columns, a column will not wrap
  /// until all fill columns have been reduced to their smallest size based on
  /// their children.
  ResponsiveColumn.fill({
    int offset = 0,
    int order = 0,
    ResponsiveCrossAlignment? crossAxisAlignment,
    required Widget child,
  }) : this._(
          child: child,
          type: ResponsiveColumnType.fill,
          offset: offset,
          order: order,
          crossAxisAlignment: crossAxisAlignment,
        );
}

/// The parent data used for row layout algorithm.
class _ResponsiveWrapParentData extends ContainerBoxParentData<RenderBox> {
  ResponsiveColumnConfig? _column;
  double _minIntrinsicWidth = 0.0;
  double _explicitWidth = 0.0;
}

/// Information about a run in a [ResponsiveRow]
class _RunMetrics {
  double mainAxisExtent = 0;
  double crossAxisExtent = 0;
  final List<RenderBox> children = [];
}

/// A series of [ResponsiveColumn] which lays out left to right, top to bottom,
/// while wrapping columns based on their responsive grid properties.
///
/// By default, when using `Breakpoints`, the layout is based on the
/// `MediaQuery.of(context).size.width`.
class ResponsiveRow extends StatelessWidget {
  /// A list of [ResponsiveColumn] objects which define the layout and children
  /// of the row.
  final List<ResponsiveColumn> columns;

  /// The number of columns the grid system supports.
  ///
  /// Defaults to 12.
  ///
  /// This is not the number of columns that [columns] can hold, but instead the
  /// number of columns the grid can support when using a [ResponsiveColumn]'s
  /// [span] property and type.
  final int maxColumns;

  /// How the columns within a run should be placed in the main axis.
  ///
  /// For example, if [alignment] is [ResponsiveAlignment.center], the columns in
  /// each run are grouped together in the center of their run in the main axis.
  ///
  /// Defaults to [ResponsiveAlignment.start].
  ///
  /// See also:
  ///
  ///  * [runAlignment], which controls how the runs are placed relative to each
  ///    other in the cross axis.
  ///  * [crossAxisAlignment], which controls how the columns within each run
  ///    are placed relative to each other in the cross axis.
  final ResponsiveAlignment alignment;

  /// How much space to place between columns in a run in the main axis.
  ///
  /// For example, if [spacing] is 10.0, the columns will be spaced at least
  /// 10.0 logical pixels apart in the main axis.
  ///
  /// If there is additional free space in a run (e.g., because the row has a
  /// minimum size that is not filled or because some runs are longer than
  /// others), the additional free space will be allocated according to the
  /// [alignment].
  ///
  /// Defaults to 0.0.
  final double spacing;

  /// How the runs themselves should be placed in the cross axis.
  ///
  /// For example, if [runAlignment] is [ResponsiveAlignment.center], the runs are
  /// grouped together in the center of the overall [ResponsiveRow] in the cross
  /// axis.
  ///
  /// Defaults to [ResponsiveAlignment.start].
  ///
  /// See also:
  ///
  ///  * [alignment], which controls how the columns within each run are placed
  ///    relative to each other in the main axis.
  ///  * [crossAxisAlignment], which controls how the columns within each run
  ///    are placed relative to each other in the cross axis.
  final ResponsiveAlignment runAlignment;

  /// How much space to place between the runs themselves in the cross axis.
  ///
  /// For example, if [runSpacing] is 10.0, the runs will be spaced at least
  /// 10.0 logical pixels apart in the cross axis.
  ///
  /// If there is additional free space (e.g., because the [ResponsiveRow] has a
  /// minimum size that is not filled), the additional free space will be
  /// allocated according to the [runAlignment].
  ///
  /// Defaults to 0.0.
  final double runSpacing;

  /// How the columns within a run should be aligned relative to each other in
  /// the cross axis.
  ///
  /// For example, if this is set to [ResponsiveCrossAlignment.end], then the
  /// children within each run will have their bottom edges aligned to the
  /// bottom edge of the run.
  ///
  /// Defaults to [ResponsiveCrossAlignment.start].
  ///
  /// See also:
  ///
  ///  * [alignment], which controls how the columns within each run are placed
  ///    relative to each other in the main axis.
  ///  * [runAlignment], which controls how the runs are placed relative to each
  ///    other in the cross axis.
  final ResponsiveCrossAlignment crossAxisAlignment;

  /// How content that overflows the row is clipped.
  ///
  /// Defaults to `Clip.none`.
  ///
  /// e.g. if the constraints to the row force it smaller than the total height
  /// of all its runs, some columns will overflow the bottom of the row.
  final Clip clipBehavior;

  /// Whether to choose breakpoints for its columns based on incoming
  /// constraints.
  ///
  /// Defaults to `false` (uses `MediaQuery.of(context).size.width`).
  final bool breakOnConstraints;

  /// Creates a row of responsive columns
  ///
  /// [maxColumns] must be greater than 1.
  ResponsiveRow({
    Key? key,
    required this.columns,
    this.alignment = ResponsiveAlignment.start,
    this.spacing = 0.0,
    this.runAlignment = ResponsiveAlignment.start,
    this.runSpacing = 0.0,
    this.crossAxisAlignment = ResponsiveCrossAlignment.start,
    this.clipBehavior = Clip.none,
    this.breakOnConstraints = false,
    this.maxColumns = 12,
  }) : assert(maxColumns > 1);

  @override
  Widget build(BuildContext context) {
    return _ResponsiveRow(
      screenSize: breakOnConstraints ? null : MediaQuery.of(context).size,
      columns: columns,
      alignment: alignment,
      spacing: spacing,
      runAlignment: runAlignment,
      runSpacing: runSpacing,
      crossAxisAlignment: crossAxisAlignment,
      clipBehavior: clipBehavior,
      maxColumns: maxColumns,
    );
  }
}

/// The true responsive row containing layout logic to size based on children.
class _ResponsiveRow extends MultiChildRenderObjectWidget {
  final List<ResponsiveColumn> columns;
  final ResponsiveAlignment alignment;
  final double spacing;
  final ResponsiveAlignment runAlignment;
  final double runSpacing;
  final ResponsiveCrossAlignment crossAxisAlignment;
  final Clip clipBehavior;
  final Size? screenSize;
  final int maxColumns;

  _ResponsiveRow({
    Key? key,
    required this.columns,
    this.screenSize,
    this.maxColumns = 12,
    this.alignment = ResponsiveAlignment.start,
    this.spacing = 0.0,
    this.runAlignment = ResponsiveAlignment.start,
    this.runSpacing = 0.0,
    this.crossAxisAlignment = ResponsiveCrossAlignment.start,
    this.clipBehavior = Clip.none,
  }) : super(key: key, children: columns.map((col) => col.child).toList());

  @override
  _ResponsiveRenderWrap createRenderObject(BuildContext context) {
    return _ResponsiveRenderWrap(
      screenSize: screenSize,
      maxColumns: maxColumns,
      columns: columns,
      alignment: alignment,
      spacing: spacing,
      runAlignment: runAlignment,
      runSpacing: runSpacing,
      crossAxisAlignment: crossAxisAlignment,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _ResponsiveRenderWrap renderObject) {
    renderObject
      ..screenSize = screenSize
      ..maxColumns = maxColumns
      ..columns = columns
      ..alignment = alignment
      ..spacing = spacing
      ..runAlignment = runAlignment
      ..runSpacing = runSpacing
      ..crossAxisAlignment = crossAxisAlignment
      ..clipBehavior = clipBehavior;
  }
}

/// A heavily modified version of wrap to support fill columns, breakpoints,
/// and 12*-column grid.
class _ResponsiveRenderWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ResponsiveWrapParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ResponsiveWrapParentData> {
  /// Creates a wrap render object.
  ///
  /// By default, the wrap layout is horizontal and both the children and the
  /// runs are aligned to the start.
  _ResponsiveRenderWrap({
    required List<ResponsiveColumn> columns,
    Size? screenSize,
    required int maxColumns,
    List<RenderBox>? children,
    ResponsiveAlignment alignment = ResponsiveAlignment.start,
    double spacing = 0.0,
    ResponsiveAlignment runAlignment = ResponsiveAlignment.start,
    double runSpacing = 0.0,
    ResponsiveCrossAlignment crossAxisAlignment =
        ResponsiveCrossAlignment.start,
    Clip clipBehavior = Clip.none,
  })  : _maxColumns = maxColumns,
        _columns = columns,
        _alignment = alignment,
        _spacing = spacing,
        _runAlignment = runAlignment,
        _runSpacing = runSpacing,
        _crossAxisAlignment = crossAxisAlignment,
        _clipBehavior = clipBehavior {
    _screenSize = screenSize ?? constraints.biggest;
    addAll(children);
  }

  int get maxColumns => _maxColumns;
  int _maxColumns;
  set maxColumns(int value) {
    if (_maxColumns == value) return;
    _maxColumns = value;
    markNeedsLayout();
  }

  Size get screenSize => _screenSize;
  late Size _screenSize;
  set screenSize(Size? value) {
    if (_screenSize == value) return;
    _screenSize = value ?? constraints.biggest;
    markNeedsLayout();
  }

  List<ResponsiveColumn> get columns => _columns;
  List<ResponsiveColumn> _columns;
  set columns(List<ResponsiveColumn> value) {
    if (_columns == value) return;
    _columns = value;
    markNeedsLayout();
  }

  ResponsiveAlignment get alignment => _alignment;
  ResponsiveAlignment _alignment;
  set alignment(ResponsiveAlignment value) {
    if (_alignment == value) return;
    _alignment = value;
    markNeedsLayout();
  }

  double get spacing => _spacing;
  double _spacing;
  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  ResponsiveAlignment get runAlignment => _runAlignment;
  ResponsiveAlignment _runAlignment;
  set runAlignment(ResponsiveAlignment value) {
    if (_runAlignment == value) return;
    _runAlignment = value;
    markNeedsLayout();
  }

  double get runSpacing => _runSpacing;
  double _runSpacing;
  set runSpacing(double value) {
    if (_runSpacing == value) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  ResponsiveCrossAlignment get crossAxisAlignment => _crossAxisAlignment;
  ResponsiveCrossAlignment _crossAxisAlignment;
  set crossAxisAlignment(ResponsiveCrossAlignment value) {
    if (_crossAxisAlignment == value) return;
    _crossAxisAlignment = value;
    markNeedsLayout();
  }

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.none;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ResponsiveWrapParentData)
      child.parentData = _ResponsiveWrapParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    double width = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      width = math.max(width, child.getMinIntrinsicWidth(double.infinity));
      child = childAfter(child);
    }
    return width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    double width = 0.0;
    RenderBox? child = firstChild;
    while (child != null) {
      width += child.getMaxIntrinsicWidth(double.infinity);
      child = childAfter(child);
    }
    return width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return computeDryLayout(BoxConstraints(maxWidth: width)).height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return computeDryLayout(BoxConstraints(maxWidth: width)).height;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  double _getMainAxisExtent(Size childSize) {
    return childSize.width;
  }

  double _getCrossAxisExtent(Size childSize) {
    return childSize.height;
  }

  double _getChildCrossAxisOffset(ResponsiveColumnConfig column,
      double runCrossAxisExtent, double childCrossAxisExtent) {
    final double freeSpace = runCrossAxisExtent - childCrossAxisExtent;
    final ResponsiveCrossAlignment align =
        column.crossAxisAlignment ?? crossAxisAlignment;
    switch (align) {
      case ResponsiveCrossAlignment.start:
      case ResponsiveCrossAlignment.stretch:
        return 0.0;
      case ResponsiveCrossAlignment.end:
        return freeSpace;
      case ResponsiveCrossAlignment.center:
        return freeSpace / 2.0;
    }
  }

  double _getWidth(int size, double mainAxisLimit) {
    return size / maxColumns * mainAxisLimit;
  }

  _ResponsiveWrapParentData _getParentData(RenderBox child) {
    return child.parentData as _ResponsiveWrapParentData;
  }

  _resetParentData(RenderBox child) {
    final parentData = child.parentData as _ResponsiveWrapParentData;
    parentData._explicitWidth = 0.0;
    parentData._minIntrinsicWidth = 0.0;
  }

  bool _hasVisualOverflow = false;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _performLayout(dry: true)!;
  }

  @override
  void performLayout() {
    _performLayout();
  }

  Size _layoutChild(RenderBox child, BoxConstraints constraints,
      {bool dry = false}) {
    late final Size childSize;
    if (dry) {
      childSize = child.getDryLayout(constraints);
    } else {
      child.layout(constraints, parentUsesSize: true);
      childSize = child.size;
    }
    return childSize;
  }

  Size? _performLayout({bool dry = false}) {
    final BoxConstraints constraints = this.constraints;
    late final Size size;

    _hasVisualOverflow = false;
    RenderBox? child = firstChild;
    if (child == null) {
      size = constraints.smallest;
      if (!dry) {
        this.size = size;
      }
      return size;
    }

    final double spacing = this.spacing;
    final double runSpacing = this.runSpacing;
    final List<_RunMetrics> runMetrics = [_RunMetrics()];

    double mainAxisLimit = constraints.maxWidth + spacing;
    double mainAxisExtent = 0.0;
    double crossAxisExtent = 0.0;

    int childIndex = 0;
    // Choose breakpoints up front because order changes layout
    while (child != null) {
      final childParentData = _getParentData(child);
      childParentData._column =
          columns.elementAt(childIndex).breakpoints.choose(_screenSize.width);
      assert(
          childParentData._column!.span! >= 0 &&
              childParentData._column!.span! <= maxColumns,
          'Column with config ${childParentData._column} has a span outside the range [0, $maxColumns]');
      assert(
          childParentData._column!.offset! >= 0 &&
              childParentData._column!.offset! < maxColumns,
          'Column with config ${childParentData._column} has an offset outside the range [0, ${maxColumns - 1}]');
      child = childParentData.nextSibling;
      childIndex++;
    }

    getChildrenAsList()
      ..sort((a, b) =>
          _getParentData(a)._column!.order! - _getParentData(b)._column!.order!)
      ..forEach((child) {
        _resetParentData(child);
        final _ResponsiveWrapParentData childParentData = _getParentData(child);
        final ResponsiveColumnConfig column = childParentData._column!;

        // The buffer space (offset and spacing) included for fit calculations
        double buffer = _getWidth(column.offset!, mainAxisLimit) + spacing;

        double childMainAxisExtent = 0.0;
        double childCrossAxisExtent = 0.0;
        if (column.type == ResponsiveColumnType.fill) {
          childMainAxisExtent =
              child.getMinIntrinsicWidth(constraints.maxHeight);
          childParentData._explicitWidth = childMainAxisExtent;
          // Remember the min width for later to redistribute free space
          childParentData._minIntrinsicWidth = childMainAxisExtent;
          // For the purposes of "what fits" in the run, the buffer is included
          childMainAxisExtent += buffer;
        } else {
          late final Size childSize;
          if (column.type == ResponsiveColumnType.auto) {
            // Auto columns are constrained to a full run width always
            childSize = _layoutChild(
                child, BoxConstraints(maxWidth: constraints.maxWidth - buffer),
                dry: dry);
            childParentData._explicitWidth = _getMainAxisExtent(childSize);
            childMainAxisExtent = childParentData._explicitWidth + buffer;
          }
          // A span column is always the size it specifies (it's guaranteed to be < run width)
          else {
            childMainAxisExtent =
                _getWidth(column.span!, mainAxisLimit) - spacing;
            childParentData._explicitWidth = childMainAxisExtent;
            childSize = _layoutChild(
                child, BoxConstraints.tightFor(width: childMainAxisExtent),
                dry: dry);
            childMainAxisExtent += buffer;
          }
          childCrossAxisExtent = _getCrossAxisExtent(childSize);
        }

        // Save some data for later on the child
        childParentData._column = column;

        // A column runs over the remaining space
        if ((runMetrics.last.mainAxisExtent + childMainAxisExtent)
                .roundToDouble() >
            mainAxisLimit.roundToDouble()) {
          _layoutFillColumns(runMetrics.last, mainAxisLimit, dry: dry);
          mainAxisExtent =
              math.max(mainAxisExtent, runMetrics.last.mainAxisExtent);
          crossAxisExtent += runMetrics.last.crossAxisExtent + runSpacing;
          runMetrics.add(_RunMetrics());
        }

        // Update run metrics
        runMetrics.last
          ..mainAxisExtent += childMainAxisExtent
          ..crossAxisExtent =
              math.max(runMetrics.last.crossAxisExtent, childCrossAxisExtent)
          ..children.add(child);
      });

    _layoutFillColumns(runMetrics.last, mainAxisLimit, dry: dry);
    mainAxisExtent = math.max(mainAxisExtent, runMetrics.last.mainAxisExtent);
    crossAxisExtent += runMetrics.last.crossAxisExtent;

    final int runCount = runMetrics.length;

    size = constraints.constrain(Size(mainAxisExtent, crossAxisExtent));
    if (dry) {
      return size;
    } else {
      this.size = size;
    }

    double containerMainAxisExtent = size.width;
    double containerCrossAxisExtent = size.height;

    _hasVisualOverflow = containerMainAxisExtent < mainAxisExtent ||
        containerCrossAxisExtent < crossAxisExtent;

    final double crossAxisFreeSpace =
        math.max(0.0, containerCrossAxisExtent - crossAxisExtent);
    double runLeadingSpace = 0.0;
    double runBetweenSpace = 0.0;
    switch (runAlignment) {
      case ResponsiveAlignment.start:
        break;
      case ResponsiveAlignment.end:
        runLeadingSpace = crossAxisFreeSpace;
        break;
      case ResponsiveAlignment.center:
        runLeadingSpace = crossAxisFreeSpace / 2.0;
        break;
      case ResponsiveAlignment.spaceBetween:
        runBetweenSpace =
            runCount > 1 ? crossAxisFreeSpace / (runCount - 1) : 0.0;
        break;
      case ResponsiveAlignment.spaceAround:
        runBetweenSpace = crossAxisFreeSpace / runCount;
        runLeadingSpace = runBetweenSpace / 2.0;
        break;
      case ResponsiveAlignment.spaceEvenly:
        runBetweenSpace = crossAxisFreeSpace / (runCount + 1);
        runLeadingSpace = runBetweenSpace;
        break;
    }

    runBetweenSpace += runSpacing;
    double crossAxisOffset = runLeadingSpace;

    for (int i = 0; i < runCount; ++i) {
      final _RunMetrics metrics = runMetrics[i];
      final double runMainAxisExtent = metrics.mainAxisExtent;
      final double runCrossAxisExtent = metrics.crossAxisExtent;
      final int childCount = metrics.children.length;

      final double mainAxisFreeSpace =
          math.max(0.0, containerMainAxisExtent - runMainAxisExtent + spacing);
      double childLeadingSpace = 0.0;
      double childBetweenSpace = 0.0;

      switch (alignment) {
        case ResponsiveAlignment.start:
          break;
        case ResponsiveAlignment.end:
          childLeadingSpace = mainAxisFreeSpace;
          break;
        case ResponsiveAlignment.center:
          childLeadingSpace = mainAxisFreeSpace / 2.0;
          break;
        case ResponsiveAlignment.spaceBetween:
          childBetweenSpace =
              childCount > 1 ? mainAxisFreeSpace / (childCount - 1) : 0.0;
          break;
        case ResponsiveAlignment.spaceAround:
          childBetweenSpace = mainAxisFreeSpace / childCount;
          childLeadingSpace = childBetweenSpace / 2.0;
          break;
        case ResponsiveAlignment.spaceEvenly:
          childBetweenSpace = mainAxisFreeSpace / (childCount + 1);
          childLeadingSpace = childBetweenSpace;
          break;
      }

      childBetweenSpace += spacing;
      double childMainPosition = childLeadingSpace;

      metrics.children.forEach((child) {
        final _ResponsiveWrapParentData childParentData = _getParentData(child);
        final ResponsiveColumnConfig column = childParentData._column!;
        final double childMainAxisOffset =
            _getWidth(childParentData._column!.offset!, mainAxisLimit);
        final double childCrossAxisExtent = _getCrossAxisExtent(child.size);
        final double childCrossAxisOffset = _getChildCrossAxisOffset(
            column, runCrossAxisExtent, childCrossAxisExtent);
        childParentData.offset = Offset(
          childMainPosition + childMainAxisOffset,
          crossAxisOffset + childCrossAxisOffset,
        );
        childMainPosition += childParentData._explicitWidth +
            childMainAxisOffset +
            childBetweenSpace;

        // If the cross axis is supposed to stretch – re-layout children that aren't full height
        final align = column.crossAxisAlignment ?? crossAxisAlignment;
        if (align == ResponsiveCrossAlignment.stretch &&
            childCrossAxisExtent < runCrossAxisExtent) {
          child.layout(BoxConstraints.tightFor(
              width: _getMainAxisExtent(child.size),
              height: runCrossAxisExtent));
        }
      });

      crossAxisOffset += runCrossAxisExtent + runBetweenSpace;
    }

    return size;
  }

  _layoutFillColumns(_RunMetrics run, double mainAxisLimit,
      {bool dry = false}) {
    final fillColumns = run.children
        .where((column) =>
            _getParentData(column)._column!.type == ResponsiveColumnType.fill)
        .toList();

    // Fill columns in a single run are allowed to be different widths if their
    // min width prevents one from getting smaller
    // Remaining gets space gets distributed from smallest to largest until they
    // are all equal width, then distributed further evenly among them.

    if (fillColumns.length > 0) {
      double freeSpace = mainAxisLimit - run.mainAxisExtent;

      // Space distribution logic only matters when there's more than one in the row
      if (fillColumns.length > 1) {
        final List<RenderBox> sorted = List.from(fillColumns);
        sorted.sort((a, b) {
          final double diff = _getParentData(a)._minIntrinsicWidth -
              _getParentData(b)._minIntrinsicWidth;

          return diff < 0 ? -1 : (diff > 0 ? 1 : 0);
        });

        for (int i = 0; i < sorted.length; i++) {
          final double a = _getParentData(sorted[i])._minIntrinsicWidth;
          final double b = i == sorted.length - 1
              ? double.infinity
              : _getParentData(sorted[i + 1])._minIntrinsicWidth;
          final double diff = b - a;
          final int multiplier = i + 1;
          final double adj = math.min(diff * multiplier, freeSpace);

          for (int j = i; j >= 0; j--) {
            final childParentData = _getParentData(sorted[j]);
            childParentData._explicitWidth += adj / multiplier;
          }
          freeSpace -= adj;

          if (freeSpace == 0) break;
        }
      } else {
        _getParentData(fillColumns.first)._explicitWidth += freeSpace;
      }

      fillColumns.forEach((child) {
        final Size childSize = _layoutChild(
            child,
            BoxConstraints.tightFor(
                width: _getParentData(child)._explicitWidth),
            dry: dry);
        // Update run metrics now that a child in the run was sized
        run.crossAxisExtent =
            math.max(run.crossAxisExtent, _getCrossAxisExtent(childSize));
      });
      // The run main axis is always full size because it had at least one fill column
      run.mainAxisExtent = mainAxisLimit;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow && clipBehavior != Clip.none) {
      _clipRectLayer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        defaultPaint,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer,
      );
    } else {
      _clipRectLayer = null;
      defaultPaint(context, offset);
    }
  }

  ClipRectLayer? _clipRectLayer;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<ResponsiveColumn>('columns', columns));
    properties.add(EnumProperty<ResponsiveAlignment>('alignment', alignment));
    properties.add(DoubleProperty('spacing', spacing));
    properties
        .add(EnumProperty<ResponsiveAlignment>('runAlignment', runAlignment));
    properties.add(DoubleProperty('runSpacing', runSpacing));
    properties.add(DoubleProperty('crossAxisAlignment', runSpacing));
  }
}
