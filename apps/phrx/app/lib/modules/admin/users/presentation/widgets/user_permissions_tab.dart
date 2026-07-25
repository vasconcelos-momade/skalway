import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/errors/api_failure.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/feedback/pharma_feedback.dart';
import '../../../../../shared/widgets/tables/enterprise_data_table.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user_entities.dart';
import '../providers/permission_matrix_provider.dart';

class UserPermissionsTab extends ConsumerStatefulWidget {
  const UserPermissionsTab({
    super.key,
    required this.userId,
    required this.role,
    required this.overrides,
    required this.onSaved,
  });

  final String userId;
  final String role;
  final List<UserPermissionOverride> overrides;
  final VoidCallback onSaved;

  @override
  ConsumerState<UserPermissionsTab> createState() => _UserPermissionsTabState();
}

class _UserPermissionsTabState extends ConsumerState<UserPermissionsTab> {
  var _loading = true;
  var _saving = false;
  var _editing = false;
  String? _error;
  List<PermissionMatrixRow> _matrix = const [];
  UserEffectivePermissions? _effective;
  Map<String, Map<String, bool?>> _overrideState = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant UserPermissionsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.role != widget.role ||
        oldWidget.overrides != widget.overrides) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _editing = false;
    });

    try {
      final userRepo = ref.read(userRepositoryProvider);
      final permRepo = ref.read(permissionRepositoryProvider);
      final results = await Future.wait([
        permRepo.getMatrix(role: widget.role),
        userRepo.getUserEffectivePermissions(widget.userId),
      ]);

      if (!mounted) return;
      setState(() {
        _matrix = results[0] as List<PermissionMatrixRow>;
        _effective = results[1] as UserEffectivePermissions;
        _overrideState = _buildOverrideState(_matrix, widget.overrides);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Map<String, Map<String, bool?>> _buildOverrideState(
    List<PermissionMatrixRow> matrix,
    List<UserPermissionOverride> overrides,
  ) {
    final explicit = {
      for (final o in overrides) '${o.module}:${o.action}': o.allowed,
    };

    return {
      for (final row in matrix)
        row.module: {
          for (final action in permissionMatrixActions)
            action: explicit.containsKey('${row.module}:$action')
                ? explicit['${row.module}:$action']
                : null,
        },
    };
  }

  bool _roleAllows(String module, String action) {
    final row = _matrix.where((r) => r.module == module).firstOrNull;
    return row?.actions[action] == true;
  }

  bool _effectiveAllowed(String module, String action) {
    final override = _overrideState[module]?[action];
    if (override != null) return override;
    return _roleAllows(module, action);
  }

  bool get _hasChanges {
    final original = {
      for (final o in widget.overrides) '${o.module}:${o.action}': o.allowed,
    };

    for (final row in _matrix) {
      for (final action in permissionMatrixActions) {
        final key = '${row.module}:$action';
        final before = original.containsKey(key) ? original[key] : null;
        final after = _overrideState[row.module]?[action];
        if (before != after) return true;
      }
    }
    return false;
  }

  void _toggle(String module, String action) {
    final roleAllowed = _roleAllows(module, action);
    final current = _effectiveAllowed(module, action);
    final next = !current;

    final updated = Map<String, Map<String, bool?>>.from(_overrideState);
    final moduleMap = Map<String, bool?>.from(updated[module] ?? {});
    moduleMap[action] = next == roleAllowed ? null : next;
    updated[module] = moduleMap;
    setState(() => _overrideState = updated);
  }

  void _discard() {
    setState(() {
      _overrideState = _buildOverrideState(_matrix, widget.overrides);
      _editing = false;
    });
  }

  Future<void> _save() async {
    if (!_hasChanges) return;

    setState(() => _saving = true);

    try {
      final original = {
        for (final o in widget.overrides) '${o.module}:${o.action}': o.allowed,
      };
      final changes = <UserPermissionGrant>[];

      for (final row in _matrix) {
        for (final action in permissionMatrixActions) {
          final key = '${row.module}:$action';
          final before = original.containsKey(key) ? original[key] : null;
          final after = _overrideState[row.module]?[action];
          if (before == after) continue;

          if (after == null) {
            changes.add(UserPermissionGrant(
              module: row.module,
              action: action,
              clear: true,
            ));
          } else {
            changes.add(UserPermissionGrant(
              module: row.module,
              action: action,
              allowed: after,
            ));
          }
        }
      }

      await ref.read(userRepositoryProvider).updateUserPermissions(
            widget.userId,
            changes,
          );

      if (!mounted) return;
      PharmaFeedback.success(context, 'Overrides actualizados');
      widget.onSaved();
      await _load();
    } on ApiFailure catch (e) {
      if (mounted) PharmaFeedback.error(context, e.message);
    } catch (e) {
      if (mounted) PharmaFeedback.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: Theme.of(context).textTheme.erpBody.copyWith(color: t.posDanger),
            ),
            SizedBox(height: s.sm),
            OutlinedButton(onPressed: _load, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }

    final overrideCount =
        _effective?.permissions.where((p) => p.isOverride).length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(s.lg, s.md, s.lg, s.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perfil ${widget.role}',
                      style: Theme.of(context).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
                    ),
                    Text(
                      '$overrideCount override(s) • ${_effective?.permissions.where((p) => p.allowed).length ?? 0} permissões efectivas',
                      style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
                    ),
                  ],
                ),
              ),
              if (!_editing)
                FilledButton.tonalIcon(
                  onPressed: _saving ? null : () => setState(() => _editing = true),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Editar overrides'),
                )
              else ...[
                TextButton(
                  onPressed: _saving ? null : _discard,
                  child: const Text('Descartar'),
                ),
                FilledButton(
                  onPressed: !_hasChanges || _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            ],
          ),
        ),
        if (_editing)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: s.lg),
            child: Text(
              'Marque para conceder ou retire para negar face ao perfil. '
              'Quando o valor coincide com o perfil, o override é removido.',
              style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
            ),
          ),
        SizedBox(height: s.sm),
        Expanded(
          child: _editing ? _buildEditor(t) : _buildReadOnly(t, s),
        ),
      ],
    );
  }

  Widget _buildReadOnly(PharmaTokens t, DensityTokens s) {
    final perms = _effective?.permissions ?? const <UserEffectivePermission>[];
    if (perms.isEmpty) {
      return Center(
        child: Text(
          'Sem permissões efectivas para este perfil.',
          style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
        ),
      );
    }

    final sorted = [...perms]
      ..sort((a, b) {
        final moduleCmp = a.module.compareTo(b.module);
        if (moduleCmp != 0) return moduleCmp;
        return a.action.compareTo(b.action);
      });

    return ListView.separated(
      padding: EdgeInsets.all(s.lg),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => Divider(color: t.border.withValues(alpha: 0.35)),
      itemBuilder: (context, index) {
        final p = sorted[index];
        return ListTile(
          dense: true,
          title: Text(
            '${p.module} • ${p.action}',
            style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
          ),
          subtitle: Text(
            p.isOverride ? 'Override' : 'Herdado do perfil',
            style: Theme.of(context).textTheme.erpCaption.copyWith(
                  color: p.isOverride ? t.brandBlue : t.textMuted,
                ),
          ),
          trailing: Icon(
            p.allowed ? Icons.check_circle : Icons.cancel,
            color: p.allowed ? t.brandGreen : t.posDanger,
            size: 20,
          ),
        );
      },
    );
  }

  Widget _buildEditor(PharmaTokens t) {
    if (_matrix.isEmpty) {
      return Center(
        child: Text(
          'Matriz de permissões indisponível.',
          style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
        ),
      );
    }

    return EnterpriseDataTable(
      columns: [
        DataColumn(
          label: Text(
            'MÓDULO',
            style: Theme.of(context).textTheme.erpOverline.copyWith(color: t.textMuted),
          ),
        ),
        for (final action in permissionMatrixActions)
          DataColumn(
            label: Text(
              action,
              style: Theme.of(context).textTheme.erpOverline.copyWith(color: t.textMuted),
            ),
          ),
      ],
      rowCount: _matrix.length,
      rowBuilder: (context, index) {
        final row = _matrix[index];
        return DataRow(
          cells: [
            DataCell(Text(
              row.module,
              style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
            )),
            for (final action in permissionMatrixActions)
              DataCell(_buildEditorCell(t, row.module, action)),
          ],
        );
      },
    );
  }

  Widget _buildEditorCell(PharmaTokens t, String module, String action) {
    final roleAllowed = _roleAllows(module, action);
    final override = _overrideState[module]?[action];
    final effective = _effectiveAllowed(module, action);
    final hasOverride = override != null;

    return Tooltip(
      message: hasOverride
          ? 'Override ${effective ? 'concedido' : 'negado'} (perfil: ${roleAllowed ? 'sim' : 'não'})'
          : 'Herdado do perfil (${roleAllowed ? 'sim' : 'não'})',
      child: Container(
        decoration: hasOverride
            ? BoxDecoration(
                border: Border.all(
                  color: effective ? t.brandBlue : t.posDanger,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: Checkbox(
          value: effective,
          tristate: false,
          onChanged: _saving ? null : (_) => _toggle(module, action),
        ),
      ),
    );
  }
}
