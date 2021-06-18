import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:responsive_toolkit/breakpoints.dart';

enum ResponsiveColumnType { span, auto, fill }

/// A composable object allowing multiple defitions to be "stacked" where
/// defined properties override exising properties.
abstract class Composable<T> {
  /// Creates a new [T] by composing non-null properties of this onto [base]s
  /// with any completely undefined properties taken from [fallback]
  T compose(List<T> base, [T fallback]);
}

class ResponsiveColumnConfig implements Composable<ResponsiveColumnConfig> {
  final ResponsiveColumnType? type;
  final int? span;
  final int? offset;
  final int? order;

  const ResponsiveColumnConfig({
    final ResponsiveColumnType? type,
    this.span,
    this.offset,
    this.order,
  }) : this.type = type ?? (span == null ? null : ResponsiveColumnType.span);

  @override
  ResponsiveColumnConfig compose(List<ResponsiveColumnConfig> base,
      [ResponsiveColumnConfig fallback =
          const ResponsiveColumnConfig(type: ResponsiveColumnType.auto, span: 0, offset: 0, order: 0)]) {
    List<ResponsiveColumnConfig> chain = base
      ..insert(0, fallback)
      ..add(this);
    return chain.reduce((result, element) => ResponsiveColumnConfig(
          type: element.type ?? result.type,
          span: element.span ?? result.span,
          offset: element.offset ?? result.offset,
          order: element.order ?? result.order,
        ));
  }

  @override
  String toString() {
    return 'ResponsiveColumnConfig(type: $type, span: $span, offset: $offset, order: $order)';
  }
}

class ResponsiveColumn {
  final Breakpoints<ResponsiveColumnConfig> breakpoints;
  final Widget child;

  ResponsiveColumn._({
    required ResponsiveColumnType type,
    int span = 0,
    int offset = 0,
    int order = 0,
    required this.child,
  }) : breakpoints = Breakpoints(
          xs: ResponsiveColumnConfig(
            type: type,
            span: span,
            offset: offset,
            order: order,
          ),
        );

  ResponsiveColumn(
    this.breakpoints, {
    required this.child,
  });

  ResponsiveColumn.span({
    required int span,
    int offset = 0,
    int order = 0,
    required Widget child,
  }) : this._(
          child: child,
          type: ResponsiveColumnType.span,
          offset: offset,
          order: order,
          span: span,
        );

  ResponsiveColumn.auto({
    int offset = 0,
    int order = 0,
    required Widget child,
  }) : this._(
          child: child,
          type: ResponsiveColumnType.auto,
          offset: offset,
          order: order,
        );

  ResponsiveColumn.fill({
    int offset = 0,
    int order = 0,
    required Widget child,
  }) : this._(
          child: child,
          type: ResponsiveColumnType.fill,
          offset: offset,
          order: order,
        );
}

class _ResponsiveWrapParentData extends ContainerBoxParentData<RenderBox> {
  ResponsiveColumnConfig? _column;
  double _minIntrinsicWidth = 0.0;
  double _adjustedWidth = 0.0;
}

class _RunMetrics {
  double mainAxisExtent = 0;
  double crossAxisExtent = 0;
  final List<RenderBox> children = [];
}

class ResponsiveRow extends StatelessWidget {
  final List<ResponsiveColumn> columns;
  final WrapAlignment alignment;
  final double spacing;
  final WrapAlignment runAlignment;
  final double runSpacing;
  final WrapCrossAlignment crossAxisAlignment;
  final Clip clipBehavior;

