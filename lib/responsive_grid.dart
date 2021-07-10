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

  Size? _drySize;
  Iterable<_Track>? _spannedRowTracks;
  Iterable<_Track>? _spannedColTracks;

  int get columnEnd => columnStart! + columnSpan! - 1;
  int get rowEnd => rowStart! + rowSpan! - 1;

  /// Determines if col/row are both set. Fully positioned items are placed into the grid first,
  /// then partially positioned, and lastly auto positioned.
  bool get _isFullyPositioned => this.columnStart != null && this.rowStart != null;
  bool get _isPartiallyPositioned =>
      (this.columnStart == null || this.rowStart == null) && this.columnStart != this.rowStart;
}

/// An item that can span one or more columns and rows in a grid system.
class ResponsiveGridItem extends ParentDataWidget<ResponsiveGridParentData> {
  /// The 0-indexed column that this item starts it area in.
  final int? columnStart;

  /// The number of columns this item spans.
  ///
  /// If the item has a [columnStart] of 1 and a [columnSpan] of 3, it fills
  /// columns 1, 2 and 3.
  final int columnSpan;

  // The 0-indexed row that this item starts it area in.
  final int? rowStart;

  /// The number of rows this item spans.
  ///
  /// If the item has a [rowStart] of 1 and a [rowSpan] of 3, it fills
  /// rows 1, 2 and 3.
  final int rowSpan;

  /// The index used when multiple grid items overlap to determine which item
  /// is shown in front.
  ///
  /// Fully-positioned (column and row starts defined) items are not allocated
  /// by finding available space, and thus can overlap if their spans cross.
  final int zIndex;

  /// The individual cross axis alignment for the item's child within the grid
  /// area defined by the item.
  ///
  /// For instance, if the child of this item is 50dp tall but the grid area of
  /// the item is 100dp, a [crossAxisAlignment] of
  /// [ResponsiveCrossAlignment.center] would leave 25dp of space above and
  /// below
  final ResponsiveCrossAlignment? crossAxisAlignment;

  /// The child of the grid item.
  ///
  /// If the item is a spans only an auto-sized row or column, the child is
  /// used in determining (the largest child in that row or column) the cross
  /// axis size of the row or column.
  final Widget child;

  /// Creates a grid item that spans a grid area.
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

/// The internal type to distinguish how a grid track is sized.
enum _GridTrackType { auto, fixed, flex }

/// A single track (a row or column) of a grid.
class GridTrack {
  final _GridTrackType _type;
  final double _value;

  /// Creates an auto-sized track.
  ///
  /// The track's cross axis size (height for rows, width for columns) will be
  /// determined by the largest cross axis size of the children of grid items
  /// that span only this track.
  const GridTrack.auto()
      : _value = 0,
        _type = _GridTrackType.auto;

  /// Creates a fixed-sized track.
  ///
  /// This track cannot be smaller (height for rows, width for columns) than the
  /// given [size] and will provide a max constraint to the children of items
  /// in the track.
  const GridTrack.fixed(double size)
      : _value = size,
        _type = _GridTrackType.fixed;

  /// Creates a flexible track.
  ///
  /// Factor defaults to 1.
  ///
  /// Multiple flexible tracks in an axis of a grid will have remaining space
  /// divided among them based on the flex [factor].
  ///
  /// A flexible column will fill the remaining space in the horizontal
  /// direction after fixed and auto sized columns are accounted for.
  ///
  /// A flexible row matches the heights of of other row's flex items also
  /// including their [factor]. For instance: there are 3 flex rows with
  /// factors 1, 1 and 2 and children determining their heights to be 50, 100
  /// and 100. Their height to factor ratios would be 50, 100, and 50 and 100
  /// would be used as factor 1. Their final row heights would be 100, 100 and
  /// 200.
  const GridTrack.flex([int factor = 1])
      : _value = factor as double,
        _type = _GridTrackType.flex;

