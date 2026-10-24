import 'package:flutter/material.dart';
import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/ui/core/localization/l10n_extensions.dart';
import 'package:lundby_lunch/ui/core/widgets/dish_tile.dart';
import 'package:lundby_lunch/ui/core/widgets/open_website_button.dart';

/// A restaurant's dishes for one day, followed by its dishes for the week.
class RestaurantDayCard extends StatelessWidget {
  const RestaurantDayCard({
    super.key,
    required this.restaurant,
    required this.date,
    this.showDetails = false,
  });

  final RestaurantMenu restaurant;
  final DateTime date;

  /// Shows the address in the header.
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dishes = restaurant.dishesOn(date);
    final notes = restaurant.notes?.resolve(context.language);

    final Widget content = switch (restaurant.status) {
      MenuStatus.missing => _Unavailable(l10n.menuMissing),
      MenuStatus.error => _Unavailable(l10n.menuError),
      MenuStatus.imageOnly => _Unavailable(l10n.menuImageOnly(restaurant.name)),
      MenuStatus.ok when dishes.isEmpty && restaurant.weekly.isEmpty =>
        _Unavailable(l10n.noMenuForDay),
      MenuStatus.ok => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final dish in dishes) DishTile(dish: dish),
          if (restaurant.weekly.isNotEmpty) ...[
            _SectionLabel(l10n.allWeek),
            for (final dish in restaurant.weekly) DishTile(dish: dish),
          ],
          if (notes != null) _Notes(notes),
        ],
      ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(restaurant: restaurant, showDetails: showDetails),
            content,
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.restaurant, required this.showDetails});

  final RestaurantMenu restaurant;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      ?restaurant.lunchHours,
      if (showDetails) ?restaurant.address,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(restaurant.name, style: theme.textTheme.titleMedium),
          if (details.isNotEmpty)
            Text(
              details,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OpenWebsiteButton(restaurant: restaurant),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
