import 'package:flutter/material.dart';
import 'package:lunch_core/lunch_core.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lundby_lunch/ui/core/localization/l10n_extensions.dart';

/// Opens the restaurant's website in the current language.
class OpenWebsiteButton extends StatelessWidget {
  const OpenWebsiteButton({super.key, required this.restaurant});

  final RestaurantMenu restaurant;

  @override
  Widget build(BuildContext context) {
    final url = Uri.tryParse(restaurant.website.resolve(context.language));
    return TextButton.icon(
      onPressed: url == null
          ? null
          : () => launchUrl(url, mode: LaunchMode.externalApplication),
      icon: const Icon(Icons.open_in_new, size: 18),
      label: Text(context.l10n.openWebsite),
    );
  }
}
