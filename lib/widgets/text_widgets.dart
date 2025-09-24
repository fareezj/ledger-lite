import 'package:flutter/material.dart';

class TextWidgets {
  // OpenSans Regular
  static Text mainRegular({
    required String title,
    TextStyle? textStyle,
    Color? color,
    TextAlign textAlign = TextAlign.center,
    double fontSize = 16.0,
    double lineHeight = 1.5,
    int maxLines = 2,
    FontWeight fontWeight = FontWeight.w400,
    TextOverflow textOverflow = TextOverflow.ellipsis,
  }) {
    return Text(
      title,
      textAlign: textAlign,
      overflow: textOverflow,
      maxLines: maxLines,
      style:
          textStyle ??
          TextStyle(
            height: lineHeight,
            fontSize: fontSize,
            color: color ?? Colors.black,
            fontWeight: fontWeight, // Regular weight
            fontFamily: 'Inter',
          ),
    );
  }

  // OpenSans SemiBold
  static Text mainSemiBold({
    required String title,
    TextStyle? textStyle,
    Color? color,
    TextAlign textAlign = TextAlign.center,
    double fontSize = 16.0,
    double letterSpace = 0,
    int maxLines = 2,
    FontWeight fontWeight = FontWeight.w600,
    TextOverflow textOverflow = TextOverflow.ellipsis,
    TextDecoration textDecoration = TextDecoration.none,
  }) {
    return Text(
      title,
      textAlign: textAlign,
      overflow: textOverflow,
      maxLines: maxLines,
      style:
          textStyle ??
          TextStyle(
            fontSize: fontSize,
            letterSpacing: letterSpace,
            color: color ?? Colors.black87,
            fontWeight: fontWeight, // SemiBold weight
            fontFamily: 'Inter',
            decoration: textDecoration,
          ),
    );
  }

  // OpenSans Bold
  static Text mainBold({
    required String title,
    TextStyle? textStyle,
    Color? color,
    TextAlign textAlign = TextAlign.center,
    double fontSize = 16,
  }) {
    return Text(
      title,
      textAlign: textAlign,
      overflow: TextOverflow.clip,
      style:
          textStyle ??
          TextStyle(
            fontSize: fontSize,
            color: color ?? Colors.black87,
            fontWeight: FontWeight.bold, // Bold weight
            fontFamily: 'Inter',
          ),
    );
  }

  // OpenSans Italic
  static Text mainItalic({
    required String title,
    TextStyle? textStyle,
    Color? color,
    TextAlign textAlign = TextAlign.center,
    double fontSize = 16,
  }) {
    return Text(
      title,
      textAlign: textAlign,
      overflow: TextOverflow.clip,
      style:
          textStyle ??
          TextStyle(
            fontSize: fontSize,
            color: color ?? Colors.black87,
            fontStyle: FontStyle.italic, // Italic style
            fontFamily: 'Inter',
          ),
    );
  }
}
