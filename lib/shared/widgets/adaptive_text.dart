import 'package:flutter/material.dart';

class AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int maxLines;

  const AdaptiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.visible,
        softWrap: false,
      ),
    );
  }
}


