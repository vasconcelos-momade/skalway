import 'package:flutter/material.dart';

import 'enterprise_bottom_sheet.dart';

Future<T?> showPharmaModalSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  String? subtitle,
}) {
  return showEnterpriseBottomSheet<T>(
    context: context,
    title: Text(title),
    subtitle: subtitle,
    body: child,
  );
}
