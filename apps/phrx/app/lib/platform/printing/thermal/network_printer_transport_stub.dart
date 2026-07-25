Future<void> sendNetworkEscPosBytesImpl({
  required String host,
  required int port,
  required List<int> bytes,
}) async {
  throw UnsupportedError(
    'Impressão por rede não suportada nesta plataforma.',
  );
}
