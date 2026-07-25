import 'package:flutter/material.dart';

import '../../../../../shared/navigation/adaptive_navigator.dart';
import '../pages/lote_details_page.dart';
import 'lote_details_content.dart';

/// Abre o detalhe do lote: Side Sheet (tablet/desktop) ou página (mobile).
Future<void> openLoteDetails(BuildContext context, String loteId) async {
  if (loteId.isEmpty) return;

  await AdaptiveNavigator.openPanel<void>(
    context: context,
    routeSettings: RouteSettings(name: '/lotes/$loteId'),
    builder: (detailContext) {
      if (AdaptiveNavigator.isMobile(detailContext)) {
        return LoteDetailsPage(loteId: loteId);
      }
      return LoteDetailsContent(
        loteId: loteId,
        onClose: () => AdaptiveNavigator.close(detailContext),
      );
    },
  );
}
