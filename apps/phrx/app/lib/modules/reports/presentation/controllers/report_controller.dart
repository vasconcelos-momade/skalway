import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/api_failure.dart';
import '../../../../platform/files/platform_file_delivery.dart';
import '../../data/report_repository.dart';

class ReportActionState {
  const ReportActionState({
    this.isSubmitting = false,
    this.activeAction,
    this.errorMessage,
  });

  final bool isSubmitting;
  final String? activeAction;
  final String? errorMessage;

  ReportActionState copyWith({
    bool? isSubmitting,
    String? activeAction,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReportActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      activeAction: activeAction ?? this.activeAction,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ReportController extends Notifier<ReportActionState> {
  @override
  ReportActionState build() => const ReportActionState();

  Future<void> previewPdf({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _runAction(
      action: 'preview-pdf',
      task: () async {
        final document = await ref.read(reportRepositoryProvider).fetchReport(
              path: path,
              format: 'pdf',
              disposition: 'inline',
              queryParameters: queryParameters,
            );
        await PlatformFileDelivery.openBytes(
          bytes: document.bytes,
          fileName: document.fileName,
          contentType: document.contentType,
        );
      },
    );
  }

  Future<void> downloadPdf({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _downloadReport(
      action: 'download-pdf',
      path: path,
      format: 'pdf',
      queryParameters: queryParameters,
    );
  }

  Future<void> printPdf({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) {
    return previewPdf(path: path, queryParameters: queryParameters);
  }

  Future<void> exportCsv({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _downloadReport(
      action: 'export-csv',
      path: path,
      format: 'csv',
      queryParameters: queryParameters,
    );
  }

  Future<void> exportExcel({
    required String path,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _downloadReport(
      action: 'export-excel',
      path: path,
      format: 'excel',
      queryParameters: queryParameters,
    );
  }

  Future<void> _downloadReport({
    required String action,
    required String path,
    required String format,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _runAction(
      action: action,
      task: () async {
        final document = await ref.read(reportRepositoryProvider).fetchReport(
              path: path,
              format: format,
              disposition: 'attachment',
              queryParameters: queryParameters,
            );
        await PlatformFileDelivery.downloadBytes(
          bytes: document.bytes,
          fileName: document.fileName,
          contentType: document.contentType,
        );
      },
    );
  }

  Future<void> _runAction({
    required String action,
    required Future<void> Function() task,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      activeAction: action,
      clearError: true,
    );

    try {
      await task();
      state = state.copyWith(
        isSubmitting: false,
        activeAction: null,
        clearError: true,
      );
    } on ApiFailure catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        activeAction: null,
        errorMessage: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        activeAction: null,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}

final reportControllerProvider =
    NotifierProvider<ReportController, ReportActionState>(
  ReportController.new,
);
