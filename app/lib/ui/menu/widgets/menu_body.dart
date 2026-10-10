import 'package:flutter/material.dart';

import 'package:lundby_lunch/ui/core/localization/l10n_extensions.dart';
import 'package:lundby_lunch/ui/core/widgets/message_view.dart';
import 'package:lundby_lunch/ui/menu/view_models/menu_view_model.dart';

/// Handles loading and error states, the stale-week notice and
/// pull-to-refresh. Shows [child] once menus are loaded.
class MenuBody extends StatelessWidget {
  const MenuBody({super.key, required this.viewModel, required this.child});

  final MenuViewModel viewModel;

  /// A scrollable, so pull-to-refresh works.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final menus = viewModel.menus;

    if (menus == null) {
      if (viewModel.load.error) {
        return MessageView(
          icon: Icons.cloud_off_outlined,
          title: l10n.loadErrorTitle,
          message: l10n.loadErrorMessage,
          action: FilledButton.tonal(
            onPressed: viewModel.load.execute,
            child: Text(l10n.retry),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (viewModel.isStale)
          _StaleWeekNotice(
            shown: menus.week.week,
            target: viewModel.targetWeek.week,
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: child,
          ),
        ),
      ],
    );
  }

  Future<void> _refresh(BuildContext context) async {
    await viewModel.refresh.execute();
    if (!context.mounted || !viewModel.refresh.error) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.refreshFailed)));
  }
}

class _StaleWeekNotice extends StatelessWidget {
  const _StaleWeekNotice({required this.shown, required this.target});

  final int shown;
  final int target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.staleWeek(shown, target),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
