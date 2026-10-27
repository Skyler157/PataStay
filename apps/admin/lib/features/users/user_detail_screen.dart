import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../core/admin_widgets.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../dashboard/platform_stats.dart';
import '../listings/listings_screen.dart';
import 'users_screen.dart';

class UserDetailScreen extends ConsumerWidget {
  const UserDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(adminUserProvider(id));
    return switch (user) {
      AsyncData(:final value?) => _Body(user: value),
      AsyncData() => MessageView(
          icon: Icons.person_off_outlined,
          title: 'User not found',
          message: 'The account may have been deleted.',
          action: OutlinedButton(onPressed: () => context.go('/users'), child: const Text('Back to users')),
        ),
      AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(adminUserProvider(id))),
      _ => const LoadingView(),
    };
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.user});

  final AdminUser user;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  Profile get _p => widget.user.profile;
  AdminRepository get _repo => ref.read(adminRepositoryProvider);
  bool get _isMe => _p.id == ref.read(currentUserIdProvider);

  void _refresh() {
    ref
      ..invalidate(adminUserProvider(_p.id))
      ..invalidate(adminUsersProvider)
      ..invalidate(adminListingsOfProvider(_p.id))
      ..invalidate(adminListingsProvider)
      ..invalidate(platformStatsProvider);
  }

  Future<void> _run(Future<void> Function() action, String success, {bool refresh = true}) async {
    setState(() => _busy = true);
    final ok = await runAction(context, action, success: success);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok && refresh) _refresh();
  }

  Future<void> _changeRole(UserRole role) async {
    if (role == _p.role) return;
    final yes = await confirmAction(
      context,
      title: 'Make ${_p.displayName} ${role == UserRole.admin ? 'an administrator' : 'a ${role.label.toLowerCase()}'}?',
      message: switch (role) {
        UserRole.admin => 'Administrators can approve and suspend listings, see private contact numbers and exact '
            'locations, and manage every user. Only do this for trusted PataStay staff.',
        UserRole.owner => 'They will be able to create and manage listings.',
        UserRole.guest => 'They will no longer be able to create listings. Existing listings stay as they are.',
      },
      action: 'Change role',
      destructive: role == UserRole.admin,
    );
    if (yes) await _run(() => _repo.setRole(_p.id, role), 'Role changed.');
  }

  Future<void> _suspend() async {
    final reason = await askForReason(
      context,
      title: 'Suspend ${_p.displayName}?',
      message: 'They can still sign in but cannot send enquiries or edit listings. Their live and pending '
          'listings are suspended too.',
      action: 'Suspend account',
      destructive: true,
    );
    if (reason != null) await _run(() => _repo.setAccountStatus(_p.id, AccountStatus.suspended, reason: reason), 'Account suspended.');
  }

  Future<void> _reactivate() async {
    final yes = await confirmAction(
      context,
      title: 'Reactivate ${_p.displayName}?',
      message: 'Their account works normally again. Suspended listings stay suspended; reinstate them one by one '
          'after checking them.',
      action: 'Reactivate',
    );
    if (yes) await _run(() => _repo.setAccountStatus(_p.id, AccountStatus.active), 'Account reactivated.');
  }

  Future<void> _processDeletion() async {
    final yes = await confirmAction(
      context,
      title: 'Permanently delete ${_p.displayName}?',
      message: 'This deletes the account, profile, listings, photos, saved places and sign-in. Enquiries they sent '
          'stay with hosts but without their name, contact or message. This cannot be undone.',
      action: 'Delete permanently',
      destructive: true,
    );
    if (!yes) return;
    setState(() => _busy = true);
    try {
      final failed = await _repo.processDeletion(_p.id);
      ref
        ..invalidate(adminUsersProvider)
        ..invalidate(adminListingsProvider)
        ..invalidate(deletionLogProvider)
        ..invalidate(platformStatsProvider);
      if (!mounted) return;
      context.showMessage(failed == 0
          ? 'Account deleted.'
          : 'Account deleted. $failed photo file${failed == 1 ? '' : 's'} could not be removed from storage.');
      context.go('/users?filter=deletionRequested');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      context.showFailure(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    final due = widget.user.deletionDueBy;
    final listings = ref.watch(adminListingsOfProvider(p.id));

    return AdminPage(
      maxWidth: 1000,
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => context.canPop() ? context.pop() : context.go('/users'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: p.displayName,
      subtitle: p.email,
      children: [
        Wrap(spacing: Space.sm, runSpacing: Space.xs, children: userTags(context, widget.user)),
        Gap.lg,
        if (p.hasRequestedDeletion)
          Panel(
            title: 'Deletion requested',
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Requested on ${Dates.day(p.deletionRequestedAt!)}. Delete by ${Dates.day(due!)}. '
                  'Their listings were hidden when they asked.'),
              Gap.md,
              if (p.isAdmin)
                const InfoBanner(
                  tone: BannerTone.warning,
                  message: 'Change this account\'s role from Administrator before deleting it.',
                ),
              if (_isMe)
                const InfoBanner(tone: BannerTone.warning, message: 'Another administrator must process your own request.'),
              Gap.sm,
              Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: context.palette.danger, foregroundColor: context.colors.onError),
                  onPressed: _busy || p.isAdmin || _isMe ? null : _processDeletion,
                  icon: const Icon(Icons.delete_forever_rounded),
                  label: const Text('Delete account and data'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          final yes = await confirmAction(context,
                              title: 'Cancel the deletion request?',
                              message: 'Only do this if the user asked to keep their account. Their listings stay '
                                  'archived; they can relist them.',
                              action: 'Keep account');
                          if (yes) await _run(() => _repo.cancelDeletion(p.id), 'Deletion request cancelled.');
                        },
                  child: const Text('Cancel request'),
                ),
              ]),
            ]),
          ),
        Panel(
          title: 'Profile',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Fact('Name', p.fullName),
            Fact('Email', p.email),
            Fact('Phone', p.phone),
            Fact('Member since', Dates.day(p.createdAt)),
            if (p.isSuspended) Fact('Suspended because', p.suspendedReason),
          ]),
        ),
        Panel(
          title: 'Access',
          child: _isMe
              ? const Text('This is your account. Another administrator must change your role or status.')
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Role', style: context.text.labelLarge),
                  Gap.sm,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<UserRole>(
                      segments: [for (final r in UserRole.values) ButtonSegment(value: r, label: Text(r.label))],
                      selected: {p.role},
                      onSelectionChanged: _busy ? null : (s) => _changeRole(s.first),
                    ),
                  ),
                  Gap.lg,
                  Align(
                    alignment: Alignment.centerLeft,
                    child: p.isSuspended
                        ? FilledButton.tonal(onPressed: _busy ? null : _reactivate, child: const Text('Reactivate account'))
                        : OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: context.palette.danger),
                            onPressed: _busy ? null : _suspend,
                            icon: const Icon(Icons.block_rounded),
                            label: const Text('Suspend account'),
                          ),
                  ),
                ]),
        ),
        Panel(
          title: 'Listings',
          child: switch (listings) {
            AsyncData(:final value) when value.isEmpty => const Text('No listings.'),
            AsyncData(:final value) => Column(children: [
                for (var i = 0; i < value.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListingRow(listing: value[i]),
                ],
              ]),
            AsyncError(:final error) => Text(mapToFailure(error).message),
            _ => const LinearProgressIndicator(),
          },
        ),
      ],
    );
  }
}