  ResponsiveRow({
    Key? key,
    required this.columns,
    this.alignment = WrapAlignment.start,
    this.spacing = 0.0,
    this.runAlignment = WrapAlignment.start,
    this.runSpacing = 0.0,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    return _ResponsiveRow(
      screenSize: MediaQuery.of(context).size,
      columns: columns,
      alignment: alignment,
      spacing: spacing,
      runAlignment: runAlignment,
      runSpacing: runSpacing,
      crossAxisAlignment: crossAxisAlignment,
      clipBehavior: clipBehavior,
    );
  }
}

class _ResponsiveRow extends MultiChildRenderObjectWidget {
  final List<ResponsiveColumn> columns;
  final WrapAlignment alignment;
  final double spacing;
  final WrapAlignment runAlignment;
  final double runSpacing;
  final WrapCrossAlignment crossAxisAlignment;
  final Clip clipBehavior;
  final Size screenSize;

  _ResponsiveRow({
    Key? key,
    required this.columns,
    required this.screenSize,
    this.alignment = WrapAlignment.start,
    this.spacing = 0.0,
    this.runAlignment = WrapAlignment.start,
    this.runSpacing = 0.0,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.clipBehavior = Clip.none,
  }) : super(key: key, children: columns.map((col) => col.child).toList());

  @override
  _ResponsiveRenderWrap createRenderObject(BuildContext context) {
    return _ResponsiveRenderWrap(
      screenSize: screenSize,
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
  void updateRenderObject(BuildContext context, _ResponsiveRenderWrap renderObject) {
    renderObject
      ..screenSize = screenSize
      ..columns = columns
      ..alignment = alignment
      ..spacing = spacing
      ..runAlignment = runAlignment
      ..runSpacing = runSpacing
      ..crossAxisAlignment = crossAxisAlignment
      ..clipBehavior = clipBehavior;
  }
}

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
    required Size screenSize,
    List<RenderBox>? children,
    WrapAlignment alignment = WrapAlignment.start,
    double spacing = 0.0,
    WrapAlignment runAlignment = WrapAlignment.start,
    double runSpacing = 0.0,
    WrapCrossAlignment crossAxisAlignment = WrapCrossAlignment.start,
    Clip clipBehavior = Clip.none,
  })  : _screenSize = screenSize,
        _columns = columns,
        _alignment = alignment,
        _spacing = spacing,
        _runAlignment = runAlignment,
        _runSpacing = runSpacing,
        _crossAxisAlignment = crossAxisAlignment,
        _clipBehavior = clipBehavior {
    addAll(children);
  }

  Size get screenSize => _screenSize;
  Size _screenSize;
  set screenSize(Size value) {
    if (_screenSize == value) return;
    _screenSize = value;
    markNeedsLayout();
  }

  List<ResponsiveColumn> get columns => _columns;
  List<ResponsiveColumn> _columns;
  set columns(List<ResponsiveColumn> value) {
    if (_columns == value) return;
    _columns = value;
    markNeedsLayout();
  }

  /// How the children within a run should be placed in the main axis.
  ///
  /// For example, if [alignment] is [WrapAlignment.center], the children in
  /// each run are grouped together in the center of their run in the main axis.
  ///
  /// Defaults to [WrapAlignment.start].
  ///
  /// See also:
  ///
  ///  * [runAlignment], which controls how the runs are placed relative to each
  ///    other in the cross axis.
  ///  * [crossAxisAlignment], which controls how the children within each run
  ///    are placed relative to each other in the cross axis.
  WrapAlignment get alignment => _alignment;
  WrapAlignment _alignment;
  set alignment(WrapAlignment value) {
    if (_alignment == value) return;
    _alignment = value;
    markNeedsLayout();
  }

  /// How much space to place between children in a run in the main axis.
  ///
  /// For example, if [spacing] is 10.0, the children will be spaced at least
  /// 10.0 logical pixels apart in the main axis.
  ///
  /// If there is additional free space in a run (e.g., because the wrap has a
  /// minimum size that is not filled or because some runs are longer than
  /// others), the additional free space will be allocated according to the
  /// [alignment].
  ///
  /// Defaults to 0.0.
  double get spacing => _spacing;
  double _spacing;
  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  /// How the runs themselves should be placed in the cross axis.
  ///
  /// For example, if [runAlignment] is [WrapAlignment.center], the runs are
  /// grouped together in the center of the overall [RenderWrap] in the cross
  /// axis.
  ///
  /// Defaults to [WrapAlignment.start].
  ///
  /// See also:
  ///
  ///  * [alignment], which controls how the children within each run are placed
  ///    relative to each other in the main axis.
  ///  * [crossAxisAlignment], which controls how the children within each run
  ///    are placed relative to each other in the cross axis.
  WrapAlignment get runAlignment => _runAlignment;
  WrapAlignment _runAlignment;
  set runAlignment(WrapAlignment value) {
    if (_runAlignment == value) return;
    _runAlignment = value;
    markNeedsLayout();
  }

