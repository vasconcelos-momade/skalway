import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/contracts/api_envelope.dart';
import '../../../../../core/contracts/pagination_response.dart';
import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/network/dio/dio_provider.dart';
import '../../domain/entities/invoice_summary.dart';
import '../models/invoice_detail_model.dart';
import '../models/invoice_summary_model.dart';

abstract class InvoiceRemoteDataSource {
  Future<PaginationResponse<InvoiceSummaryModel>> listInvoices(InvoiceQuery query);

  Future<InvoiceDetailModel> getInvoiceDetail(String invoiceId);

  Future<({Uint8List bytes, String fileName, String contentType})> getInvoicePdf(
    String invoiceId,
  );

  Future<
      ({
        Uint8List bytes,
        String fileName,
        String contentType,
        String mode,
        String? tipo,
      })> getInvoicePrintArtifact(String invoiceId);

  Future<void> cancelInvoice({
    required String invoiceId,
    required String motivo,
    String? observacoes,
  });
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  InvoiceRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<PaginationResponse<InvoiceSummaryModel>> listInvoices(
    InvoiceQuery query,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPosFaturas,
        queryParameters: <String, dynamic>{
          'page': query.page,
          'pageSize': query.pageSize,
          if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
          if (query.clienteId != null) 'clienteId': query.clienteId,
          if (query.status != null) 'status': query.status,
          if (query.dateFrom != null) 'dateFrom': _formatApiDate(query.dateFrom!),
          if (query.dateTo != null) 'dateTo': _formatApiDate(query.dateTo!),
          if (query.terminalId != null) 'terminalId': query.terminalId,
          if (query.userId != null) 'userId': query.userId,
        },
      );

      final data = response.data;
      if (data == null) {
        return const PaginationResponse<InvoiceSummaryModel>(items: []);
      }

      final rawItems = data['data'];
      final meta = ApiEnvelope.unwrapMeta(data) ?? <String, dynamic>{};
      final items = rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(InvoiceSummaryModel.fromJson)
              .toList()
          : <InvoiceSummaryModel>[];

      final rawSummary = meta['summary'];
      return PaginationResponse<InvoiceSummaryModel>(
        items: items,
        page: _asInt(meta['page'], fallback: query.page),
        pageSize: _asInt(meta['pageSize'], fallback: query.pageSize),
        hasMore: meta['hasMore'] == true,
        summary: rawSummary is Map<String, dynamic>
            ? PaginationSummary.fromJson(rawSummary)
            : null,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<InvoiceDetailModel> getInvoiceDetail(String invoiceId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPosFaturaDetalhe(invoiceId),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Falha ao carregar detalhe da fatura.');
      }
      return InvoiceDetailModel.fromJson(ApiEnvelope.unwrapMap(data));
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<({Uint8List bytes, String fileName, String contentType})> getInvoicePdf(
    String invoiceId,
  ) async {
    try {
      // POS /pdf: FR → PDF 80mm; FT → PDF A4
      final response = await _dio.get<List<int>>(
        ApiConstants.tenantPosFaturaPdf(invoiceId),
        options: Options(responseType: ResponseType.bytes),
      );

      final rawBytes = response.data;
      if (rawBytes == null || rawBytes.isEmpty) {
        throw const ApiFailure('Falha ao carregar PDF da fatura.');
      }

      final headers = response.headers;
      final disposition = headers.value('content-disposition');
      final contentType =
          headers.value(Headers.contentTypeHeader) ?? 'application/pdf';

      return (
        bytes: Uint8List.fromList(rawBytes),
        fileName: _extractFileName(
          disposition,
          fallback: 'fatura-$invoiceId.pdf',
        ),
        contentType: contentType,
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  @override
  Future<
      ({
        Uint8List bytes,
        String fileName,
        String contentType,
        String mode,
        String? tipo,
      })> getInvoicePrintArtifact(String invoiceId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.tenantPosFaturaPrint(invoiceId),
      );
      final data = response.data;
      if (data == null) {
        throw const ApiFailure('Falha ao carregar artefacto de impressão.');
      }

      final payload = ApiEnvelope.unwrapMap(data);
      final payloadBase64 = payload['payloadBase64']?.toString();
      if (payloadBase64 == null || payloadBase64.isEmpty) {
        throw const ApiFailure('Resposta inválida do artefacto de impressão.');
      }

      final contentType =
          payload['contentType']?.toString().trim().isNotEmpty == true
              ? payload['contentType'].toString().trim()
              : 'application/octet-stream';
      final mode = payload['mode']?.toString().trim().isNotEmpty == true
          ? payload['mode'].toString().trim()
          : (contentType.contains('pdf') ? 'pdf_a4' : 'thermal_80mm');

      return (
        bytes: base64Decode(payloadBase64),
        fileName:
            payload['fileName']?.toString().trim().isNotEmpty == true
            ? payload['fileName'].toString().trim()
            : (mode == 'pdf_a4'
                ? 'fatura-$invoiceId.pdf'
                : 'fatura-$invoiceId.escpos'),
        contentType: contentType,
        mode: mode,
        tipo: payload['tipo']?.toString(),
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    } on FormatException {
      throw const ApiFailure('Payload de impressão inválido.');
    }
  }

  @override
  Future<void> cancelInvoice({
    required String invoiceId,
    required String motivo,
    String? observacoes,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiConstants.tenantPosCancelarFatura(invoiceId),
        data: <String, dynamic>{
          'motivo': motivo.trim(),
          if (observacoes != null && observacoes.trim().isNotEmpty)
            'observacoes': observacoes.trim(),
        },
      );
    } on DioException catch (e) {
      throw ApiFailure.fromDio(e);
    }
  }

  String _formatApiDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  int _asInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  String _extractFileName(String? disposition, {required String fallback}) {
    if (disposition == null || disposition.trim().isEmpty) {
      return fallback;
    }

    final utf8Match = RegExp(
      r'''filename\*=UTF-8''([^;]+)''',
      caseSensitive: false,
    ).firstMatch(disposition);
    if (utf8Match != null) {
      return Uri.decodeComponent(utf8Match.group(1)!).trim();
    }

    final quotedMatch = RegExp(
      r'filename="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(disposition);
    if (quotedMatch != null) {
      return quotedMatch.group(1)!.trim();
    }

    final plainMatch = RegExp(
      r'filename=([^;]+)',
      caseSensitive: false,
    ).firstMatch(disposition);
    if (plainMatch != null) {
      return plainMatch.group(1)!.trim();
    }

    return fallback;
  }
}

final invoiceRemoteDataSourceProvider = Provider<InvoiceRemoteDataSource>((ref) {
  return InvoiceRemoteDataSourceImpl(ref.watch(dioProvider));
});