  @override
  String toString() {
    return 'GridTrack(type: $_type, _value: $_value)';
  }
}

/// A widget for laying out children in a grid where rows and columns can vary
/// in size and grid items are configurable in placement. Works well with
/// [Breakpoints] to change grid item placements and spans.
class ResponsiveGrid extends StatelessWidget {
  /// The column track definitions.
  ///
  /// At least one column is required and
  final List<GridTrack> columns;

  /// The row track definitions.
  ///
  /// No row track definitions are required. As items fill available space in
  /// the grid, new auto rows will be generated as required.
  final List<GridTrack> rows;

  /// How children are aligned within the horizontal axis of a grid item.
  ///
  /// For instance, if a item spans multiple columns and takes up 400dp of space
  /// but its child is only 200dp wide, 100dp of space will be distributed
  /// on each side with an [alignment] of [ResponsiveAlignment.center]
  final ResponsiveAlignment alignment;

  /// How children are aligned vertically within a grid item.
  ///
  /// For instance, if a row contains items with children of varying heights,
  /// a [crossAxisAlignment] of [ResponsiveCrossAlignment.end] will align all
  /// children to the bottom of their items (and thus, row).
  final ResponsiveCrossAlignment crossAxisAlignment;

  /// The spacing between grid items (both vertically and horizontally)
  ///
  /// To control space between rows and columns separately, use [rowSpacing] and
  /// [columnSpacing]
  final double spacing;

  /// The spacing between rows in the grid
  final double rowSpacing;

  /// The spacing between columns in the grid.
  final double columnSpacing;

  /// How to clip items that fall outside the constraints of the grid.
  final Clip clipBehavior;

  /// TODO: Do I need this?
  final bool breakOnConstraints;

  /// The grid items which fill the grid.
  final List<ResponsiveGridItem> children;

  /// Creates a grid for laying out items in a row and column format.
  ResponsiveGrid({
    Key? key,
    required this.columns,
    required this.rows,
    this.alignment = ResponsiveAlignment.start,
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
        rows: rows,
        alignment: alignment,
        crossAxisAlignment: crossAxisAlignment,
        rowSpacing: rowSpacing,
        columnSpacing: columnSpacing,
        clipBehavior: clipBehavior,
      ),
    );
  }
}

/// The true responsive grid containing layout logic to size based on children.
class _ResponsiveGrid extends MultiChildRenderObjectWidget {
  final List<GridTrack> columns;
  final List<GridTrack> rows;
  final ResponsiveAlignment alignment;
  final ResponsiveCrossAlignment crossAxisAlignment;
  final double rowSpacing;
  final double columnSpacing;
  final Clip clipBehavior;
  final Size screenSize;

  _ResponsiveGrid({
    Key? key,
    required this.rows,
    required this.columns,
    required this.screenSize,
    this.alignment = ResponsiveAlignment.start,
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
      rows: rows,
      alignment: alignment,
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
      ..rows = rows
      ..alignment = alignment
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
    required List<GridTrack> rows,
    required Size screenSize,
    List<RenderBox>? children,
    ResponsiveAlignment alignment = ResponsiveAlignment.start,
    ResponsiveCrossAlignment crossAxisAlignment = ResponsiveCrossAlignment.start,
    double rowSpacing = 0.0,
    double columnSpacing = 0.0,
    Clip clipBehavior = Clip.none,
  })  : _screenSize = screenSize,
        _columns = columns,
        _rows = rows,
        _alignment = alignment,
        _rowSpacing = rowSpacing,
        _columnSpacing = columnSpacing,
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

