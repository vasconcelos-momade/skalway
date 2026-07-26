/// Contrato HTTP da API v1 (`{ success, data }` / `{ success, error }`).
abstract final class ApiEnvelope {
  ApiEnvelope._();

  static const String v1Prefix = '/api/v1';

  /// Garante que o URL base termina em `/api/v1` (sem duplicar o segmento).
  static String resolveBaseUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) {
      return 'http://localhost:4001$v1Prefix';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith(v1Prefix)) {
      return url;
    }
    return '$url$v1Prefix';
  }

  /// Extrai o payload útil de uma resposta JSON (com ou sem envelope).
  /// Metadados opcionais (ex.: `catalogVersion` na pesquisa POS).
  static Map<String, dynamic>? unwrapMeta(Map<String, dynamic> json) {
    final meta = json['meta'];
    if (meta is Map<String, dynamic>) {
      return meta;
    }
    return null;
  }

  static Map<String, dynamic> unwrapMap(Map<String, dynamic> json) {
    if (json['success'] == true) {
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      // Algumas rotas devolvem campos ao lado de `success` (ex.: sessão POS).
      final flattened = <String, dynamic>{};
      json.forEach((key, value) {
        if (key == 'success' || key == 'meta') return;
        flattened[key] = value;
      });
      if (flattened.isNotEmpty) {
        return flattened;
      }
    }
    return json;
  }

  static List<Map<String, dynamic>> unwrapList(dynamic body) {
    if (body is List) {
      return body.whereType<Map<String, dynamic>>().toList();
    }
    if (body is Map<String, dynamic>) {
      if (body['success'] == true) {
        final data = body['data'];
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }
      }
      final items = body['items'];
      if (items is List) {
        return items.whereType<Map<String, dynamic>>().toList();
      }
    }
    return <Map<String, dynamic>>[];
  }
}
