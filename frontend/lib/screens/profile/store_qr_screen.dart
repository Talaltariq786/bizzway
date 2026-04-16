import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/business_provider.dart';

/// Shop QR for printing / sharing — encodes [BusinessProvider.storeOrderQrUrl].
class StoreQrScreen extends StatefulWidget {
  const StoreQrScreen({super.key});

  @override
  State<StoreQrScreen> createState() => _StoreQrScreenState();
}

class _StoreQrScreenState extends State<StoreQrScreen> {
  bool _sharing = false;

  Future<void> _ensureLoaded() async {
    final b = context.read<BusinessProvider>();
    if (b.storeQrToken.isEmpty) {
      await b.loadBusiness();
    }
  }

  Future<void> _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order link copied'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareLink(String url, String name) async {
    await Share.share(
      'Order from $name on BizzWay:\n$url',
      subject: 'BizzWay — $name',
    );
  }

  Future<void> _shareQrPng(String data, String businessName) async {
    setState(() => _sharing = true);
    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        gapless: true,
      );
      final bd = await painter.toImageData(640, format: ui.ImageByteFormat.png);
      if (bd == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create QR image')),
        );
        return;
      }
      final bytes = bd.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final safeName = businessName.replaceAll(RegExp(r'[^\w\-]+'), '_');
      final f = File('${dir.path}/bizzway_qr_$safeName.png');
      await f.writeAsBytes(bytes);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(f.path)],
        text:
            'BizzWay — $businessName\nScan this QR in the BizzWay app to order.',
        subject: 'BizzWay store QR — $businessName',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final business = context.watch<BusinessProvider>();
    final accent = business.themeColor;
    final url = business.storeOrderQrUrl;
    final name = business.businessName;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Store QR code'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: url.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Print yeh QR apni dukaan par lagayein — customer BizzWay app se scan karke order karega.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: QrImageView(
                          data: url,
                          version: QrVersions.auto,
                          size: 220,
                          gapless: true,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: accent, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'QR phone par ban jata hai — har scan ka koi extra charge nahi. Sirf print / paper ki apni cost.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: AppColors.textPrimary.withValues(alpha: 0.88),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _sharing
                        ? null
                        : () => _shareQrPng(url, name),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _sharing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.share_rounded),
                    label: Text(_sharing ? 'Preparing…' : 'Share QR image (PNG)'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _shareLink(url, name),
                    icon: const Icon(Icons.link_rounded),
                    label: const Text('Share order link'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _copyLink(url),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy order link'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tip: Poster banate waqt neeche likh dein: '
                    '"BizzWay app se scan karke order karein".',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