  List<GridTrack> get rows => _rows;
  List<GridTrack> _rows;
  set rows(List<GridTrack> value) {
    if (_rows == value) return;
    _rows = value;
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
    print('LAYOUT');
    final BoxConstraints constraints = this.constraints;

    _hasVisualOverflow = false;
    RenderBox? child = firstChild;
    if (child == null) {
      size = constraints.smallest;
      return size;
    }

    final List<RenderBox> children = getChildrenAsList();
    final int columnCount = columns.length;
    int rowCount = 0;
    final _Grid cells = _Grid(columnCount);

    // TODO: implicit columns? Find greatest columnEnd and create missing columns
    // with auto. Flex beyond constraints would be auto

    // Allocate fully positioned children first
    while (child != null) {
      final ResponsiveGridParentData childParentData = _getParentData(child);
      if (childParentData._isFullyPositioned) {
        cells.allocate(child);
        rowCount = math.max(rowCount, childParentData.rowEnd + 1);
      }
      child = childParentData.nextSibling;
    }

    // Allocate space to the rest of the children
    child = firstChild;
    while (child != null) {
      final ResponsiveGridParentData childParentData = _getParentData(child);
      if (!childParentData._isFullyPositioned) {
        cells.allocate(child);
        rowCount = math.max(rowCount, childParentData.rowEnd + 1);
      }
      child = childParentData.nextSibling;
    }

    double mainAxisLimit = constraints.maxWidth - (columnCount - 1) * _columnSpacing;

    if (rowCount > rows.length) rows.addAll(List.generate(rowCount - rows.length, (_) => GridTrack.auto()));
    rowTracks = rows.mapIndexed((index, row) => _Track(index, row, Axis.horizontal)).toList();
    colTracks = [];
    int totalFlex = 0;

    // Find remaining column space after fixed columns
    double remainingSpace = mainAxisLimit;
    columns.forEach((column) {
      final _Track track = _Track(colTracks.length, column, Axis.vertical);
      colTracks.add(track);
      if (column._type == _GridTrackType.fixed)
        track.crossAxisExtent = column._value;
      else if (column._type == _GridTrackType.flex) {
        // also count the total flex factor for later flex width calculations
        totalFlex += column._value.toInt();
      }
      remainingSpace -= track.crossAxisExtent;
    });

    assert(remainingSpace >= 0, 'The size of fixed columns exceeds the constraints width');

    // First, size auto columns based on the children that exist completely within their crossAxis
    child = firstChild;
    while (child != null) {
      final ResponsiveGridParentData item = _getParentData(child);

      // remember the rows and columns this item spans
      item._spannedColTracks = colTracks.getRange(item.columnStart!, item.columnEnd + 1);
      item._spannedRowTracks = rowTracks.getRange(item.rowStart!, item.rowEnd + 1);

      if (columns[item.columnStart!]._type == _GridTrackType.auto && item.columnSpan == 1) {
        item._drySize = child.getDryLayout(BoxConstraints());
        colTracks[item.columnStart!].update(item._drySize!);
      }
      child = item.nextSibling;
      // if there is an auto column that does not satisfy the above, it has no width-driving
      // children and would have a crossAxisExtent of 0.
    }

    // Distribute column-spanned widths to auto columns
    Iterable<RenderBox> colSpans = children.where((child) => _getParentData(child).columnSpan! > 1);
    colSpans.sorted((a, b) => _getParentData(a).columnSpan! - _getParentData(b).columnSpan!);
    colSpans.forEach((child) {
      final ResponsiveGridParentData item = _getParentData(child);
      // If it spans a flex at all, move on
      if (item._spannedColTracks!.any((track) => track.definition._type == _GridTrackType.flex)) return;

      item._drySize ??= child.getDryLayout(BoxConstraints());

      final Iterable<_Track> spannedAutoColTracks =
          item._spannedColTracks!.where((track) => track.definition._type == _GridTrackType.auto);
      double spannedWidth = 0.0;
      spannedAutoColTracks.forEach((track) {
        spannedWidth += track.crossAxisExtent;
      });

      final double contribution =
          (item._drySize!.width - _columnSpacing * (item.columnSpan! - 1) - spannedWidth) / item.columnSpan!;

      print('col spans ${item.columnSpan}, width $spannedWidth, contributes $contribution');

      if (contribution <= 0) return;
      spannedAutoColTracks.forEach((track) {
        track.crossAxisExtent += contribution;
      });
    });

    // At this point, all auto columns should have a crossAxisExtent that is their set width.
    remainingSpace = mainAxisLimit;
    colTracks.forEach((track) {
      remainingSpace -= track.crossAxisExtent;
    });

    assert(remainingSpace >= 0, 'No remaining space to distribute to flex columns.');

    // Set remaining crossAxisExtents for all columns
    columns.forEachIndexed((index, column) {
      final _Track track = colTracks[index];
      switch (column._type) {
        case _GridTrackType.fixed:
          track.crossAxisExtent = column._value;
          break;
        case _GridTrackType.flex:
          track.crossAxisExtent = column._value / totalFlex * remainingSpace;
          break;
        default: // auto has its crossAxisExtent set above
          return;
      }
    });

    // Set fixed row heights and count total row flex
    rowTracks.forEach((track) {
      final GridTrack row = track.definition;
      if (row._type == _GridTrackType.fixed)
        track.crossAxisExtent = row._value;
      else if (row._type == _GridTrackType.flex) {
        totalFlex += row._value.toInt();
      }
    });

    // Size auto rows based on the children that exist completely within their crossAxis
    // Also find the flex basis for flex rows (max of: auto height / flex factor)
    double maxHeightFlex = 0.0;
    child = firstChild;
    while (child != null) {
      final ResponsiveGridParentData item = _getParentData(child);
      final GridTrack row = rows[item.rowStart!];
      if (row._type == _GridTrackType.auto && item.rowSpan == 1) {
        item._drySize ??= child.getDryLayout(BoxConstraints());
        rowTracks[item.rowStart!].update(item._drySize!);
      }

      if (row._type == _GridTrackType.flex && item.rowSpan == 1) {
        item._drySize ??= child.getDryLayout(BoxConstraints());
        maxHeightFlex = math.max(maxHeightFlex, item._drySize!.height / row._value);
      }

      child = item.nextSibling;
    }

    // Distribute row-spanned heights to auto rows
    Iterable<RenderBox> rowSpans = children.where((child) => _getParentData(child).rowSpan! > 1);
    rowSpans.sorted((a, b) => _getParentData(a).rowSpan! - _getParentData(b).rowSpan!);
    rowSpans.forEach((child) {
      final ResponsiveGridParentData item = _getParentData(child);
      // If it spans a flex row at all, move on
      if (item._spannedColTracks!.any((track) => track.definition._type == _GridTrackType.flex)) return;

      item._drySize ??= child.getDryLayout(BoxConstraints());

      final Iterable<_Track> spannedAutoRowTracks =
          item._spannedRowTracks!.where((track) => track.definition._type == _GridTrackType.auto);

      if (spannedAutoRowTracks.length == 0) return;

      double spannedHeight = 0.0;
      item._spannedRowTracks!.forEach((track) {
        spannedHeight += track.crossAxisExtent;
        print('spans a row ${track.definition._type} with ${track.crossAxisExtent}');
      });

      final double contribution =
          (item._drySize!.height - _rowSpacing * (item.rowSpan! - 1) - spannedHeight) / spannedAutoRowTracks.length;

      print(
          'row spans ${spannedAutoRowTracks.length} (${item._drySize!.height}), spans height $spannedHeight, contributes $contribution');

      if (contribution <= 0) return;
      spannedAutoRowTracks.forEach((track) {
        track.crossAxisExtent += contribution;
      });
    });

    // Set remaining crossAxisExtents for rows.
    rows.forEachIndexed((index, row) {
      final _Track track = rowTracks[index];
      switch (row._type) {
        case _GridTrackType.fixed:
          track.crossAxisExtent = row._value;
          break;
        case _GridTrackType.flex:
          track.crossAxisExtent = row._value * maxHeightFlex;
          break;
        default:
          return;
      }
    });

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

    // Finally, lay everything out for real with the crossAxistExtents of their row/column
    child = firstChild;
    while (child != null) {
      final ResponsiveGridParentData item = _getParentData(child);

      // find the total mainAxisExtent for all the cols the child crosses
      double spanMainAxisExtent = (item._spannedColTracks!.length - 1) * _columnSpacing;
      item._spannedColTracks!.forEach((track) => spanMainAxisExtent += track.crossAxisExtent);

      // find the total crossAxisExtent for all the rows the child crosses
      double spanCrossAxisExtent = (item._spannedRowTracks!.length - 1) * _rowSpacing;
      item._spannedRowTracks!.forEach((track) => spanCrossAxisExtent += track.crossAxisExtent);

      _layoutChild(
        child,
        BoxConstraints(
          maxWidth: spanMainAxisExtent,
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
    assert(() {
      final Paint fill = Paint()
        ..color = Color(0x33FF0000)
        ..style = PaintingStyle.fill;
      final Paint stroke = Paint()
        ..color = Color(0x66FF0000)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final Paint itemStroke = Paint()
        ..color = Color(0x668800FF)
        ..strokeWidth = 2
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
      getChildrenAsList().forEach((child) {
        ResponsiveGridParentData item = _getParentData(child);
        final Rect rect = Rect.fromPoints(
            offset +
                Offset(colTracks.elementAt(item.columnStart!).crossAxisOffset,
                    rowTracks.elementAt(item.rowStart!).crossAxisOffset),
            offset +
                Offset(
                    colTracks.elementAt(item.columnEnd).crossAxisOffset +
                        colTracks.elementAt(item.columnEnd).crossAxisExtent,
                    rowTracks.elementAt(item.rowEnd).crossAxisOffset +
                        rowTracks.elementAt(item.rowEnd).crossAxisExtent));
        context.canvas.drawRect(rect.deflate(1), itemStroke);
      });
      return true;
    }());
    super.debugPaintSize(context, offset);
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
    properties.add(IterableProperty<GridTrack>('rows', rows));
    properties.add(DoubleProperty('rowSpacing', rowSpacing));
    properties.add(DoubleProperty('columnSpacing', columnSpacing));
    properties.add(EnumProperty<ResponsiveAlignment>('alignment', alignment));
    properties.add(EnumProperty<ResponsiveCrossAlignment>('crossAxisAlignment', crossAxisAlignment));
  }
}

class _Track {
  final int index;
  final List<RenderBox> children = [];
  final Axis axis;
  double crossAxisExtent = 0;
  double crossAxisOffset = 0;
  final GridTrack definition;

  _Track(this.index, this.definition, this.axis);

  update(Size childSize) {
    crossAxisExtent = math.max(crossAxisExtent, axis == Axis.horizontal ? childSize.height : childSize.width);
  }

  @override
  String toString() {
    return '_Track(index: $index, axis: $axis, crossAxisExtent: $crossAxisExtent)';
  }
}

class _Grid {
  final int columnCount;
  final List<List<bool>> cells;

  _Grid(this.columnCount) : cells = [List.generate(columnCount, (_) => false)];

  _markTaken(RenderBox child) {
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
    final ResponsiveGridParentData item = _getParentData(child);

    if (item._isPartiallyPositioned) {
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
            break;
          }
        }
        if (item.columnStart == null) {
          throw ArgumentError(
              '${item.columnStart} ${item.columnSpan} ${item.rowStart} ${item.rowSpan} did not fit on row $y, $cells');
        }
      }
    } else if (!item._isFullyPositioned) {
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

ResponsiveGridParentData _getParentData(RenderBox child) {
  return child.parentData as ResponsiveGridParentData;
}
