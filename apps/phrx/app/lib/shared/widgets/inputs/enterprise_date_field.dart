import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/typography.dart';
import 'enterprise_field_decoration.dart';
import 'formatters/date_input_formatter.dart';

/// Campo de data enterprise: texto DD/MM/AAAA + calendário.
/// Altura = [PharmaTokens.controlHeight] (igual a inputs / selects / botões).
class EnterpriseDateField extends StatefulWidget {
  const EnterpriseDateField({
    super.key,
    required this.labelText,
    this.value,
    this.onChanged,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.hintText = 'DD/MM/AAAA',
    this.validator,
    this.controller,
  });

  final String labelText;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String hintText;
  final FormFieldValidator<String>? validator;
  final TextEditingController? controller;

  @override
  State<EnterpriseDateField> createState() => _EnterpriseDateFieldState();
}

class _EnterpriseDateFieldState extends State<EnterpriseDateField> {
  static final _displayFormat = DateFormat('dd/MM/yyyy');
  late final TextEditingController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    if (widget.controller == null) {
      _syncFromValue(widget.value);
    }
  }

  @override
  void didUpdateWidget(covariant EnterpriseDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.controller == null) {
      _syncFromValue(widget.value);
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _syncFromValue(DateTime? value) {
    final text = value == null ? '' : _displayFormat.format(value);
    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  DateTime? _parse(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) return null;
    final day = int.tryParse(digits.substring(0, 2));
    final month = int.tryParse(digits.substring(2, 4));
    final year = int.tryParse(digits.substring(4, 8));
    if (day == null || month == null || year == null) return null;
    try {
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      return date;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDate() async {
    if (!widget.enabled) return;
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    DateTime initial = widget.value ?? now;
    if (_controller.text.length == 10) {
      try {
        initial = _displayFormat.parseStrict(_controller.text);
      } catch (_) {}
    }

    final firstDate = widget.firstDate ?? DateTime(now.year - 30);
    final lastDate = widget.lastDate ?? DateTime(now.year + 30);
    final clampedInitial = initial.isBefore(firstDate)
        ? firstDate
        : (initial.isAfter(lastDate) ? lastDate : initial);

    final navigatorContext =
        Navigator.of(context, rootNavigator: false).context;
    final picked = await showDatePicker(
      context: navigatorContext,
      initialDate: clampedInitial,
      firstDate: firstDate,
      lastDate: lastDate,
      useRootNavigator: false,
    );
    if (picked == null) return;
    _syncFromValue(picked);
    widget.onChanged?.call(picked);
  }

  void _onTextChanged(String text) {
    if (text.trim().isEmpty) {
      widget.onChanged?.call(null);
      return;
    }
    final parsed = _parse(text);
    if (parsed != null) {
      widget.onChanged?.call(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final theme = Theme.of(context);

    final field = TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      maxLength: 10,
      inputFormatters: [DateInputFormatter()],
      validator: widget.validator,
      onChanged: _onTextChanged,
      style: theme.textTheme.erpBody.copyWith(color: t.textPrimary),
      decoration: EnterpriseFieldDecoration.of(
        context,
        hintText: widget.hintText,
        enabled: widget.enabled,
        suffixIcon: IconButton(
          tooltip: 'Escolher data',
          onPressed: widget.enabled ? _pickDate : null,
          icon: Icon(
            Icons.calendar_today_outlined,
            size: t.iconSm,
            color: widget.enabled ? t.textSecondary : t.textMuted,
          ),
        ),
      ).copyWith(counterText: ''),
    );

    return EnterpriseFieldGroup(labelText: widget.labelText, child: field);
  }
}
