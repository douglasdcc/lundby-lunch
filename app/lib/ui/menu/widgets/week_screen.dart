import 'package:flutter/material.dart';

import 'package:lundby_lunch/ui/core/localization/l10n_extensions.dart';
import 'package:lundby_lunch/ui/core/widgets/message_view.dart';
import 'package:lundby_lunch/ui/menu/view_models/menu_view_model.dart';
import 'package:lundby_lunch/ui/menu/widgets/day_selector.dart';
import 'package:lundby_lunch/ui/menu/widgets/menu_body.dart';
import 'package:lundby_lunch/ui/menu/widgets/restaurant_day_card.dart';

/// One restaurant's menu, day by day.
class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key, required this.viewModel});

  final MenuViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.load]),
      builder: (context, _) {
        final menus = viewModel.menus;
        final restaurant = viewModel.selectedRestaurant;
        final date = viewModel.selectedDate;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              menus == null
                  ? context.l10n.navWeek
                  : context.l10n.weekNumber(menus.week.week),
            ),
          ),
          body: MenuBody(
            viewModel: viewModel,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _RestaurantSelector(viewModel: viewModel),
                ),
                SliverToBoxAdapter(
                  child: DaySelector(
                    days: viewModel.weekdays,
                    selected: date,
                    onSelected: viewModel.selectDate,
                  ),
                ),
                if (restaurant == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: MessageView(
                      icon: Icons.visibility_off_outlined,
                      title: context.l10n.allRestaurantsHidden,
                    ),
                  )
                else if (date != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: RestaurantDayCard(
                        restaurant: restaurant,
                        date: date,
                        showDetails: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RestaurantSelector extends StatelessWidget {
  const _RestaurantSelector({required this.viewModel});

  final MenuViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final restaurants = viewModel.restaurants;
    final selectedId = viewModel.selectedRestaurant?.id;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: restaurants.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final restaurant = restaurants[index];
          return Center(
            child: ChoiceChip(
              label: Text(restaurant.name),
              selected: restaurant.id == selectedId,
              onSelected: (_) => viewModel.selectRestaurant(restaurant.id),
            ),
          );
        },
      ),
    );
  }
}
