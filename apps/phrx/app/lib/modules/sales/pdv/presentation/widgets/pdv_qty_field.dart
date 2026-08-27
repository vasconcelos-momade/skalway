import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../shared/widgets/inputs/enterprise_field_decoration.dart';

/// Input numérico compacto de quantidade no catálogo PDV (min 1, step 1).
class PdvQtyField extends StatefulWidget {
  const PdvQtyField({
    super.key,
    required this.maxStock,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.compact = false,
  });

  final int maxStock;
  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final bool compact;

  @override
  State<PdvQtyField> createState() => _PdvQtyFieldState();
}

class _PdvQtyFieldState extends State<PdvQtyField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant PdvQtyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        !_focusNode.hasFocus &&
        _controller.text != '${widget.value}') {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _commit(_controller.text);
    }
  }

  int _clamp(int raw) {
    final max = widget.maxStock < 1 ? 1 : widget.maxStock;
    if (raw < 1) return 1;
    if (raw > max) return max;
    return raw;
  }

  void _commit(String raw) {
    final parsed = int.tryParse(raw.trim());
    final next = _clamp(parsed ?? 1);
    if (_controller.text != '$next') {
      _controller.text = '$next';
    }
    if (next != widget.value) {
      widget.onChanged(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final width = widget.compact ? 56.0 : 72.0;
    final height = widget.compact ? t.compactControlHeight : t.controlHeight;

    return SizedBox(
      width: width,
      height: height,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled && widget.maxStock > 0,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        style: Theme.of(context).textTheme.erpBody.copyWith(
              color: t.textPrimary,
            ),
        decoration: EnterpriseFieldDecoration.of(context).copyWith(
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.spacing.xs,
            vertical: 0,
          ),
          isDense: true,
        ),
        onChanged: (value) {
          final parsed = int.tryParse(value.trim());
          if (parsed != null && parsed >= 1) {
            widget.onChanged(_clamp(parsed));
          }
        },
        onSubmitted: _commit,
      ),
    );
  }
}
