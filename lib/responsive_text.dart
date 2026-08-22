import 'package:flutter/material.dart';

class FluidText extends Text {
  final int minWidth;
  final int maxWidth;
  final double minFontSize;
  final double maxFontSize;
  final TextStyle _style;

  FluidText(
    super.data, {
    required this.minWidth,
    required this.maxWidth,
    required this.minFontSize,
    required this.maxFontSize,
    super.key,
    TextStyle? style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
  }) : _style = style ?? const TextStyle() {
    _validateRange(minWidth, maxWidth, minFontSize, maxFontSize);
  }

  FluidText.rich(
    super.textSpan, {
    required this.minWidth,
    required this.maxWidth,
    required this.minFontSize,
    required this.maxFontSize,
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
  }) : _style = style ?? const TextStyle(),
       super.rich() {
    _validateRange(minWidth, maxWidth, minFontSize, maxFontSize);
  }

  static void _validateRange(
    int minWidth,
    int maxWidth,
    double minFontSize,
    double maxFontSize,
  ) {
    if (minWidth < 0 || maxWidth <= minWidth) {
      throw ArgumentError(
        'maxWidth must be greater than non-negative minWidth.',
      );
    }
    if (!minFontSize.isFinite ||
        !maxFontSize.isFinite ||
        minFontSize < 0 ||
        maxFontSize < minFontSize) {
      throw ArgumentError(
        'Font sizes must be finite, non-negative, and ordered.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final progress = ((width - minWidth) / (maxWidth - minWidth)).clamp(
      0.0,
      1.0,
    );
    final fontSize = minFontSize + (maxFontSize - minFontSize) * progress;

    return DefaultTextStyle.merge(
      style: _style.merge(TextStyle(fontSize: fontSize)),
      child: Builder(builder: super.build),
    );
  }
}
