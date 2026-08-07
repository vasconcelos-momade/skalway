import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/auth_session_notifier.dart';
import '../../core/theme/design_tokens.dart';
import 'desktop_close_handler.dart';
import 'desktop_window.dart';

/// Controlos min/max/fechar para integrar na AppBar (após o botão de tema).
/// Não cria barra extra — só os ícones.
class DesktopWindowControls extends ConsumerStatefulWidget {
  const DesktopWindowControls({super.key});

  @override
  ConsumerState<DesktopWindowControls> createState() =>
      _DesktopWindowControlsState();
}

class _DesktopWindowControlsState extends ConsumerState<DesktopWindowControls> {
  bool _maximized = false;
  bool _closing = false;
  VoidCallback? _removeListener;

  @override
  void initState() {
    super.initState();
    if (!supportsDesktopWindowControls) return;
    _syncMaximized();
    _removeListener = addDesktopWindowListener(
      onMaximize: () => _setMaximized(true),
      onUnmaximize: () => _setMaximized(false),
      onEnterFullScreen: () => _setMaximized(true),
      onLeaveFullScreen: () => _setMaximized(false),
    );
  }

  @override
  void dispose() {
    _removeListener?.call();
    super.dispose();
  }

  Future<void> _syncMaximized() async {
    final value = await isDesktopWindowMaximized();
    if (mounted) setState(() => _maximized = value);
  }

  void _setMaximized(bool value) {
    if (!mounted || _maximized == value) return;
    setState(() => _maximized = value);
  }

  Future<void> _onClose() async {
    if (_closing) return;
    setState(() => _closing = true);
    try {
      await handleDesktopCloseRequest(ref);
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!supportsDesktopWindowControls) {
      return const SizedBox.shrink();
    }

    final t = context.pharmaTokens;
    final authenticated = ref.watch(authSessionProvider).isAuthenticated;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowIconButton(
          tooltip: 'Minimizar',
          icon: Icons.remove,
          color: t.textSecondary,
          onPressed: minimizeDesktopWindow,
        ),
        _WindowIconButton(
          tooltip: _maximized ? 'Restaurar' : 'Maximizar',
          icon: _maximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
          iconSize: _maximized ? 16 : 18,
          color: t.textSecondary,
          onPressed: () async {
            await toggleMaximizeDesktopWindow();
            await _syncMaximized();
          },
        ),
        _WindowIconButton(
          tooltip: authenticated ? 'Terminar sessão' : 'Fechar',
          icon: Icons.close,
          color: t.posDanger,
          onPressed: _closing ? null : _onClose,
        ),
      ],
    );
  }
}

/// Área da AppBar que arrasta a janela (e duplo clique maximiza/restaura).
class DesktopWindowDragArea extends StatelessWidget {
  const DesktopWindowDragArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!supportsDesktopWindowControls) return child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => startDesktopWindowDragging(),
      onDoubleTap: toggleMaximizeDesktopWindow,
      child: child,
    );
  }
}

class _WindowIconButton extends StatelessWidget {
  const _WindowIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.color,
    this.iconSize = 20,
  });

  final String tooltip;
  final IconData icon;
  final Future<void> Function()? onPressed;
  final Color color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    return IconButton(
      tooltip: tooltip,
      constraints: BoxConstraints(
        minWidth: t.minTouchTarget,
        minHeight: t.minTouchTarget,
      ),
      padding: EdgeInsets.zero,
      onPressed: onPressed == null ? null : () => onPressed!(),
      icon: Icon(icon, size: iconSize, color: color),
    );
  }
}
