import 'package:flutter/material.dart';
import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/ui/core/localization/l10n_extensions.dart';

/// One dish: optional category, name, description, spice level, diet tags
/// and price.
class DishTile extends StatelessWidget {
  const DishTile({super.key, required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = context.language;
    final category = dish.category?.resolve(language);
    final description = dish.description?.resolve(language);
    final price = dish.price;
    final spice = dish.spice;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category != null && category.isNotEmpty)
                  Text(
                    category,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                Text(
                  dish.name.resolve(language),
                  style: theme.textTheme.bodyLarge,
                ),
                if (description != null && description.isNotEmpty)
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (spice != null || dish.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (spice != null) _SpiceLabel(spice),
                        for (final tag in dish.tags) _TagLabel(tag),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (price != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                context.l10n.price(price),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One chili per level, read out as words by screen readers.
class _SpiceLabel extends StatelessWidget {
  const _SpiceLabel(this.spice);

  final SpiceLevel spice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (chilies, label) = switch (spice) {
      SpiceLevel.mild => (1, l10n.spiceMild),
      SpiceLevel.medium => (2, l10n.spiceMedium),
      SpiceLevel.hot => (3, l10n.spiceHot),
    };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Text(
        '🌶️' * chilies,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

class _TagLabel extends StatelessWidget {
  const _TagLabel(this.tag);

  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          tag,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
