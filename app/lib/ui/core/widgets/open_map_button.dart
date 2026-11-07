import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lundby_lunch/ui/core/localization/l10n_extensions.dart';

/// Opens the restaurant's address in Google Maps.
class OpenMapButton extends StatelessWidget {
  const OpenMapButton({super.key, required this.address});

  final String address;

  /// The addresses are stored without a city, which the search needs to find
  /// the right street.
  static Uri urlFor(String address) => Uri.https(
    'www.google.com',
    '/maps/search/',
    {'api': '1', 'query': '$address, Göteborg'},
  );

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () =>
          launchUrl(urlFor(address), mode: LaunchMode.externalApplication),
      icon: const Icon(Icons.map_outlined, size: 18),
      label: Text(context.l10n.openMap),
    );
  }
}
