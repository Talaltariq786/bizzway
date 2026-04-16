import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/constants/app_colors.dart';

/// Profile → Terms & Conditions: full backend handoff (markdown asset).
class TermsAndBackendHandoffScreen extends StatefulWidget {
  const TermsAndBackendHandoffScreen({super.key});

  @override
  State<TermsAndBackendHandoffScreen> createState() =>
      _TermsAndBackendHandoffScreenState();
}

class _TermsAndBackendHandoffScreenState
    extends State<TermsAndBackendHandoffScreen> {
  late final Future<String> _markdownFuture;

  @override
  void initState() {
    super.initState();
    _markdownFuture =
        rootBundle.loadString('docs/BACKEND_THREE_APPS_HANDOFF_FINAL.md');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: FutureBuilder<String>(
        future: _markdownFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Document load failed: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Markdown(
            data: snapshot.data!,
            selectable: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
              h1: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              h2: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              h3: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              strong: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              code: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.4),
                color: AppColors.textPrimary,
              ),
              codeblockDecoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              codeblockPadding: const EdgeInsets.all(12),
              blockquote: const TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              tableHead: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              tableBody: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              tableBorder: TableBorder.all(color: AppColors.border),
            ),
          );
        },
      ),
    );
  }
}

