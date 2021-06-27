import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:responsive_toolkit/responsive_row.dart';
import 'package:collection/collection.dart';

/// Parent data for use with [RenderResponsiveGrid]
class ResponsiveGridParentData extends ContainerBoxParentData<RenderBox> {
  int? columnStart;
  int? columnSpan;
  int? rowStart;
  int? rowSpan;
  int? zIndex;
  ResponsiveCrossAlignment? crossAxisAlignment;

  int get columnEnd => columnStart! + columnSpan! - 1;
  int get rowEnd => rowStart! + rowSpan! - 1;

  GridTrack? _column;

  /// Determines if col/row are both set. Fully positioned items are placed into the grid first,
  /// then partially positioned, and lastly auto positioned.
  bool get _isFullyPositioned => this.columnStart != null && this.rowStart != null;
  bool get _isPartiallyPositioned =>
      (this.columnStart == null || this.rowStart == null) && this.columnStart != this.rowStart;
}

class ResponsiveGridItem extends ParentDataWidget<ResponsiveGridParentData> {
  final int? columnStart;
  final int columnSpan;
  final int? rowStart;
  final int rowSpan;
  final int zIndex;
  final ResponsiveCrossAlignment? crossAxisAlignment;
  final Widget child;

  const ResponsiveGridItem({
    Key? key,
    this.columnStart,
    this.columnSpan = 1,
    this.rowStart,
    this.rowSpan = 1,
    this.zIndex = 0,
    this.crossAxisAlignment,
    required this.child,
  })  : assert(columnStart == null || columnStart >= 0),
        assert(rowStart == null || rowStart >= 0),
        super(key: key, child: child);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('columnStart', columnStart));
    properties.add(IntProperty('columnSpan', columnSpan));
    properties.add(IntProperty('rowStart', rowStart));
    properties.add(IntProperty('rowSpan', rowSpan));
    properties.add(IntProperty('zIndex', zIndex));
    properties.add(EnumProperty<ResponsiveCrossAlignment>('crossAxisAlignment', crossAxisAlignment));
  }

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is ResponsiveGridParentData);
    final ResponsiveGridParentData parentData = renderObject.parentData! as ResponsiveGridParentData;
    bool needsLayout = false;

    if (parentData.columnStart != columnStart) {
      parentData.columnStart = columnStart;
      needsLayout = true;
    }
    if (parentData.columnSpan != columnSpan) {
      parentData.columnSpan = columnSpan;
      needsLayout = true;
    }
    if (parentData.rowStart != rowStart) {
      parentData.rowStart = rowStart;
      needsLayout = true;
    }
    if (parentData.rowSpan != rowSpan) {
      parentData.rowSpan = rowSpan;
      needsLayout = true;
    }
    if (parentData.zIndex != zIndex) {
      parentData.zIndex = zIndex;
      needsLayout = true;
    }
    if (parentData.crossAxisAlignment != crossAxisAlignment) {
      parentData.crossAxisAlignment = crossAxisAlignment;
      needsLayout = true;
    }

    if (needsLayout) {
      final AbstractNode? targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => ResponsiveGrid;
}

enum _GridTrackType { auto, fixed, flex, fraction }

class GridTrack {
  final _GridTrackType _type;
  final double _value;

  const GridTrack.auto()
      : _value = 0,
        _type = _GridTrackType.auto;

  const GridTrack.fixed(double width)
      : _value = width,
        _type = _GridTrackType.fixed;

  const GridTrack.flex([int factor = 1])
      : _value = factor as double,
        _type = _GridTrackType.flex;

  const GridTrack.fraction(double fraction)
      : _value = fraction,
        _type = _GridTrackType.fraction;
}

class ResponsiveGrid extends StatelessWidget {
  final List<GridTrack> columns;
  final List<GridTrack> rows;
  final ResponsiveAlignment alignment;
  final ResponsiveAlignment runAlignment;
  final ResponsiveCrossAlignment crossAxisAlignment;
  final double spacing;
  final double rowSpacing;
  final double columnSpacing;
  final Clip clipBehavior;
  final bool breakOnConstraints;
  final List<ResponsiveGridItem> children;

