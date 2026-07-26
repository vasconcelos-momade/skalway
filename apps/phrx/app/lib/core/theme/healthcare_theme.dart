import 'package:flutter/material.dart';

import 'design_tokens.dart';

@immutable
class HealthcareTheme extends ThemeExtension<HealthcareTheme> {
  const HealthcareTheme({
    required this.prescriptionColor,
    required this.dispensedColor,
    required this.controlledMedicineColor,
    required this.batchColor,
    required this.expiryColor,
    required this.expiredColor,
  });

  final Color prescriptionColor;
  final Color dispensedColor;
  final Color controlledMedicineColor;
  final Color batchColor;
  final Color expiryColor;
  final Color expiredColor;

  factory HealthcareTheme.fromLegacy(PharmaTokens tokens) {
    return HealthcareTheme(
      prescriptionColor: tokens.brandGreen,
      dispensedColor: tokens.brandGreen,
      controlledMedicineColor: tokens.psychotropic,
      batchColor: tokens.posInfo,
      expiryColor: tokens.posWarning,
      expiredColor: tokens.posDanger,
    );
  }

  @override
  HealthcareTheme copyWith({
    Color? prescriptionColor,
    Color? dispensedColor,
    Color? controlledMedicineColor,
    Color? batchColor,
    Color? expiryColor,
    Color? expiredColor,
  }) {
    return HealthcareTheme(
      prescriptionColor: prescriptionColor ?? this.prescriptionColor,
      dispensedColor: dispensedColor ?? this.dispensedColor,
      controlledMedicineColor: controlledMedicineColor ?? this.controlledMedicineColor,
      batchColor: batchColor ?? this.batchColor,
      expiryColor: expiryColor ?? this.expiryColor,
      expiredColor: expiredColor ?? this.expiredColor,
    );
  }

  @override
  HealthcareTheme lerp(ThemeExtension<HealthcareTheme>? other, double t) {
    if (other is! HealthcareTheme) return this;
    return t < 0.5 ? this : other;
  }
}

extension HealthcareThemeX on BuildContext {
  HealthcareTheme get healthcareTheme =>
      Theme.of(this).extension<HealthcareTheme>() ??
      HealthcareTheme.fromLegacy(
        Theme.of(this).extension<PharmaTokens>() ?? PharmaTokens.enterpriseLight(),
      );
}
