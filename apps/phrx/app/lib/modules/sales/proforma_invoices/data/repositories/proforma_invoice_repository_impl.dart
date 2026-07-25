import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/proforma_invoice.dart';
import '../../domain/entities/proforma_invoice_cart_line.dart';
import '../../domain/repositories/proforma_invoice_repository.dart';
import '../datasources/proforma_invoice_remote_datasource.dart';

class ProformaInvoiceRepositoryImpl implements ProformaInvoiceRepository {
  ProformaInvoiceRepositoryImpl(this._remote);

  final ProformaInvoiceRemoteDataSource _remote;

  @override
  Future<ProformaInvoiceCreateResult> createProformaInvoice({
    required String cliente,
    String? clienteId,
    String? nuit,
    String? contacto,
    double? descontoGeral,
    required DateTime validade,
    String? observacoes,
    required List<ProformaInvoiceCartLine> lines,
  }) async {
    final payload = _buildHeaderPayload(
      cliente: cliente,
      clienteId: clienteId,
      nuit: nuit,
      contacto: contacto,
      descontoGeral: descontoGeral,
      validade: validade,
      observacoes: observacoes,
    )
      ..['items'] = lines.map(_buildItemPayload).toList(growable: false);

    final data = await _remote.create(payload);
    final detail = _parseProformaInvoiceDetail(data);
    return ProformaInvoiceCreateResult(
      id: data['id']?.toString() ?? '',
      numero: data['numero']?.toString() ?? '',
      total: _toDouble(data['total']),
      detail: detail,
    );
  }

  @override
  Future<ProformaInvoiceDetail> getProformaInvoice(String proformaInvoiceId) async {
    final data = await _remote.getById(proformaInvoiceId);
    return _parseProformaInvoiceDetail(data);
  }

  @override
  Future<ProformaInvoiceDetail> updateProformaInvoiceHeader({
    required String proformaInvoiceId,
    required String cliente,
    String? clienteId,
    String? nuit,
    String? contacto,
    double? descontoGeral,
    required DateTime validade,
    String? observacoes,
  }) async {
    final data = await _remote.update(
      proformaInvoiceId,
      _buildHeaderPayload(
        cliente: cliente,
        clienteId: clienteId,
        nuit: nuit,
        contacto: contacto,
        descontoGeral: descontoGeral,
        validade: validade,
        observacoes: observacoes,
      ),
    );
    return _parseProformaInvoiceDetail(data);
  }

  @override
  Future<ProformaInvoiceDetail> addProformaInvoiceItem({
    required String proformaInvoiceId,
    required ProformaInvoiceCartLine line,
  }) async {
    final data = await _remote.addItem(proformaInvoiceId, _buildItemPayload(line));
    return _parseProformaInvoiceDetail(data);
  }

  @override
  Future<ProformaInvoiceDetail> updateProformaInvoiceItem({
    required String proformaInvoiceId,
    required String itemId,
    required ProformaInvoiceCartLine line,
  }) async {
    final data = await _remote.updateItem(
      proformaInvoiceId,
      itemId,
      _buildItemUpdatePayload(line),
    );
    return _parseProformaInvoiceDetail(data);
  }

  @override
  Future<ProformaInvoiceDetail> removeProformaInvoiceItem({
    required String proformaInvoiceId,
    required String itemId,
  }) async {
    final data = await _remote.removeItem(proformaInvoiceId, itemId);
    return _parseProformaInvoiceDetail(data);
  }

  @override
  Future<ProformaInvoiceDetail> rejectProformaInvoice({
    required String proformaInvoiceId,
    String? observacoes,
  }) async {
    final data = await _remote.reject(
      proformaInvoiceId,
      observacoes: observacoes,
    );
    return _parseProformaInvoiceDetail(data);
  }

  @override
  Future<ProformaInvoiceDetail> approveProformaInvoice({
    required String proformaInvoiceId,
    String? observacoes,
  }) async {
    final data = await _remote.approve(
      proformaInvoiceId,
      observacoes: observacoes,
    );
    return _parseProformaInvoiceDetail(data);
  }