  ResponsiveGrid({
    Key? key,
    required this.columns,
    required this.rows,
    this.alignment = ResponsiveAlignment.start,
    this.runAlignment = ResponsiveAlignment.start,
    this.crossAxisAlignment = ResponsiveCrossAlignment.start,
    this.clipBehavior = Clip.none,
    this.breakOnConstraints = false,
    this.spacing = 0.0,
    double? rowSpacing,
    double? columnSpacing,
    required List<Widget> children,
  })  : assert(columns.length > 0),
        rowSpacing = rowSpacing ?? spacing,
        columnSpacing = columnSpacing ?? spacing,
        children =
            children.map((child) => child is ResponsiveGridItem ? child : ResponsiveGridItem(child: child)).toList(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _ResponsiveGrid(
        children: children,
        screenSize: breakOnConstraints ? constraints.biggest : MediaQuery.of(context).size,
        columns: columns,
        alignment: alignment,
        runAlignment: runAlignment,
        crossAxisAlignment: crossAxisAlignment,
        rowSpacing: rowSpacing,
        columnSpacing: columnSpacing,
        clipBehavior: clipBehavior,
      ),
    );
  }
}

/// The true responsive row containing layout logic to size based on children.
class _ResponsiveGrid extends MultiChildRenderObjectWidget {
  final List<GridTrack> columns;
  final ResponsiveAlignment alignment;
  final ResponsiveAlignment runAlignment;
  final ResponsiveCrossAlignment crossAxisAlignment;
  final double rowSpacing;
  final double columnSpacing;
  final Clip clipBehavior;
  final Size screenSize;

  _ResponsiveGrid({
    Key? key,
    required this.columns,
    required this.screenSize,
    this.alignment = ResponsiveAlignment.start,
    this.runAlignment = ResponsiveAlignment.start,
    this.crossAxisAlignment = ResponsiveCrossAlignment.start,
    this.rowSpacing = 0.0,
    this.columnSpacing = 0.0,
    this.clipBehavior = Clip.none,
    required List<ResponsiveGridItem> children,
  }) : super(key: key, children: children);

  @override
  RenderResponsiveGrid createRenderObject(BuildContext context) {
    return RenderResponsiveGrid(
      screenSize: screenSize,
      columns: columns,
      alignment: alignment,
      runAlignment: runAlignment,
      crossAxisAlignment: crossAxisAlignment,
      rowSpacing: rowSpacing,
      columnSpacing: columnSpacing,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderResponsiveGrid renderObject) {
    renderObject
      ..screenSize = screenSize
      ..columns = columns
      ..alignment = alignment
      ..runAlignment = runAlignment
      ..crossAxisAlignment = crossAxisAlignment
      ..rowSpacing = rowSpacing
      ..columnSpacing = columnSpacing
      ..clipBehavior = clipBehavior;
  }
}

class RenderResponsiveGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ResponsiveGridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ResponsiveGridParentData> {
  RenderResponsiveGrid({
    required List<GridTrack> columns,
    required Size screenSize,
    List<RenderBox>? children,
    ResponsiveAlignment alignment = ResponsiveAlignment.start,
    ResponsiveAlignment runAlignment = ResponsiveAlignment.start,
    ResponsiveCrossAlignment crossAxisAlignment = ResponsiveCrossAlignment.start,
    double rowSpacing = 0.0,
    double columnSpacing = 0.0,
    Clip clipBehavior = Clip.none,
  })  : _screenSize = screenSize,
        _columns = columns,
        _alignment = alignment,
        _rowSpacing = rowSpacing,
        _columnSpacing = columnSpacing,
        _runAlignment = runAlignment,
        _crossAxisAlignment = crossAxisAlignment,
        _clipBehavior = clipBehavior {
    addAll(children);
  }

  List<_Track> rowTracks = [];
  List<_Track> colTracks = [];

  Size get screenSize => _screenSize;
  Size _screenSize;
  set screenSize(Size value) {
    if (_screenSize == value) return;
    _screenSize = value;
    markNeedsLayout();
  }

