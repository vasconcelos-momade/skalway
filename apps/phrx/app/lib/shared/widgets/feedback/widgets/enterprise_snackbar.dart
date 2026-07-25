import 'dart:async';

import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/theme/feedback_theme.dart';
import '../internal/notification_type.dart';

class EnterpriseSnackbar extends StatefulWidget {
  const EnterpriseSnackbar({
    super.key,
    required this.type,
    required this.message,
    required this.duration,
    required this.onClose,
  });

  final NotificationType type;
  final String message;
  final Duration duration;
  final VoidCallback onClose;

  @override
  State<EnterpriseSnackbar> createState() => _EnterpriseSnackbarState();
}

class _EnterpriseSnackbarState extends State<EnterpriseSnackbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    _timer = Timer(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onClose();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    IconData icon;

    switch (widget.type) {
      case NotificationType.success:
        backgroundColor = FeedbackColors.successBg;
        borderColor = FeedbackColors.successBorder;
        icon = Icons.check_circle_outline_rounded;
        break;
      case NotificationType.error:
        backgroundColor = FeedbackColors.errorBg;
        borderColor = FeedbackColors.errorBorder;
        icon = Icons.error_outline_rounded;
        break;
      case NotificationType.warning:
        backgroundColor = FeedbackColors.warningBg;
        borderColor = FeedbackColors.warningBorder;
        icon = Icons.warning_amber_rounded;
        break;
      case NotificationType.info:
        backgroundColor = FeedbackColors.infoBg;
        borderColor = FeedbackColors.infoBorder;
        icon = Icons.info_outline_rounded;
        break;
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 600;

    final content = Material(
      type: MaterialType.transparency,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 44,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(FeedbackStyles.borderRadius),
          boxShadow: FeedbackStyles.shadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FeedbackStyles.borderRadius),
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: const SizedBox.shrink(),
                ),
              ),
              Container(
                padding: FeedbackStyles.padding,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(FeedbackStyles.borderRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: FeedbackColors.icon, size: 20),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: FeedbackStyles.messageStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Positioned(
      bottom: 24,
      left: isDesktop ? 24 : 16,
      right: isDesktop ? null : 16,
      child: isDesktop
          ? ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: content,
                ),
              ),
            )
          : SizedBox(
              width: screenWidth - 32,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(child: content),
                ),
              ),
            ),
    );
  }
}