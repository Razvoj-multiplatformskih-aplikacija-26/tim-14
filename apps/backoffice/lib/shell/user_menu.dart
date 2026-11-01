import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../data/demo_data.dart';
import '../data/fail_switch.dart';

enum _MenuAction { switchUser, simulateError }

// Figma: account u dnu sidebara. Do prijave u KT2 ovde se bira ko je ulogovan.
class UserMenu extends StatelessWidget {
  const UserMenu({super.key, required this.session});

  final ValueNotifier<User> session;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: session,
      builder: (context, user, _) {
        final other = user == milica ? admin : milica;
        // Material nosi pozadinu, da bi se talas od klika video preko nje.
        return Material(
          color: AppExtraColors.of(context).muted,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
          clipBehavior: Clip.antiAlias,
          child: PopupMenuButton<_MenuAction>(
            tooltip: 'Nalog',
            onSelected: (action) => _onSelected(context, action, other),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _MenuAction.switchUser,
                child: Text('Pređi na: ${other.name} (${_roleLabel(other.role)})'),
              ),
              const PopupMenuItem(value: _MenuAction.simulateError, child: Text('Simuliraj grešku')),
            ],
            child: _Account(user: user),
          ),
        );
      },
    );
  }

  void _onSelected(BuildContext context, _MenuAction action, User other) {
    switch (action) {
      case _MenuAction.switchUser:
        // Ruter sluša session, pa sam prelazi na deo nove uloge.
        session.value = other;
      case _MenuAction.simulateError:
        // Na ekranu se ništa ne menja dok repozitorijum ne bude pozvan, zato poruka.
        context.read<FailSwitch>().failNext = true;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sledeći zahtev će vratiti grešku.')));
    }
  }
}

String _roleLabel(Role role) => switch (role) {
  Role.student => 'učenik',
  Role.professor => 'profesor',
  Role.admin => 'administrator',
};

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