  List<GridTrack> get columns => _columns;
  List<GridTrack> _columns;
  set columns(List<GridTrack> value) {
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

  double get rowSpacing => _rowSpacing;
  double _rowSpacing;
  set rowSpacing(double value) {
    if (_rowSpacing == value) return;
    _rowSpacing = value;
    markNeedsLayout();
  }

  double get columnSpacing => _columnSpacing;
  double _columnSpacing;
  set columnSpacing(double value) {
    if (_columnSpacing == value) return;
    _columnSpacing = value;
    markNeedsLayout();
  }

  ResponsiveAlignment get runAlignment => _runAlignment;
  ResponsiveAlignment _runAlignment;
  set runAlignment(ResponsiveAlignment value) {
    if (_runAlignment == value) return;
    _runAlignment = value;
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
    if (child.parentData is! ResponsiveGridParentData) child.parentData = ResponsiveGridParentData();
  }

  // TODO: For all these, loop through all rows and its the min/max of the sums of their children
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

  double _getChildCrossAxisOffset(RenderBox child, double crossAxisExtent) {
    final double freeSpace = crossAxisExtent - child.size.height;
    final ResponsiveCrossAlignment align =
        (child.parentData as ResponsiveGridParentData).crossAxisAlignment ?? crossAxisAlignment;
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

    final int columnCount = columns.length;
    final _Grid cells = _Grid(columnCount);
    int maxRow = 0;

    // Allocate space to all children
    while (child != null) {
      ResponsiveGridParentData childParentData = child.parentData as ResponsiveGridParentData;

      cells.allocate(child);
      childParentData._column = columns[childParentData.columnStart!];
      maxRow = math.max(maxRow, childParentData.rowEnd);
      log('$cells');

      child = childParentData.nextSibling;
    }

    double mainAxisLimit = constraints.maxWidth - (columnCount - 1) * _columnSpacing;

    rowTracks = List.generate(maxRow + 1, (_) => _Track(Axis.horizontal));
    colTracks = [];
    int totalFlex = 0;

    // find remaining space after fixed/fraction columns
    double remainingSpace = mainAxisLimit;
    columns.forEach((column) {
      final _Track track = _Track(Axis.vertical);
      colTracks.add(track);
      if (column._type == _GridTrackType.fixed)
        track.crossAxisExtent = column._value;
      else if (column._type == _GridTrackType.fraction)
        track.crossAxisExtent = mainAxisLimit * column._value;
      else if (column._type == _GridTrackType.flex) {
        // also count the total flex factor for later flex width calculations
        totalFlex += column._value.toInt();
      }
      remainingSpace -= track.crossAxisExtent;
    });

    assert(remainingSpace >= 0, 'The size of fixed and fraction columns exceeds the constraints width');

    // Spans of 1 contribute width to the crossAxisExtent of the track of the span type (col/row)
    // Auto columns must have all its singular colSpan children laid out to dermine its width
    // after that even flex columns are locked in.

    // First, size auto columns based on the children that exist completely within their crossAxis
    child = firstChild;
    while (child != null) {
      ResponsiveGridParentData item = child.parentData as ResponsiveGridParentData;
      if (item._column!._type == _GridTrackType.auto && item.columnSpan == 1) {
        colTracks[item.columnStart!].update(child.getDryLayout(BoxConstraints()));
      }
      child = item.nextSibling;
      // if there is an auto column that does not satisfy the above, it has no width-driving
      // children and would have a crossAxisExtent of 0.
    }

    // At this point, all auto columns should have a crossAxisExtent that is their set width.
    remainingSpace = mainAxisLimit;
    colTracks.forEach((track) {
      remainingSpace -= track.crossAxisExtent;
    });

    assert(remainingSpace >= 0, 'No remaining space to distribute to flex columns.');

    columns.forEachIndexed((index, column) {
      final _Track track = colTracks[index];
      switch (column._type) {
        case _GridTrackType.fixed:
          track.crossAxisExtent = column._value;
          break;
        case _GridTrackType.fraction:
          track.crossAxisExtent = column._value * mainAxisLimit;
          break;
        case _GridTrackType.flex:
          track.crossAxisExtent = column._value / totalFlex * remainingSpace;
          break;
        default: // auto has its crossAxisExtent set above
          return;
      }
    });
    // All column tracks have a crossAxisExtent set we can use to layout and determine heights
    child = firstChild;
    while (child != null) {
      final ResponsiveGridParentData item = child.parentData as ResponsiveGridParentData;

      // Add all tracks this child contributes its crossAxistExtent to
      Iterable<_Track> spannedColTracks = colTracks.getRange(item.columnStart!, item.columnEnd + 1);
      Iterable<_Track> spannedRowTracks = rowTracks.getRange(item.rowStart!, item.rowEnd + 1);

      // find the total mainAxisExtent for all the columns the child crosses
      double childMainAxisExtent = (spannedColTracks.length - 1) * _columnSpacing;
      spannedColTracks.forEach((track) => childMainAxisExtent += track.crossAxisExtent);

      final Size childSize = _layoutChild(child, BoxConstraints(maxWidth: childMainAxisExtent), dry: dry);

      final int rowSpan = spannedRowTracks.length;
      final double contribution = childSize.height / rowSpan - _rowSpacing * (rowSpan - 1);
      spannedRowTracks.forEach((track) => track.update(Size(0, contribution)));
      // log('[$index] $start:$end contributes $contribution to rows ${start.row}-${end.row}');

      child = item.nextSibling;
    }

    colTracks.forEach((track) => log('col ${track.crossAxisExtent}'));
    rowTracks.forEach((track) => log('row ${track.crossAxisExtent}'));

    // calculate row and column offsets
    double crossAxisExtent = 0.0;
    colTracks.forEach((track) {
      track.crossAxisOffset = crossAxisExtent;
      crossAxisExtent += track.crossAxisExtent + _columnSpacing;
    });
    crossAxisExtent = 0.0;
    rowTracks.forEach((track) {
      track.crossAxisOffset = crossAxisExtent;
      crossAxisExtent += track.crossAxisExtent + _rowSpacing;
    });

    Size mySize = constraints.constrain(Size(constraints.maxWidth, crossAxisExtent - _rowSpacing));
    if (dry) return mySize;
    size = mySize;

    // Finally, relayout with new height restrictions based on row crossAxisExtent
    child = firstChild;
    while (child != null) {
      final ResponsiveGridParentData item = child.parentData as ResponsiveGridParentData;
      final Iterable<_Track> spannedRowTracks = rowTracks.getRange(item.rowStart!, item.rowEnd + 1);
      // find the total crossAxisExtent for all the rows the child crosses
      double spanCrossAxisExtent = (spannedRowTracks.length - 1) * _rowSpacing;
      spannedRowTracks.forEach((track) => spanCrossAxisExtent += track.crossAxisExtent);

      _layoutChild(
        child,
        BoxConstraints(
          maxWidth: child.size.width,
          maxHeight: spanCrossAxisExtent,
          minHeight: (item.crossAxisAlignment ?? crossAxisAlignment) == ResponsiveCrossAlignment.stretch
              ? spanCrossAxisExtent
              : 0,
        ),
      );

      final _Track rowTrack = rowTracks[item.rowStart!];
      final _Track colTrack = colTracks[item.columnStart!];
      final double childCrossAxisOffset = _getChildCrossAxisOffset(child, spanCrossAxisExtent);
      item.offset = Offset(colTrack.crossAxisOffset, rowTrack.crossAxisOffset + childCrossAxisOffset);

      child = item.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      final Paint fill = Paint()
        ..color = Color(0x33FF0000)
        ..style = PaintingStyle.fill;
      final Paint stroke = Paint()
        ..color = Color(0x66FF0000)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      colTracks.skip(1).forEach((track) {
        final Rect gap =
            (offset + Offset(track.crossAxisOffset - _columnSpacing, 0)) & Size(_columnSpacing, size.height);
        context.canvas..drawRect(gap, fill)..drawRect(gap.deflate(0.5), stroke);
      });
      rowTracks.skip(1).forEach((track) {
        final Rect gap = (offset + Offset(0, track.crossAxisOffset - _rowSpacing)) & Size(size.width, _rowSpacing);
        context.canvas..drawRect(gap, fill)..drawRect(gap.deflate(0.5), stroke);
      });
      return true;
    }());
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
    properties.add(IterableProperty<GridTrack>('columns', columns));
    properties.add(EnumProperty<ResponsiveAlignment>('alignment', alignment));
    properties.add(DoubleProperty('rowSpacing', rowSpacing));
    properties.add(DoubleProperty('columnSpacing', columnSpacing));
    properties.add(EnumProperty<ResponsiveAlignment>('runAlignment', runAlignment));
    properties.add(EnumProperty<ResponsiveCrossAlignment>('crossAxisAlignment', crossAxisAlignment));
  }
}

class _Track {
  final List<RenderBox> children = [];
  final Axis axis;
  double crossAxisExtent = 0;
  double crossAxisOffset = 0;
  GridTrack? column;

