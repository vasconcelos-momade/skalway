import 'base_entity.dart';

/// Entidade com metadados de sincronização offline.
abstract class SyncEntity extends BaseEntity {
  const SyncEntity({
    required super.id,
    required this.updatedAt,
    this.syncedAt,
  });

  final DateTime updatedAt;
  final DateTime? syncedAt;
}
