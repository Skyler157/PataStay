import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../data/admin_repository.dart';
import '../features/dashboard/platform_stats.dart';
import 'theme_mode.dart';

class _Destination {
  const _Destination(this.path, this.label, this.icon, this.selectedIcon);
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Destination('/', 'Overview', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
  _Destination('/review', 'Review queue', Icons.fact_check_outlined, Icons.fact_check_rounded),
  _Destination('/listings', 'Listings', Icons.home_work_outlined, Icons.home_work_rounded),
  _Destination('/reports', 'Reports', Icons.flag_outlined, Icons.flag_rounded),
  _Destination('/follow-ups', 'Follow-ups', Icons.notifications_active_outlined, Icons.notifications_active_rounded),
  _Destination('/users', 'Users', Icons.people_outline_rounded, Icons.people_rounded),
  _Destination('/areas', 'Areas & amenities', Icons.map_outlined, Icons.map_rounded),
];

/// Side navigation on wide screens, a drawer on narrow ones.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  int get _selected {
    for (var i = _destinations.length - 1; i > 0; i--) {
      if (location.startsWith(_destinations[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final profile = ref.watch(currentProfileProvider).value;
    final stats = ref.watch(platformStatsProvider(30)).value;
    final followUps = ref.watch(followUpsProvider).value;
    int? badgeFor(int i) => switch (_destinations[i].path) {
          '/review' => stats?.listingsPending,
          '/reports' => stats?.reportsOpen,
          '/follow-ups' => followUps?.total,
          '/users' => stats?.deletionRequests,
          _ => null,
        };

    Widget icon(int i, {bool selected = false}) {
      final d = _destinations[i];
      final count = badgeFor(i) ?? 0;
      final glyph = Icon(selected ? d.selectedIcon : d.icon);
      return count > 0 ? Badge.count(count: count, child: glyph) : glyph;
    }

    void go(int i) {
      // Badges follow the latest numbers after moderation work.
      ref
        ..invalidate(platformStatsProvider(30))
        ..invalidate(followUpsProvider);
      context.go(_destinations[i].path);
    }

    final appBar = AppBar(
      titleSpacing: wide ? Space.xl : 0,
      title: const Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(child: PataWordmark(size: 20)),
        Gap.md,
        Text('Admin'),
      ]),
      actions: [
        if (profile != null && wide)
          Padding(
            padding: const EdgeInsets.only(right: Space.sm),
            child: Center(child: Text(profile.email ?? '', style: context.text.bodyMedium)),
          ),
        const ThemeModeButton(),
        IconButton(
          tooltip: 'Sign out',
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
          icon: const Icon(Icons.logout_rounded),
        ),
        Gap.sm,
      ],
    );

    if (!wide) {
      return Scaffold(
        appBar: appBar,
        drawer: NavigationDrawer(
          selectedIndex: _selected,
          onDestinationSelected: (i) {
            Navigator.pop(context);
            go(i);
          },
          children: [
            const Padding(padding: EdgeInsets.all(Space.xl), child: PataWordmark(size: 22)),
            for (var i = 0; i < _destinations.length; i++)
              NavigationDrawerDestination(
                icon: icon(i),
                selectedIcon: icon(i, selected: true),
                label: Flexible(child: Text(_destinations[i].label, overflow: TextOverflow.ellipsis)),
              ),
          ],
        ),
        body: child,
      );
    }

    return Scaffold(
      appBar: appBar,
      body: Row(children: [
        NavigationRail(
          selectedIndex: _selected,
          onDestinationSelected: go,
          labelType: NavigationRailLabelType.all,
          minWidth: 96,
          destinations: [
            for (var i = 0; i < _destinations.length; i++)
              NavigationRailDestination(
                icon: icon(i),
                selectedIcon: icon(i, selected: true),
                label: Text(_destinations[i].label, textAlign: TextAlign.center),
              ),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: child),
      ]),
    );
  }
}
