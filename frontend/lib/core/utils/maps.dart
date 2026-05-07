import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openDirections({
  required BuildContext context,
  String? address,
  double? lat,
  double? lng,
}) async {
  final hasCoords = lat != null && lng != null;
  final dest = hasCoords ? '$lat,$lng' : Uri.encodeComponent(address ?? '');

  final google = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving');

  // Apple Maps scheme for iOS
  final apple = hasCoords
      ? Uri.parse('http://maps.apple.com/?daddr=$dest&dirflg=d')
      : Uri.parse('http://maps.apple.com/?daddr=$dest&dirflg=d');

  final url = Platform.isIOS ? apple : google;

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open Maps'),
      ),
    );
  }
}