  @override
  Future<List<ProformaInvoiceSummary>> listProformaInvoiceHistory({
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _remote.list(query: query, page: page, pageSize: pageSize);
    return data
        .map(
          (item) => ProformaInvoiceSummary(
            id: item['id']?.toString() ?? '',
            numero: item['numero']?.toString() ?? '',
            estado: item['estado']?.toString() ?? '',
            clienteNome: item['cliente']?.toString() ?? '',
            total: _toDouble(item['total']),
            validade: _toDateTime(item['validade']),
            createdAt: _toDateTime(item['createdAt']),
            itemCount: _toInt(item['itemCount']),
          ),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> _buildHeaderPayload({
    required String cliente,
    String? clienteId,
    String? nuit,
    String? contacto,
    double? descontoGeral,
    required DateTime validade,
    String? observacoes,
  }) {
    return <String, dynamic>{
      'cliente': cliente.trim(),
      if (clienteId != null && clienteId.trim().isNotEmpty) 'clienteId': clienteId,
      if (nuit != null && nuit.trim().isNotEmpty) 'nuit': nuit.trim(),
      if (contacto != null && contacto.trim().isNotEmpty) 'contacto': contacto.trim(),
      ...?switch (descontoGeral) {
        final desconto? => <String, dynamic>{'desconto': desconto},
        null => null,
      },
      'validade': validade.toUtc().toIso8601String(),
      ...?switch (observacoes?.trim()) {
        final observacao? when observacao.isNotEmpty =>
          <String, dynamic>{'observacoes': observacao},
        _ => null,
      },
    };
  }

  Map<String, dynamic> _buildItemPayload(ProformaInvoiceCartLine line) {
    return <String, dynamic>{
      if (line.product != null) 'produtoId': line.product!.id,
      if (line.service != null) 'servicoId': line.service!.id,
      'quantidade': line.quantidade,
      'precoUnit': line.precoUnitario,
      if (line.descontoPercent > 0) 'descontoPercent': line.descontoPercent,
      if ((line.observacao ?? '').trim().isNotEmpty) 'descricao': line.observacao!.trim(),
    };
  }

  Map<String, dynamic> _buildItemUpdatePayload(ProformaInvoiceCartLine line) {
    return <String, dynamic>{
      'quantidade': line.quantidade,
      'precoUnit': line.precoUnitario,
      if (line.descontoPercent > 0) 'descontoPercent': line.descontoPercent else 'desconto': 0,
      if ((line.observacao ?? '').trim().isNotEmpty) 'descricao': line.observacao!.trim(),
    };
  }

  ProformaInvoiceDetail _parseProformaInvoiceDetail(Map<String, dynamic> data) {
    final itemsRaw = data['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map<String, dynamic>>()
            .map(_parseProformaInvoiceItem)
            .toList(growable: false)
        : const <ProformaInvoiceItem>[];
    return ProformaInvoiceDetail(
      id: data['id']?.toString() ?? '',
      numero: data['numero']?.toString() ?? '',
      estado: data['estado']?.toString() ?? '',
      cliente: data['cliente']?.toString() ?? '',
      clienteId: data['clienteId']?.toString(),
      nuit: data['nuit']?.toString(),
      contacto: data['contacto']?.toString(),
      validade: _toDateTime(data['validade']),
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
      subtotal: _toDouble(data['subtotal']),
      desconto: _toDouble(data['desconto']),
      ivaTotal: _toDouble(data['ivaTotal']),
      total: _toDouble(data['total']),
      itemCount: _toInt(data['itemCount']),
      observacoes: data['observacoes']?.toString(),
      items: items,
    );
  }

  ProformaInvoiceItem _parseProformaInvoiceItem(Map<String, dynamic> data) {
    final produto = data['produto'];
    final servico = data['servico'];
    return ProformaInvoiceItem(
      id: data['id']?.toString() ?? '',
      proformaInvoiceId: data['proformaInvoiceId']?.toString() ?? '',
      tipo: data['tipo']?.toString() ?? '',
      descricao: data['descricao']?.toString() ?? '',
      quantidade: _toDouble(data['quantidade']),
      precoUnit: _toDouble(data['precoUnit']),
      desconto: _toDouble(data['desconto']),
      subtotal: _toDouble(data['subtotal']),
      iva: _toDouble(data['iva']),
      valorIva: _toDouble(data['valorIva']),
      total: _toDouble(data['total']),
      produtoId: data['produtoId']?.toString(),
      servicoId: data['servicoId']?.toString(),
      codigoRegraFiscal: data['codigoRegraFiscal']?.toString(),
      produtoNome: produto is Map<String, dynamic> ? produto['nome']?.toString() : null,
      produtoBarcode: produto is Map<String, dynamic> ? produto['barcode']?.toString() : null,
      servicoNome: servico is Map<String, dynamic> ? servico['nome']?.toString() : null,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}

final proformaInvoiceRepositoryProvider = Provider<ProformaInvoiceRepository>((ref) {
  return ProformaInvoiceRepositoryImpl(
    ref.watch(proformaInvoiceRemoteDataSourceProvider),
  );
});