  _Track(this.axis);

  add(RenderBox child, Size childSize) {
    children.add(child);
    update(childSize);
  }

  update(Size childSize) {
    crossAxisExtent = math.max(crossAxisExtent, axis == Axis.horizontal ? childSize.height : childSize.width);
  }
}

class _Grid {
  final int columnCount;
  final List<List<bool>> cells;

  _Grid(this.columnCount) : cells = [List.generate(columnCount, (_) => false)];

  _markTaken(RenderBox child) {
    log('marking taken');
    final ResponsiveGridParentData item = child.parentData as ResponsiveGridParentData;
    _expand(item.rowEnd);
    for (int y = item.rowStart!; y <= item.rowEnd; y++) {
      for (int x = item.columnStart!; x <= item.columnEnd; x++) {
        cells[y][x] = true;
      }
    }
  }

  bool checkTaken(_Cell from, [_Cell? to]) {
    to = to ?? from;
    _expand(to.row);
    for (int y = from.row; y <= to.row; y++) {
      for (int x = from.col; x <= to.col; x++) {
        if (cells[y][x]) return true;
      }
    }
    return false;
  }

  _expand(int row) {
    if (row >= cells.length) {
      cells.addAll(List.generate(row + 1 - cells.length, (_) => List.generate(columnCount, (_) => false)));
    }
  }

