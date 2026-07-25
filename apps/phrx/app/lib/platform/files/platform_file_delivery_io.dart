import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<void> openBytesImpl({
  required Uint8List bytes,
  required String fileName,
  required String contentType,
}) async {
  final file = await _writeFile(
    directory: await getTemporaryDirectory(),
    fileName: fileName,
    bytes: bytes,
  );
  await _openFile(file);
}

Future<void> downloadBytesImpl({
  required Uint8List bytes,
  required String fileName,
  required String contentType,
}) async {
  final baseDirectory = await getApplicationDocumentsDirectory();
  final downloadsDirectory = Directory('${baseDirectory.path}/downloads');
  final file = await _writeFile(
    directory: downloadsDirectory,
    fileName: fileName,
    bytes: bytes,
  );
  await _openFile(file);
}

Future<File> _writeFile({
  required Directory directory,
  required String fileName,
  required Uint8List bytes,
}) async {
  await directory.create(recursive: true);
  final sanitizedName = _sanitizeFileName(fileName);
  final file = File('${directory.path}/$sanitizedName');
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Future<void> _openFile(File file) async {
  final result = await OpenFilex.open(file.path);
  if (result.type != ResultType.done) {
    throw FileSystemException(result.message, file.path);
  }
}

String _sanitizeFileName(String fileName) {
  final normalized = fileName.trim();
  if (normalized.isEmpty) {
    return 'documento.bin';
  }

  return normalized.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}
