import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../core/admin_widgets.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key, this.initialFilter = UserFilter.all});

  final UserFilter initialFilter;

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  late UserFilter _filter = widget.initialFilter;
  String _query = '';

  UserQuery get _key => (filter: _filter, query: _query);

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider(_key));
    final deletions = _filter == UserFilter.deletionRequested;

    return AdminPage(
      title: 'Users',
      subtitle: deletions
          ? 'PataStay promises to delete accounts within 30 days of the request. Oldest requests first.'
          : null,
      maxWidth: 1000,
      actions: [
        SearchBox(hint: 'Name, email or phone', onChanged: (q) => setState(() => _query = q)),
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(adminUsersProvider(_key)),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      children: [
        Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
          for (final f in UserFilter.values)
            ChoiceChip(label: Text(f.label), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
        ]),
        Gap.lg,
        switch (users) {
          AsyncData(:final value) when value.isEmpty => SizedBox(
              height: 240,
              child: EmptyView(
                icon: deletions ? Icons.task_alt_rounded : Icons.person_search_rounded,
                title: deletions ? 'No deletion requests' : 'No users found',
              ),
            ),
          AsyncData(:final value) => Card(
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (var i = 0; i < value.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _UserRow(user: value[i]),
                ],
              ]),
            ),
          AsyncError(:final error) => SizedBox(
              height: 240,
              child: ErrorView(error: error, onRetry: () => ref.invalidate(adminUsersProvider(_key))),
            ),
          _ => const SizedBox(height: 240, child: LoadingView()),
        },
        if (deletions) ...[Gap.xxl, const _DeletionLog()],
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final p = user.profile;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.xs),
      onTap: () => context.go('/users/${p.id}'),
      leading: CircleAvatar(child: Text(p.initials)),
      title: Wrap(spacing: Space.sm, runSpacing: Space.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(p.displayName, style: context.text.titleSmall),
        ...userTags(context, user),
      ]),
      subtitle: Text(
        [
          p.email ?? 'No email',
          if (user.listingCount > 0) '${user.listingCount} listing${user.listingCount == 1 ? '' : 's'}',
          'joined ${Dates.day(p.createdAt)}',
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

/// Role, suspension and deletion labels for a user.
List<Widget> userTags(BuildContext context, AdminUser user) {
  final p = user.profile;
  final palette = context.palette;
  final daysLeft = user.deletionDaysLeft();
  return [
    Tag(
      label: p.role.label,
      foreground: p.isAdmin ? context.colors.onPrimaryContainer : context.colors.onSurface,
      background: p.isAdmin ? context.colors.primaryContainer : palette.neutralContainer,
    ),
    if (p.isSuspended) Tag(label: 'Suspended', foreground: palette.danger, background: palette.dangerContainer),
    if (daysLeft != null)
      Tag(
        label: daysLeft <= 0 ? 'Deletion overdue' : 'Delete within $daysLeft day${daysLeft == 1 ? '' : 's'}',
        icon: Icons.delete_outline_rounded,
        foreground: daysLeft <= 7 ? palette.danger : palette.warning,
        background: daysLeft <= 7 ? palette.dangerContainer : palette.warningContainer,
      ),
  ];
}

class _DeletionLog extends ConsumerWidget {
  const _DeletionLog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(deletionLogProvider);
    return Panel(
      title: 'Processed deletions',
      child: switch (log) {
        AsyncData(:final value) when value.isEmpty => const Text('None yet.'),
        AsyncData(:final value) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Kept as proof of deletion. Holds no personal data.', style: context.text.bodySmall),
            Gap.sm,
            for (final d in value)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.xs),
                child: Text([
                  '${d.role.label} deleted ${formatDateTime(d.processedAt)}',
                  if (d.requestedAt != null)
                    '${d.processedAt.difference(d.requestedAt!).inDays} days after the request',
                  if (d.listingsRemoved > 0) '${d.listingsRemoved} listing${d.listingsRemoved == 1 ? '' : 's'} removed',
                ].join(' · ')),
              ),
          ]),
        AsyncError(:final error) => Text(mapToFailure(error).message),
        _ => const LinearProgressIndicator(),
      },
    );
  }
}