  allocate(RenderBox child) {
    ResponsiveGridParentData item = child.parentData as ResponsiveGridParentData;

    if (item._isPartiallyPositioned) {
      log('partially positioned');
      if (item.columnStart != null) {
        // column is locked, find a row that will fit the size
        int y = 0;
        // this will always complete by eventually creating new rows
        while (true) {
          _expand(y);
          final _Cell position = _Cell(item.columnStart!, y++);
          if (!checkTaken(position, position.span(item.columnSpan!, item.rowSpan!))) {
            item.columnStart = position.col;
            item.rowStart = position.row;
            break;
          }
        }
      } else {
        // row is locked, find a column in the row that will fit the size
        final int y = item.rowStart!;
        _expand(y);
        for (int x = 0; x < columnCount - item.columnSpan! + 1; x++) {
          final _Cell position = _Cell(x, y);
          if (!checkTaken(position, position.span(item.columnSpan!, item.rowSpan!))) {
            item.columnStart = position.col;
            item.rowStart = position.row;
          }
        }
        throw ArgumentError('$item did not fit on row $y');
      }
    } else if (!item._isFullyPositioned) {
      log('auto positioned');
      // only other option is auto positioned, fully positioned do not call findSpace
      int y = 0;
      // this will always complete by eventually creating new rows
      while (item.columnStart == null) {
        _expand(y);
        for (int x = 0; x < columnCount - item.columnSpan! + 1; x++) {
          final _Cell position = _Cell(x, y);
          if (!checkTaken(position, position.span(item.columnSpan!, item.rowSpan!))) {
            item.columnStart = position.col;
            item.rowStart = position.row;
            break;
          }
        }
        y++;
      }
    }

    _markTaken(child);
  }

  @override
  String toString() {
    String result = '';
    for (int y = 0; y < cells.length; y++) {
      for (int x = 0; x < columnCount; x++) {
        result += cells[y][x] ? 'X' : '_';
      }
      result += '\n';
    }
    return result;
  }
}

class _Cell {
  final int col;
  final int row;

  _Cell(this.col, this.row);

  _Cell span(int colSpan, int rowSpan) {
    return _Cell(col + colSpan - 1, row + rowSpan - 1);
  }

  @override
  String toString() {
    return '_Cell($col, $row)';
  }
}