  /// How much space to place between the runs themselves in the cross axis.
  ///
  /// For example, if [runSpacing] is 10.0, the runs will be spaced at least
  /// 10.0 logical pixels apart in the cross axis.
  ///
  /// If there is additional free space in the overall [RenderWrap] (e.g.,
  /// because the wrap has a minimum size that is not filled), the additional
  /// free space will be allocated according to the [runAlignment].
  ///
  /// Defaults to 0.0.
  double get runSpacing => _runSpacing;
  double _runSpacing;
  set runSpacing(double value) {
    if (_runSpacing == value) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  /// How the children within a run should be aligned relative to each other in
  /// the cross axis.
  ///
  /// For example, if this is set to [WrapCrossAlignment.end], and the
  /// [direction] is [Axis.horizontal], then the children within each
  /// run will have their bottom edges aligned to the bottom edge of the run.
  ///
  /// Defaults to [WrapCrossAlignment.start].
  ///
  /// See also:
  ///
  ///  * [alignment], which controls how the children within each run are placed
  ///    relative to each other in the main axis.
  ///  * [runAlignment], which controls how the runs are placed relative to each
  ///    other in the cross axis.
  WrapCrossAlignment get crossAxisAlignment => _crossAxisAlignment;
  WrapCrossAlignment _crossAxisAlignment;
  set crossAxisAlignment(WrapCrossAlignment value) {
    if (_crossAxisAlignment == value) return;
    _crossAxisAlignment = value;
    markNeedsLayout();
  }

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
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
    if (child.parentData is! _ResponsiveWrapParentData) child.parentData = _ResponsiveWrapParentData();
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

  double _getChildCrossAxisOffset(double runCrossAxisExtent, double childCrossAxisExtent) {
    final double freeSpace = runCrossAxisExtent - childCrossAxisExtent;
    switch (crossAxisAlignment) {
      case WrapCrossAlignment.start:
        return 0.0;
      case WrapCrossAlignment.end:
        return freeSpace;
      case WrapCrossAlignment.center:
        return freeSpace / 2.0;
    }
  }

  double _getWidth(int size, double mainAxisLimit) {
    return size / 12 * mainAxisLimit;
  }

  _ResponsiveWrapParentData _getParentData(RenderBox child) {
    return child.parentData as _ResponsiveWrapParentData;
  }

  _resetParentData(RenderBox child) {
    final parentData = child.parentData as _ResponsiveWrapParentData;
    parentData._adjustedWidth = 0.0;
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

  Size _layoutChild(RenderBox child, BoxConstraints constraints, {bool dry = false}) {
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

    _hasVisualOverflow = false;
    RenderBox? child = firstChild;
    if (child == null) {
      size = constraints.smallest;
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
      childParentData._column = columns.elementAt(childIndex).breakpoints.choose(_screenSize.width);
      child = childParentData.nextSibling;
      childIndex++;
    }

    getChildrenAsList()
      ..sort((a, b) => _getParentData(a)._column!.order! - _getParentData(b)._column!.order!)
      ..forEach((child) {
        _resetParentData(child);
        final ResponsiveColumnConfig column = _getParentData(child)._column!;

        // The buffer space (offset and spacing) included for fit calculations
        double buffer = _getWidth(column.offset!, mainAxisLimit) + spacing;

        double childMainAxisExtent = 0.0;
        double childCrossAxisExtent = 0.0;
        if (column.type == ResponsiveColumnType.fill) {
          childMainAxisExtent = child.getMinIntrinsicWidth(constraints.maxHeight);
          // Remember the min width for later to redistribute free space
          (child.parentData as _ResponsiveWrapParentData)._minIntrinsicWidth = childMainAxisExtent;
          // For the purposes of "what fits" in the run, the buffer is included
          childMainAxisExtent += buffer;
        } else {
          late final Size childSize;
          if (column.type == ResponsiveColumnType.auto) {
            // Auto columns are constrained to a full run width always
            childSize = _layoutChild(
              child,
              BoxConstraints(maxWidth: constraints.maxWidth - buffer),
            );
            childMainAxisExtent = _getMainAxisExtent(childSize) + buffer;
          }
          // A span column is always the size it specifies (it's guaranteed to be < run width)
          else {
            childMainAxisExtent = _getWidth(column.span!, mainAxisLimit) - spacing;
            childSize = _layoutChild(
              child,
              BoxConstraints(maxWidth: childMainAxisExtent),
            );
            childMainAxisExtent += buffer;
          }
          childCrossAxisExtent = _getCrossAxisExtent(childSize);
        }

        // Save some data for later on the child
        final _ResponsiveWrapParentData childParentData = child.parentData! as _ResponsiveWrapParentData;
        childParentData._column = column;

        // A column runs over the remaining space
        if ((runMetrics.last.mainAxisExtent + childMainAxisExtent).roundToDouble() > mainAxisLimit) {
          _layoutFillColumns(runMetrics.last, mainAxisLimit, dry: dry);
          mainAxisExtent = math.max(mainAxisExtent, runMetrics.last.mainAxisExtent);
          crossAxisExtent += runMetrics.last.crossAxisExtent + runSpacing;
          runMetrics.add(_RunMetrics());
        }

        // Update run metrics
        runMetrics.last
          ..mainAxisExtent += childMainAxisExtent
          ..crossAxisExtent = math.max(runMetrics.last.crossAxisExtent, childCrossAxisExtent)
          ..children.add(child);
      });

    _layoutFillColumns(runMetrics.last, mainAxisLimit, dry: dry);
    mainAxisExtent = math.max(mainAxisExtent, runMetrics.last.mainAxisExtent);
    crossAxisExtent += runMetrics.last.crossAxisExtent;

    final int runCount = runMetrics.length;
    assert(runCount > 0);

    size = constraints.constrain(Size(mainAxisExtent, crossAxisExtent));
    if (dry) return size;

    double containerMainAxisExtent = size.width;
    double containerCrossAxisExtent = size.height;

    _hasVisualOverflow = containerMainAxisExtent < mainAxisExtent || containerCrossAxisExtent < crossAxisExtent;

    final double crossAxisFreeSpace = math.max(0.0, containerCrossAxisExtent - crossAxisExtent);
    double runLeadingSpace = 0.0;
    double runBetweenSpace = 0.0;
    switch (runAlignment) {
      case WrapAlignment.start:
        break;
      case WrapAlignment.end:
        runLeadingSpace = crossAxisFreeSpace;
        break;
      case WrapAlignment.center:
        runLeadingSpace = crossAxisFreeSpace / 2.0;
        break;
      case WrapAlignment.spaceBetween:
        runBetweenSpace = runCount > 1 ? crossAxisFreeSpace / (runCount - 1) : 0.0;
        break;
      case WrapAlignment.spaceAround:
        runBetweenSpace = crossAxisFreeSpace / runCount;
        runLeadingSpace = runBetweenSpace / 2.0;
        break;
      case WrapAlignment.spaceEvenly:
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

      final double mainAxisFreeSpace = math.max(0.0, containerMainAxisExtent - runMainAxisExtent + spacing);
      double childLeadingSpace = 0.0;
      double childBetweenSpace = 0.0;

      switch (alignment) {
        case WrapAlignment.start:
          break;
        case WrapAlignment.end:
          childLeadingSpace = mainAxisFreeSpace;
          break;
        case WrapAlignment.center:
          childLeadingSpace = mainAxisFreeSpace / 2.0;
          break;
        case WrapAlignment.spaceBetween:
          childBetweenSpace = childCount > 1 ? mainAxisFreeSpace / (childCount - 1) : 0.0;
          break;
        case WrapAlignment.spaceAround:
          childBetweenSpace = mainAxisFreeSpace / childCount;
          childLeadingSpace = childBetweenSpace / 2.0;
          break;
        case WrapAlignment.spaceEvenly:
          childBetweenSpace = mainAxisFreeSpace / (childCount + 1);
          childLeadingSpace = childBetweenSpace;
          break;
      }

      childBetweenSpace += spacing;
      double childMainPosition = childLeadingSpace;

      metrics.children.forEach((child) {
        final _ResponsiveWrapParentData childParentData = child.parentData! as _ResponsiveWrapParentData;
        double childMainAxisExtent = _getMainAxisExtent(child.size);
        if (childParentData._column!.span! > 0)
          childMainAxisExtent = math.max(childMainAxisExtent, _getWidth(childParentData._column!.span!, mainAxisLimit));
        final double childMainAxisOffset = _getWidth(childParentData._column!.offset!, mainAxisLimit);
        final double childCrossAxisExtent = _getCrossAxisExtent(child.size);
        final double childCrossAxisOffset = _getChildCrossAxisOffset(runCrossAxisExtent, childCrossAxisExtent);
        childParentData.offset = Offset(
          childMainPosition + childMainAxisOffset,
          crossAxisOffset + childCrossAxisOffset,
        );
        childMainPosition += childMainAxisExtent + childMainAxisOffset + childBetweenSpace;
      });

      crossAxisOffset += runCrossAxisExtent + runBetweenSpace;
    }
  }

  _layoutFillColumns(_RunMetrics run, double mainAxisLimit, {bool dry = false}) {
    final fillColumns = run.children
        .where((column) => (column.parentData! as _ResponsiveWrapParentData)._column!.type == ResponsiveColumnType.fill)
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
          final double diff = _getParentData(a)._minIntrinsicWidth - _getParentData(b)._minIntrinsicWidth;

          return diff < 0 ? -1 : (diff > 0 ? 1 : 0);
        });

        for (int i = 0; i < sorted.length; i++) {
          final double a = _getParentData(sorted[i])._minIntrinsicWidth;
          final double b = i == sorted.length - 1 ? double.infinity : _getParentData(sorted[i + 1])._minIntrinsicWidth;
          final double diff = b - a;
          final int multiplier = i + 1;
          final double adj = math.min(diff * multiplier, freeSpace);

          for (int j = i; j >= 0; j--) {
            _getParentData(sorted[j])._adjustedWidth += adj / multiplier;
          }
          freeSpace -= adj;

          if (freeSpace == 0) break;
        }
      } else {
        _getParentData(fillColumns.first)._adjustedWidth = freeSpace;
      }

      fillColumns.forEach((child) {
        final _ResponsiveWrapParentData parentData = _getParentData(child);
        final Size childSize = _layoutChild(
          child,
          BoxConstraints(maxWidth: parentData._minIntrinsicWidth + parentData._adjustedWidth),
        );
        // Update run metrics now that a child in the run was sized
        run.crossAxisExtent = math.max(run.crossAxisExtent, _getCrossAxisExtent(childSize));
        // The run main axis is always full size because it had at least one fill column
        run.mainAxisExtent = mainAxisLimit;
      });
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
    properties.add(EnumProperty<WrapAlignment>('alignment', alignment));
    properties.add(DoubleProperty('spacing', spacing));
    properties.add(EnumProperty<WrapAlignment>('runAlignment', runAlignment));
    properties.add(DoubleProperty('runSpacing', runSpacing));
    properties.add(DoubleProperty('crossAxisAlignment', runSpacing));
  }
}
