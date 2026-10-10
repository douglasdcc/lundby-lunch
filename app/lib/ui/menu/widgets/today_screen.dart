import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lundby_lunch/ui/core/localization/l10n_extensions.dart';
import 'package:lundby_lunch/ui/core/widgets/message_view.dart';
import 'package:lundby_lunch/ui/menu/view_models/menu_view_model.dart';
import 'package:lundby_lunch/ui/menu/widgets/day_selector.dart';
import 'package:lundby_lunch/ui/menu/widgets/menu_body.dart';
import 'package:lundby_lunch/ui/menu/widgets/restaurant_day_card.dart';

/// Every restaurant's menu for the selected day.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.viewModel});

  final MenuViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.load]),
      builder: (context, _) {
        final locale = Localizations.localeOf(context).toString();
        final date = viewModel.selectedDate;
        final restaurants = viewModel.restaurants;
        final menus = viewModel.menus;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              date == null
                  ? context.l10n.navToday
                  : DateFormat.MMMMEEEEd(locale).format(date),
            ),
            actions: [
              if (menus != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(context.l10n.weekNumber(menus.week.week)),
                ),
            ],
          ),
          body: MenuBody(
            viewModel: viewModel,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: DaySelector(
                    days: viewModel.weekdays,
                    selected: date,
                    onSelected: viewModel.selectDate,
                  ),
                ),
                if (restaurants.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: MessageView(
                      icon: Icons.visibility_off_outlined,
                      title: context.l10n.allRestaurantsHidden,
                    ),
                  )
                else if (date != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: SliverList.separated(
                      itemCount: restaurants.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => RestaurantDayCard(
                        restaurant: restaurants[index],
                        date: date,
                      ),
                    ),
                  ),
                if (menus != null)
                  SliverToBoxAdapter(
                    child: _LastUpdated(time: menus.generatedAt),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LastUpdated extends StatelessWidget {
  const _LastUpdated({required this.time});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final formatted = DateFormat.MMMd(locale).add_Hm().format(time.toLocal());
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Text(
        context.l10n.lastUpdated(formatted),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
