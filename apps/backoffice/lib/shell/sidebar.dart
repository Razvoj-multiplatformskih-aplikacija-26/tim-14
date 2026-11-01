import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../router.dart';
import 'user_menu.dart';

typedef _NavItem = ({String label, IconData icon, String path, Role role});

// Stavku vidi samo uloga kojoj pripada.
const _items = <_NavItem>[
  (label: 'Časovi', icon: Icons.event_note_outlined, path: Routes.lessons, role: Role.professor),
  (label: 'Verifikacija', icon: Icons.verified_user_outlined, path: Routes.verification, role: Role.admin),
];

// Figma: Panel/Sidebar.
class Sidebar extends StatelessWidget {
  const Sidebar({super.key, required this.session, required this.location});

  final ValueNotifier<User> session;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      padding: const EdgeInsets.all(AppSpacing.px16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(right: BorderSide(color: AppExtraColors.of(context).border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.px8,
        children: [
          const _Brand(),
          ValueListenableBuilder(
            valueListenable: session,
            builder: (context, user, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.px4,
              children: [
                for (final item in _items)
                  if (item.role == user.role) _NavTile(item: item, selected: location == item.path),
              ],
            ),
          ),
          const Spacer(),
          UserMenu(session: session),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.px8, top: AppSpacing.px8, bottom: AppSpacing.px8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: AppSpacing.px8,
        children: [
          Flexible(
            child: Text(
              'Backoffice',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.heading2xl.copyWith(color: colors.primary),
            ),
          ),
          Text('panel', style: AppTextStyles.captionXs.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.selected});

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.onPrimaryContainer : colors.onSurfaceVariant;
    const radius = BorderRadius.all(Radius.circular(AppRadius.md));
    return Material(
      color: selected ? colors.primaryContainer : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        // U fioki klik prvo zatvara fioku. Na širokom prozoru fioke nema, pa closeDrawer ne radi ništa.
        onTap: () {
          Scaffold.of(context).closeDrawer();
          context.go(item.path);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.px12, vertical: AppSpacing.px8),
          child: Row(
            spacing: AppSpacing.px12,
            children: [
              Icon(item.icon, size: 20, color: foreground),
              Expanded(
                child: Text(item.label, style: AppTextStyles.bodySmMedium.copyWith(color: foreground)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
