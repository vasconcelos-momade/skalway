import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user_entities.dart';

class UserDetailPanel extends ConsumerStatefulWidget {
  const UserDetailPanel({
    super.key,
    required this.userId,
    required this.onClose,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
  });

  final String userId;
  final VoidCallback onClose;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;

  @override
  ConsumerState<UserDetailPanel> createState() => _UserDetailPanelState();
}

class _UserDetailPanelState extends ConsumerState<UserDetailPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  var _loading = true;
  String? _error;
  TenantUserDetail? _detail;
  List<UserAuditEntry> _audit = [];
  List<UserEventEntry> _events = [];

  static final _dateFmt = DateFormat('dd/MM/yyyy');
  static final _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = ref.read(userRepositoryProvider);
      final detail = await repo.getUser(widget.userId);
      final audit = await repo.listUserAudit(widget.userId);
      final events = await repo.listUserEvents(widget.userId);

      if (!mounted) return;
      setState(() {
        _detail = detail;
        _audit = audit.items;
        _events = events.items;
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

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.sm, s.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _detail?.name ?? 'Utilizador',
                  style: Theme.of(context).textTheme.erpCardTitle.copyWith(color: t.textPrimary),
                ),
              ),
              if (widget.onToggleActive != null)
                IconButton(
                  tooltip: _detail?.active == true ? 'Desactivar' : 'Activar',
                  onPressed: widget.onToggleActive,
                  icon: Icon(
                    _detail?.active == true
                        ? Icons.person_off_outlined
                        : Icons.person_outline,
                  ),
                ),
              if (widget.onEdit != null)
                IconButton(
                  tooltip: 'Editar',
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (widget.onDelete != null)
                IconButton(
                  tooltip: 'Excluir',
                  onPressed: widget.onDelete,
                  icon: Icon(Icons.delete_outline, color: t.posDanger),
                ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dados'),
            Tab(text: 'Auditoria'),
            Tab(text: 'Eventos'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: Theme.of(context).textTheme.erpBody.copyWith(color: t.posDanger),
                      ),
                    )
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _buildDadosTab(t, s),
                        _buildAuditTab(t, s),
                        _buildEventsTab(t, s),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildDadosTab(PharmaTokens t, DensityTokens s) {
    final d = _detail!;
    return ListView(
      padding: EdgeInsets.all(s.lg),
      children: [
        _infoRow(t, 'Email', d.email ?? '—'),
        _infoRow(t, 'Perfil', _roleLabel(d.role)),
        _infoRow(t, 'Estado', d.active ? 'Activo' : 'Inactivo'),
        _infoRow(t, 'Faturas', '${d.stats.faturas}'),
        _infoRow(t, 'Eventos', '${d.stats.eventos}'),
        _infoRow(t, 'Logs auditoria', '${d.stats.auditLogs}'),
        _infoRow(t, 'Registo', _dateFmt.format(d.createdAt)),
        if (d.permissions.isNotEmpty) ...[
          SizedBox(height: s.md),
          Text(
            'Overrides de permissão (${d.permissions.length})',
            style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textMuted),
          ),
          SizedBox(height: s.sm),
          Wrap(
            spacing: s.sm,
            runSpacing: s.sm,
            children: [
              for (final p in d.permissions)
                Chip(
                  label: Text(
                    '${p.module}.${p.action}',
                    style: Theme.of(context).textTheme.erpCaption,
                  ),
                  avatar: Icon(
                    p.allowed ? Icons.check : Icons.block,
                    size: 16,
                    color: p.allowed ? t.brandGreen : t.posDanger,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAuditTab(PharmaTokens t, DensityTokens s) {
    if (_audit.isEmpty) {
      return Center(
        child: Text(
          'Sem registos de auditoria.',
          style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(s.lg),
      itemCount: _audit.length,
      separatorBuilder: (_, _) => Divider(color: t.border.withValues(alpha: 0.35)),
      itemBuilder: (context, index) {
        final a = _audit[index];
        return ListTile(
          dense: true,
          leading: Icon(Icons.history, color: t.brandBlue, size: 20),
          title: Text(
            a.action,
            style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
          ),
          subtitle: Text(
            '${a.entity}${a.entityId != null ? ' #${a.entityId}' : ''} • ${_dateTimeFmt.format(a.createdAt)}',
            style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
          ),
        );
      },
    );
  }

  Widget _buildEventsTab(PharmaTokens t, DensityTokens s) {
    if (_events.isEmpty) {
      return Center(
        child: Text(
          'Sem eventos de negócio.',
          style: Theme.of(context).textTheme.erpBodySecondary.copyWith(color: t.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(s.lg),
      itemCount: _events.length,
      separatorBuilder: (_, _) => Divider(color: t.border.withValues(alpha: 0.35)),
      itemBuilder: (context, index) {
        final e = _events[index];
        return ListTile(
          dense: true,
          leading: Icon(Icons.bolt, color: t.brandBlue, size: 20),
          title: Text(
            e.type,
            style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
          ),
          subtitle: Text(
            '${e.entity}${e.entityId != null ? ' #${e.entityId}' : ''} • ${_dateTimeFmt.format(e.createdAt)}',
            style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
          ),
        );
      },
    );
  }

  Widget _infoRow(PharmaTokens t, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.erpCaption.copyWith(color: t.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.erpLabel.copyWith(color: t.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
        'ADMIN' => 'Administrador',
        'GERENTE' => 'Gestor',
        'FARMACEUTICO' => 'Farmacêutico',
        'DIRETOR_TECNICO' => 'Director técnico',
        'CAIXA' => 'Caixa PDV',
        _ => role,
      };
}
