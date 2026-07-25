import '../../../../pharmacy/products/domain/entities/product.dart';
import '../../data/models/draft_cart_model.dart';
import '../entities/pdv_cart.dart';
import '../entities/pdv_cart_line.dart';
import '../entities/pdv_service.dart';

abstract final class DraftCartMapper {
  DraftCartMapper._();

  static Product productFromItem(DraftCartItemModel item) {
    return Product(
      id: item.produtoId ?? '',
      nomeComercial: item.nome,
      nomeGenerico: item.nomeGenerico,
      dosagem: item.dosagem,
      forma: item.forma,
      ativo: true,
      tipoDispensacao: item.tipoDispensacao ?? 'VENDA_LIVRE',
      requiresPrescription: item.requiresPrescription,
      requiresDoubleCheck: item.requiresDoubleCheck,
      requiresPsychotropicBook: item.requiresPsychotropicBook,
      precoVenda: item.precoUnit,
      estoqueAtual: item.estoqueAtual ?? 0,
      estoqueMinimo: 0,
      taxRule: item.taxRule,
    );
  }

  static PdvService serviceFromItem(DraftCartItemModel item) {
    return PdvService(
      id: item.servicoId ?? '',
      nome: item.nome,
      preco: item.precoUnit,
      tipoServicoClinico: item.tipoServicoClinico,
    );
  }

  static PdvCartLine lineFromItem(DraftCartItemModel item) {
    if (item.isServico) {
      return PdvCartLine.service(
        serviceFromItem(item),
        item.quantidade,
        faturaItemId: item.id,
        lineTotal: item.total,
        baseCalculo: item.baseCalculo,
        valorIva: item.valorIva,
        ivaLabel: item.ivaLabel,
      );
    }
    return PdvCartLine.product(
      productFromItem(item),
      item.quantidade,
      faturaItemId: item.id,
      lineTotal: item.total,
      baseCalculo: item.baseCalculo,
      valorIva: item.valorIva,
      ivaLabel: item.ivaLabel,
    );
  }

  static PdvCart toEntity(DraftCartModel model) {
    final lines = model.items.map(lineFromItem).toList();
    final checkout = model.checkout;

    return PdvCart(
      draftFaturaId: model.hasDraft ? model.id : null,
      idempotencyKey: model.idempotencyKey,
      lines: lines,
      subtotal: model.subtotal,
      tax: model.ivaTotal,
      discount: model.desconto,
      total: model.total,
      taxLabel: checkout?.taxLabel ?? 'IVA',
      requiresPatientDetails: checkout?.requiresPatientDetails ?? false,
    );
  }
}
