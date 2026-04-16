import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_colors.dart';
import 'async_guard.dart';

/// Themed bars aligned with [AppColors] — use these instead of raw [SnackBar].
enum AppSnackKind {
  success,
  error,
  warning,
  info,
}

IconData _iconForKind(AppSnackKind kind) {
  return switch (kind) {
    AppSnackKind.success => Icons.check_circle_rounded,
    AppSnackKind.error => Icons.error_outline_rounded,
    AppSnackKind.warning => Icons.warning_amber_rounded,
    AppSnackKind.info => Icons.info_outline_rounded,
  };
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackKind kind = AppSnackKind.info,
  String? detail,
  Duration duration = const Duration(seconds: 4),
}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  final spec = _SnackSpec.forKind(kind);

  messenger.showSnackBar(
    SnackBar(
      content: _SnackBarContent(
        kind: kind,
        message: message,
        detail: detail,
        foreground: spec.foreground,
      ),
      backgroundColor: spec.background,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 6,
      duration: detail != null && detail.isNotEmpty
          ? duration + const Duration(seconds: 2)
          : duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}

/// Maps any thrown error to a user message + optional expandable technical detail.
void showAppSnackBarFromException(
  BuildContext context,
  Object error, {
  AppSnackKind kind = AppSnackKind.error,
}) {
  showAppSnackBar(
    context,
    AsyncGuard.friendlyMessage(error),
    kind: kind,
    detail: AsyncGuard.optionalDetail(error),
  );
}

/// Backwards-compatible API (existing call sites).
void showAppToast(
  BuildContext context,
  String message, {
  bool error = false,
  bool success = false,
}) {
  showAppSnackBar(
    context,
    message,
    kind: error
        ? AppSnackKind.error
        : success
            ? AppSnackKind.success
            : AppSnackKind.info,
  );
}

class _SnackSpec {
  const _SnackSpec({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  static _SnackSpec forKind(AppSnackKind kind) {
    switch (kind) {
      case AppSnackKind.success:
        return const _SnackSpec(
          background: AppColors.success,
          foreground: Colors.white,
        );
      case AppSnackKind.error:
        return const _SnackSpec(
          background: AppColors.error,
          foreground: Colors.white,
        );
      case AppSnackKind.warning:
        return const _SnackSpec(
          background: AppColors.warning,
          foreground: AppColors.textPrimary,
        );
      case AppSnackKind.info:
        return const _SnackSpec(
          background: AppColors.primary,
          foreground: Colors.white,
        );
    }
  }
}

class _SnackBarContent extends StatefulWidget {
  const _SnackBarContent({
    required this.kind,
    required this.message,
    required this.detail,
    required this.foreground,
  });

  final AppSnackKind kind;
  final String message;
  final String? detail;
  final Color foreground;

  @override
  State<_SnackBarContent> createState() => _SnackBarContentState();
}

class _SnackBarContentState extends State<_SnackBarContent> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail?.trim();
    final hasDetail = detail != null && detail.isNotEmpty;

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _iconForKind(widget.kind),
          color: widget.foreground,
          size: 26,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.message,
                style: TextStyle(
                  color: widget.foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              if (hasDetail) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: widget.foreground.withValues(alpha: 0.95),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _expanded ? 'Detail chhupayein' : 'Poori detail / error',
                          style: TextStyle(
                            color: widget.foreground.withValues(alpha: 0.95),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor:
                                widget.foreground.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_expanded) ...[
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: SelectableText(
                          detail,
                          style: TextStyle(
                            color: widget.foreground.withValues(alpha: 0.95),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: widget.foreground,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: detail));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        showAppSnackBar(
                          context,
                          'Detail copy ho gayi',
                          kind: AppSnackKind.success,
                          duration: const Duration(seconds: 2),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );

    return row
        .animate()
        .fadeIn(duration: 200.ms, curve: Curves.easeOutCubic)
        .slideX(begin: 0.04, end: 0, duration: 220.ms, curve: Curves.easeOutCubic);
  }
}
