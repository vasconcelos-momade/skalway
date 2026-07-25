import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/proforma_invoice_repository_impl.dart';
import '../../domain/entities/proforma_invoice.dart';
import '../../../../pharmacy/products/domain/entities/product.dart';
import '../../../pdv/domain/entities/pdv_service.dart';
import '../../domain/entities/proforma_invoice_cart_line.dart';
import '../widgets/save_proforma_invoice_dialog.dart';

class ProformaInvoiceCartState {
  const ProformaInvoiceCartState({
    this.detail,
    this.isBusy = false,
    this.isSavingHeader = false,
    this.errorMessage,
    this.history = const <ProformaInvoiceSummary>[],
    this.isLoadingHistory = false,
  });

  final ProformaInvoiceDetail? detail;
  final bool isBusy;
  final bool isSavingHeader;
  final String? errorMessage;
  final List<ProformaInvoiceSummary> history;
  final bool isLoadingHistory;

  bool get hasProformaInvoice => detail != null;
  String? get proformaInvoiceId => detail?.id;
  String get proformaInvoiceNumero => detail?.numero ?? '';
  String get proformaInvoiceEstado => detail?.estado ?? '';

  List<ProformaInvoiceCartLine> get lines {
    final detail = this.detail;
    if (detail == null) {
      return const <ProformaInvoiceCartLine>[];
    }
    return detail
        .items
        .map((item) => _mapItemToLine(item, allowPriceEdit: detail.canEdit))
        .toList(growable: false);
  }

  bool get isEmpty => lines.isEmpty;
  int get itemCount => detail?.itemCount ?? 0;
  double get subtotal => detail?.subtotal ?? 0;
  double get descontoTotal => detail?.desconto ?? 0;
  double get ivaTotal => detail?.ivaTotal ?? 0;
  double get total => detail?.total ?? 0;
  String? get cliente => detail?.cliente;
  String? get clienteId => detail?.clienteId;
  String? get nuit => detail?.nuit;
  String? get contacto => detail?.contacto;
  DateTime? get validade => detail?.validade;
  String? get observacoes => detail?.observacoes;

  ProformaInvoiceCartState copyWith({
    ProformaInvoiceDetail? detail,
    bool? isBusy,
    bool? isSavingHeader,
    String? errorMessage,
    List<ProformaInvoiceSummary>? history,
    bool? isLoadingHistory,
    bool clearDetail = false,
    bool clearError = false,
  }) {
    return ProformaInvoiceCartState(
      detail: clearDetail ? null : (detail ?? this.detail),
      isBusy: isBusy ?? this.isBusy,
      isSavingHeader: isSavingHeader ?? this.isSavingHeader,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      history: history ?? this.history,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }

  static ProformaInvoiceCartLine _mapItemToLine(
    ProformaInvoiceItem item, {
    required bool allowPriceEdit,
  }) {
    return ProformaInvoiceCartLine.fromPersistedItem(
      proformaInvoiceId: item.proformaInvoiceId,
      itemId: item.id,
      nome: item.produtoNome ?? item.servicoNome ?? item.descricao,
      codigo: item.produtoBarcode ?? item.produtoId ?? item.servicoId ?? item.id,
      unidade: 'un',
      quantidade: item.quantidade,
      precoUnitario: item.precoUnit,
      descontoValor: item.desconto,
      subtotal: item.subtotal,
      valorIva: item.valorIva,
      total: item.total,
      ivaPercent: item.iva,
      ivaLabel: '${item.iva.toStringAsFixed(item.iva % 1 == 0 ? 0 : 2)}% IVA',
      observacao: item.descricao,
      allowPriceEdit: allowPriceEdit,
      product: item.produtoId != null
          ? Product(
              id: item.produtoId!,
              nomeComercial: item.produtoNome ?? item.descricao,
              barcode: item.produtoBarcode,
              tipoDispensacao: 'RECEITA_NORMAL',
              requiresPrescription: false,
              requiresDoubleCheck: false,
              requiresPsychotropicBook: false,
              precoVenda: item.precoUnit,
              estoqueAtual: 0,
              estoqueMinimo: 0,
              ativo: true,
            )
          : null,
      service: item.servicoId != null
          ? PdvService(
              id: item.servicoId!,
              nome: item.servicoNome ?? item.descricao,
              preco: item.precoUnit,
            )
          : null,
    );
  }
}

class ProformaInvoiceCartController extends Notifier<ProformaInvoiceCartState> {
  @override
  ProformaInvoiceCartState build() {
    Future.microtask(loadHistory);
    return const ProformaInvoiceCartState();
  }

