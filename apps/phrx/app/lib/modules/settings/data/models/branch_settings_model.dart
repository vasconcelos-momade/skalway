class BranchSettingsSnapshot {
  const BranchSettingsSnapshot({
    required this.branchId,
    required this.branchCode,
    required this.branchName,
    required this.byKey,
  });

  final String branchId;
  final String? branchCode;
  final String? branchName;
  final Map<String, dynamic> byKey;

  factory BranchSettingsSnapshot.fromJson(Map<String, dynamic> json) {
    final rawByKey = json['byKey'];
    final byKey = <String, dynamic>{};
    if (rawByKey is Map) {
      rawByKey.forEach((key, value) {
        byKey[key.toString()] = value;
      });
    }
    return BranchSettingsSnapshot(
      branchId: json['branchId']?.toString() ?? '',
      branchCode: json['branchCode']?.toString(),
      branchName: json['branchName']?.toString(),
      byKey: byKey,
    );
  }

  String text(String key) {
    final value = byKey[key];
    if (value == null) return '';
    return value.toString();
  }

  bool boolValue(String key, {bool fallback = false}) {
    final value = byKey[key];
    if (value is bool) return value;
    if (value == 'true') return true;
    if (value == 'false') return false;
    return fallback;
  }

  int? intValue(String key) {
    final value = byKey[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
