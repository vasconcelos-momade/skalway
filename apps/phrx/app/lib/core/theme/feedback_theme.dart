import 'dart:ui';
import 'package:flutter/material.dart';

class FeedbackColors {
  FeedbackColors._();

  static final successBg = const Color(0xFF16A34A).withValues(alpha: 0.90);
  static const successBorder = Color(0xFF15803D);

  static final errorBg = const Color(0xFFDC2626).withValues(alpha: 0.90);
  static const errorBorder = Color(0xFFB91C1C);

  static final warningBg = const Color(0xFFD97706).withValues(alpha: 0.90);
  static const warningBorder = Color(0xFFB45309);

  static final infoBg = const Color(0xFF2563EB).withValues(alpha: 0.90);
  static const infoBorder = Color(0xFF1D4ED8);

  static const text = Colors.white;
  static const icon = Colors.white;
}

class FeedbackStyles {
  FeedbackStyles._();

  static const borderRadius = 10.0;
  static const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  
  static const borderStyle = BorderSide(width: 1.0);

  static final shadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static const titleStyle = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600, // SemiBold
    color: FeedbackColors.text,
  );

  static const messageStyle = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400, // Regular
    fontSize: 14,
    color: FeedbackColors.text,
  );

  static BackdropFilter get glassFilter => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: const SizedBox.shrink(),
      );
}