import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../data/fail_switch.dart';
import '../dependencies.dart';

enum _MenuAction { simulateError, logOut }

// Figma: account u dnu sidebara. Pokazuje ko je prijavljen i nudi odjavu.
class UserMenu extends StatelessWidget {
  const UserMenu({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final failSwitch = context.read<BackofficeDependencies>().failSwitch;
    // Material nosi pozadinu, da bi se talas od klika video preko nje.
    return Material(
      color: AppExtraColors.of(context).muted,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<_MenuAction>(
        tooltip: 'Nalog',
        onSelected: (action) => _onSelected(context, action, failSwitch),
        itemBuilder: (context) => [
          // Samo uz lažne podatke. Pravi server ne može da se natera da pogreši, njega gasi docker compose stop.
          if (failSwitch != null)
            const PopupMenuItem(value: _MenuAction.simulateError, child: Text('Simuliraj grešku')),
          const PopupMenuItem(value: _MenuAction.logOut, child: Text('Odjava')),
        ],
        child: _Account(user: user),
      ),
    );
  }

  void _onSelected(BuildContext context, _MenuAction action, FailSwitch? failSwitch) {
    switch (action) {
      case _MenuAction.simulateError:
        failSwitch?.failNext = true;
        // Na ekranu se ništa ne menja dok repozitorijum ne bude pozvan, zato poruka.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sledeći zahtev će vratiti grešku.')));
      case _MenuAction.logOut:
        // Ruter sluša SessionBloc, pa sam prelazi na prijavu. Blocovi ovog korisnika se tada zatvore.
        context.read<SessionBloc>().add(const SessionLogOutRequested());
    }
  }
}

class _Account extends StatelessWidget {
  const _Account({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.px8),
      child: Row(
        spacing: AppSpacing.px8,
        children: [
          Avatar(name: user.name, size: AvatarSize.sm),
          Expanded(
            child: Text(user.name, style: AppTextStyles.bodySm.copyWith(color: colors.onSurface)),
          ),
          Icon(Icons.expand_more, size: 16, color: colors.onSurfaceVariant),
        ],
      ),
    );
  }
}
