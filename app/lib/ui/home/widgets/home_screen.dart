import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:lundby_lunch/data/repositories/menu_repository.dart';
import 'package:lundby_lunch/data/repositories/settings_repository.dart';
import 'package:lundby_lunch/domain/models/settings.dart';
import 'package:lundby_lunch/ui/core/localization/l10n_extensions.dart';
import 'package:lundby_lunch/ui/menu/view_models/menu_view_model.dart';
import 'package:lundby_lunch/ui/menu/widgets/today_screen.dart';
import 'package:lundby_lunch/ui/menu/widgets/week_screen.dart';
import 'package:lundby_lunch/ui/settings/view_models/settings_view_model.dart';
import 'package:lundby_lunch/ui/settings/widgets/settings_screen.dart';
import 'package:lundby_lunch/utils/clock.dart';

/// The main screen with the Today / Week / Settings navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MenuViewModel _menuViewModel;
  late final SettingsViewModel _settingsViewModel;
  late int _index;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsRepository>();
    final menus = context.read<MenuRepository>();
    _menuViewModel = MenuViewModel(
      menuRepository: menus,
      settingsRepository: settings,
      now: context.read<Clock>().now,
    );
    _settingsViewModel = SettingsViewModel(
      settingsRepository: settings,
      menuRepository: menus,
    );
    _index = switch (settings.startView) {
      MenuView.today => 0,
      MenuView.week => 1,
    };
  }

  @override
  void dispose() {
    _menuViewModel.dispose();
    _settingsViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: switch (_index) {
        0 => TodayScreen(viewModel: _menuViewModel),
        1 => WeekScreen(viewModel: _menuViewModel),
        _ => SettingsScreen(viewModel: _settingsViewModel),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: l10n.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.view_week_outlined),
            selectedIcon: const Icon(Icons.view_week),
            label: l10n.navWeek,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