  Future<void> createProformaInvoice({
    required SaveProformaInvoiceDialogResult header,
    List<ProformaInvoiceCartLine> initialLines =
        const <ProformaInvoiceCartLine>[],
  }) async {
    state = state.copyWith(isSavingHeader: true, clearError: true);
    try {
      final created = await ref
          .read(proformaInvoiceRepositoryProvider)
          .createProformaInvoice(
            cliente: header.cliente,
            clienteId: header.clienteId,
            nuit: header.nuit,
            contacto: header.contacto,
            descontoGeral: header.descontoGeral,
            validade: header.validade,
            observacoes: header.observacoes,
            lines: initialLines,
          );
      state = state.copyWith(
        detail: created.detail,
        isSavingHeader: false,
        clearError: true,
      );
      await loadHistory();
    } catch (e) {
      state = state.copyWith(
        isSavingHeader: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> updateHeader(SaveProformaInvoiceDialogResult header) async {
    final proformaInvoiceId = state.proformaInvoiceId;
    if (proformaInvoiceId == null) {
      await createProformaInvoice(header: header);
      return;
    }
    state = state.copyWith(isSavingHeader: true, clearError: true);
    try {
      final detail = await ref
          .read(proformaInvoiceRepositoryProvider)
          .updateProformaInvoiceHeader(
            proformaInvoiceId: proformaInvoiceId,
            cliente: header.cliente,
            clienteId: header.clienteId,
            nuit: header.nuit,
            contacto: header.contacto,
            descontoGeral: header.descontoGeral,
            validade: header.validade,
            observacoes: header.observacoes,
          );
      state = state.copyWith(
        detail: detail,
        isSavingHeader: false,
        clearError: true,
      );
      await loadHistory();
    } catch (e) {
      state = state.copyWith(
        isSavingHeader: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> addProduct(Product product) {
    return _addLine(ProformaInvoiceCartLine.fromProduct(product));
  }

  Future<void> addService(PdvService service) {
    return _addLine(ProformaInvoiceCartLine.fromService(service));
  }

  Future<void> incrementLine(ProformaInvoiceCartLine line) async {
    await updateLine(line.copyWith(quantidade: line.quantidade + 1));
  }

  Future<void> decrementLine(ProformaInvoiceCartLine line) async {
    if (line.quantidade <= 1) {
      await removeLine(line);
      return;
    }
    await updateLine(line.copyWith(quantidade: line.quantidade - 1));
  }

  Future<void> removeLine(ProformaInvoiceCartLine line) async {
    final proformaInvoiceId = state.proformaInvoiceId;
    final itemId = line.proformaInvoiceItemId;
    if (proformaInvoiceId == null || itemId == null) {
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final detail = await ref
          .read(proformaInvoiceRepositoryProvider)
          .removeProformaInvoiceItem(
            proformaInvoiceId: proformaInvoiceId,
            itemId: itemId,
          );
      state = state.copyWith(detail: detail, isBusy: false, clearError: true);
      await loadHistory();
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> updateLine(ProformaInvoiceCartLine line) async {
    final proformaInvoiceId = state.proformaInvoiceId;
    final itemId = line.proformaInvoiceItemId;
    if (proformaInvoiceId == null || itemId == null) {
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final detail = await ref
          .read(proformaInvoiceRepositoryProvider)
          .updateProformaInvoiceItem(
            proformaInvoiceId: proformaInvoiceId,
            itemId: itemId,
            line: line,
          );
      state = state.copyWith(detail: detail, isBusy: false, clearError: true);
      await loadHistory();
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> clear() async {
    final lines = List<ProformaInvoiceCartLine>.of(state.lines);
    for (final line in lines) {
      await removeLine(line);
    }
  }

  Future<void> cancelProformaInvoice({String? observacoes}) async {
    final proformaInvoiceId = state.proformaInvoiceId;
    if (proformaInvoiceId == null) {
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final detail = await ref
          .read(proformaInvoiceRepositoryProvider)
          .rejectProformaInvoice(
            proformaInvoiceId: proformaInvoiceId,
            observacoes: observacoes,
          );
      state = state.copyWith(detail: detail, isBusy: false, clearError: true);
      await loadHistory();
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> approveProformaInvoice({String? observacoes}) async {
    final proformaInvoiceId = state.proformaInvoiceId;
    if (proformaInvoiceId == null) {
      return;
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final detail = await ref
          .read(proformaInvoiceRepositoryProvider)
          .approveProformaInvoice(
            proformaInvoiceId: proformaInvoiceId,
            observacoes: observacoes,
          );
      state = state.copyWith(detail: detail, isBusy: false, clearError: true);
      await loadHistory();
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> loadHistory({String? query}) async {
    state = state.copyWith(isLoadingHistory: true, clearError: true);
    try {
      final history = await ref
          .read(proformaInvoiceRepositoryProvider)
          .listProformaInvoiceHistory(
            query: query,
            page: 1,
            pageSize: 20,
          );
      state = state.copyWith(
        history: history,
        isLoadingHistory: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> openProformaInvoice(String proformaInvoiceId) async {
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final detail =
          await ref.read(proformaInvoiceRepositoryProvider).getProformaInvoice(proformaInvoiceId);
      state = state.copyWith(detail: detail, isBusy: false, clearError: true);
      await loadHistory();
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: e.toString());
      rethrow;
    }
  }

  void resetComposer() {
    state = state.copyWith(clearDetail: true, isBusy: false, isSavingHeader: false);
  }

  Future<void> _addLine(ProformaInvoiceCartLine line) async {
    final proformaInvoiceId = state.proformaInvoiceId;
    if (proformaInvoiceId == null) {
      throw StateError('Crie a fatura proforma antes de adicionar itens.');
    }
    state = state.copyWith(isBusy: true, clearError: true);
    try {
      final detail = await ref
          .read(proformaInvoiceRepositoryProvider)
          .addProformaInvoiceItem(
            proformaInvoiceId: proformaInvoiceId,
            line: line,
          );
      state = state.copyWith(detail: detail, isBusy: false, clearError: true);
      await loadHistory();
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: e.toString());
      rethrow;
    }
  }
}

final proformaInvoiceCartProvider =
    NotifierProvider<ProformaInvoiceCartController, ProformaInvoiceCartState>(
  ProformaInvoiceCartController.new,
);
