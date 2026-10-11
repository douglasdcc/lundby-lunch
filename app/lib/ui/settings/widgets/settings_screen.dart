import 'package:flutter/material.dart';
import 'package:lunch_core/lunch_core.dart';

import 'package:lundby_lunch/config/app_config.dart';
import 'package:lundby_lunch/domain/models/settings.dart';
import 'package:lundby_lunch/ui/core/localization/l10n_extensions.dart';
import 'package:lundby_lunch/ui/settings/view_models/settings_view_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _SectionTitle(l10n.settingsLanguage),
            _Choice<Language>(
              selected: viewModel.language ?? context.language,
              onChanged: viewModel.setLanguage,
              options: {
                for (final language in Language.values)
                  language: (language.nativeName, null),
              },
            ),
            _SectionTitle(l10n.settingsTheme),
            _Choice<ThemePreference>(
              selected: viewModel.theme,
              onChanged: viewModel.setTheme,
              options: {
                ThemePreference.system: (
                  l10n.themeSystem,
                  Icons.brightness_auto_outlined,
                ),
                ThemePreference.light: (
                  l10n.themeLight,
                  Icons.light_mode_outlined,
                ),
                ThemePreference.dark: (
                  l10n.themeDark,
                  Icons.dark_mode_outlined,
                ),
              },
            ),
            _SectionTitle(l10n.settingsStartScreen),
            _Choice<MenuView>(
              selected: viewModel.startView,
              onChanged: viewModel.setStartView,
              options: {
                MenuView.today: (l10n.navToday, Icons.today_outlined),
                MenuView.week: (l10n.navWeek, Icons.view_week_outlined),
              },
            ),
            _SectionTitle(l10n.settingsRestaurants),
            _RestaurantList(viewModel: viewModel),
            _SectionTitle(l10n.settingsAbout),
            const _About(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// A full-width segmented choice. Each option has a label and optional icon.
class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.onChanged,
    required this.options,
  });

  final T selected;
  final ValueChanged<T> onChanged;
  final Map<T, (String, IconData?)> options;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<T>(
          showSelectedIcon: false,
          segments: [
            for (final MapEntry(key: value, value: (label, icon))
                in options.entries)
              ButtonSegment(
                value: value,
                label: Text(label),
                icon: icon == null ? null : Icon(icon),
              ),
          ],
          selected: {selected},
          onSelectionChanged: (selection) => onChanged(selection.single),
        ),
      ),
    );
  }
}

class _RestaurantList extends StatelessWidget {
  const _RestaurantList({required this.viewModel});

  final SettingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restaurants = viewModel.restaurants;
    final hintStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (restaurants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(context.l10n.settingsRestaurantsEmpty, style: hintStyle),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(context.l10n.settingsRestaurantsHint, style: hintStyle),
        ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: viewModel.moveRestaurant,
          children: [
            for (final (index, restaurant) in restaurants.indexed)
              ListTile(
                key: ValueKey(restaurant.id),
                leading: ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_indicator),
                ),
                title: Text(restaurant.name),
                trailing: Switch(
                  value: !viewModel.isHidden(restaurant.id),
                  onChanged: (visible) =>
                      viewModel.setVisible(restaurant.id, visible: visible),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.aboutText, style: style),
          if (AppConfig.useSampleData) ...[
            const SizedBox(height: 8),
            Text(context.l10n.sampleDataNotice, style: style),
          ],
        ],
      ),
    );
  }
}
