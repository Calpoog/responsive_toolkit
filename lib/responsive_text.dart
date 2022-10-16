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
    super.textScaleFactor,
    super.maxLines,
    super.semanticsLabel,
    super.textWidthBasis,
    super.textHeightBehavior,
  }) : _style = style ?? TextStyle();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return DefaultTextStyle.merge(
      style: _style.merge(TextStyle(
          fontSize: minFontSize +
              (maxFontSize - minFontSize) *
                  ((width - minWidth) / (maxWidth - minWidth)).clamp(0, 1))),
      child: Builder(builder: (context) => super.build(context)),
    );
  }
}
