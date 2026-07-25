import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/pharma_surface.dart';
import '../../../../../shared/widgets/cards/enterprise_list_card.dart';
import '../../../pdv/presentation/widgets/pdv_catalog_utils.dart';
import '../../domain/entities/proforma_invoice_cart_line.dart';

class ProformaInvoiceCartItemCard extends StatefulWidget {
  const ProformaInvoiceCartItemCard({
    super.key,
    required this.line,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final ProformaInvoiceCartLine line;
  final ValueChanged<ProformaInvoiceCartLine> onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  State<ProformaInvoiceCartItemCard> createState() =>
      _ProformaInvoiceCartItemCardState();
}

class _ProformaInvoiceCartItemCardState
    extends State<ProformaInvoiceCartItemCard> {
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _obsController;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.line);
  }

  @override
  void didUpdateWidget(covariant ProformaInvoiceCartItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line.id != widget.line.id) {
      _qtyController.text = _formatQty(widget.line.quantidade);
      _priceController.text = widget.line.precoUnitario.toStringAsFixed(2);
      _discountController.text = widget.line.descontoPercent.toStringAsFixed(0);
      _obsController.text = widget.line.observacao ?? '';
      return;
    }
    if (oldWidget.line.quantidade != widget.line.quantidade) {
      _qtyController.text = _formatQty(widget.line.quantidade);
    }
    if (oldWidget.line.precoUnitario != widget.line.precoUnitario) {
      _priceController.text = widget.line.precoUnitario.toStringAsFixed(2);
    }
    if (oldWidget.line.descontoPercent != widget.line.descontoPercent) {
      _discountController.text = widget.line.descontoPercent.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  void _initControllers(ProformaInvoiceCartLine line) {
    _qtyController = TextEditingController(text: _formatQty(line.quantidade));
    _priceController =
        TextEditingController(text: line.precoUnitario.toStringAsFixed(2));
    _discountController =
        TextEditingController(text: line.descontoPercent.toStringAsFixed(0));
    _obsController = TextEditingController(text: line.observacao ?? '');
  }

  String _formatQty(double value) {
    return value == value.truncateToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  double _parse(String text, {double fallback = 0}) {
    final normalized = text.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? fallback;
  }

  void _commit({
    double? quantidade,
    double? preco,
    double? desconto,
    String? observacao,
  }) {
    widget.onChanged(
      widget.line.copyWith(
        quantidade: quantidade,
        precoUnitario: preco,
        descontoPercent: desconto,
        observacao: observacao,
        clearObservacao: observacao != null && observacao.isEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final line = widget.line;
    final textTheme = Theme.of(context).textTheme;

    return PharmaSurface(
      padding: EdgeInsets.all(s.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                line.isProduct
                    ? Icons.medication_outlined
                    : Icons.medical_services_outlined,
                color: t.textSecondary,
              ),
              SizedBox(width: s.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.nome,
                      style: textTheme.erpLabel.copyWith(color: t.textPrimary),
                    ),
                    SizedBox(height: s.xxs),
                    Text(
                      'Cód. ${line.codigo} • ${line.unidade}',
                      style: textTheme.erpCaption.copyWith(color: t.textMuted),
                    ),
                    if (!line.ativo) ...[
                      SizedBox(height: s.xs),
                      EnterpriseStatusChip(label: 'Inactivo', color: t.textMuted),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remover',
                onPressed: line.allowPriceEdit ? widget.onRemove : null,
                icon: Icon(Icons.delete_outline_rounded, color: t.posDanger),
              ),
            ],
          ),
          SizedBox(height: s.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyController,
                  enabled: line.allowPriceEdit,
                  decoration: const InputDecoration(
                    labelText: 'Qtd.',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onSubmitted: (value) {
                    final qty = _parse(value, fallback: line.quantidade);
                    if (qty > 0) {
                      _commit(quantidade: qty);
                    }
                  },
                ),
              ),
              IconButton(
                onPressed: line.allowPriceEdit ? widget.onDecrement : null,
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              Text(_formatQty(line.quantidade), style: textTheme.erpLabel),
              IconButton(
                onPressed: line.allowPriceEdit ? widget.onIncrement : null,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          SizedBox(height: s.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  enabled: line.allowPriceEdit,
                  decoration: const InputDecoration(
                    labelText: 'Preço unit.',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (value) {
                    final price = _parse(value, fallback: line.precoUnitario);
                    if (price > 0) {
                      _commit(preco: price);
                    }
                  },
                ),
              ),
              SizedBox(width: s.sm),
              Expanded(
                child: TextField(
                  controller: _discountController,
                  enabled: line.allowPriceEdit,
                  decoration: const InputDecoration(
                    labelText: 'Desc. %',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (value) {
                    _commit(desconto: _parse(value).clamp(0, 100).toDouble());
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: s.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Desc. ${pdvFormatMoney(line.descontoValor)}',
                style: textTheme.erpCaption.copyWith(color: t.posDanger),
              ),
              Text(
                '${line.ivaLabel} • ${pdvFormatMoney(line.valorIva)}',
                style: textTheme.erpCaption.copyWith(color: t.textSecondary),
              ),
              Text(
                pdvFormatMoney(line.total),
                style: textTheme.erpLabel.copyWith(color: t.brandGreen),
              ),
            ],
          ),
          SizedBox(height: s.sm),
          TextField(
            controller: _obsController,
            enabled: line.allowPriceEdit,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onSubmitted: (value) => _commit(observacao: value.trim()),
          ),
        ],
      ),
    );
  }
}
