import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants/app_colors.dart';

/// JazzCash / EasyPaisa checkout: load gateway URL or auto-submit HTML form.
class PaymentWebViewScreen extends StatefulWidget {
  const PaymentWebViewScreen({
    super.key,
    this.initialUrl,
    this.html,
    this.baseUrl,
    this.title = 'Payment',
  });

  final Uri? initialUrl;
  final String? html;
  final String? baseUrl;
  final String title;

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
        ),
      );

    if (widget.initialUrl != null) {
      _controller.loadRequest(Uri.parse(widget.initialUrl.toString()));
    } else if (widget.html != null && widget.html!.isNotEmpty) {
      final b = widget.baseUrl ?? 'https://bizzway.app/';
      _controller.loadHtmlString(widget.html!, baseUrl: b);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const ColoredBox(
              color: Colors.white70,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
