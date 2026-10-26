import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/routing/routes.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../properties/presentation/widgets/property_widgets.dart';
import '../application/host_providers.dart';
import 'host_widgets.dart';

class ManageListingScreen extends ConsumerWidget {
  const ManageListingScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(hostListingProvider(listingId));
    return Scaffold(
      appBar: AppBar(title: const Text('Manage listing')),
      body: switch (listing) {
        AsyncData(:final value?) => _Manage(listing: value),
        AsyncData() => const EmptyView(title: 'Listing not found', icon: Icons.home_work_outlined),
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(hostListingProvider(listingId))),
        _ => const LoadingView(),
      },
    );
  }
}

class _Manage extends ConsumerStatefulWidget {
  const _Manage({required this.listing});

  final HostListing listing;

  @override
  ConsumerState<_Manage> createState() => _ManageState();
}

class _ManageState extends ConsumerState<_Manage> {
  bool _busy = false;

  HostListing get l => widget.listing;

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    setState(() => _busy = true);
    try {
      await action();
      refreshHostData(ref, listingId: l.id);
      if (mounted && done != null) context.showMessage(done);
    } on AppFailure catch (failure) {
      if (mounted) context.showFailure(failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String body, String action, {bool destructive = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: destructive ? TextButton.styleFrom(foregroundColor: context.colors.error) : null,
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _blockDates() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Dates the place is NOT available',
      saveText: 'Block',
    );
    if (range == null) return;
    await _run(
      () => ref.read(hostRepositoryProvider).blockDates(l.id, start: range.start, end: range.end),
      done: 'Dates blocked. Guests will not be able to choose them.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(hostStatsProvider).value?[l.id] ?? const ListingStats();
    final repo = ref.read(hostRepositoryProvider);
    final upcomingBlocks = l.property.unavailableDates
        .where((r) => !r.endsOn.isBefore(DateTime.now().subtract(const Duration(days: 1))))
        .toList();

    final (BannerTone tone, String title, String message) = switch (l.status) {
      PropertyStatus.draft => (BannerTone.info, 'Draft', l.readyToSubmit
          ? 'Everything is filled in. Submit it for review so guests can see it.'
          : 'Not visible to guests yet. Still needed: ${l.missingForSubmission.join(', ')}.'),
      PropertyStatus.pendingReview => (BannerTone.warning, 'In review',
          'Our team checks every listing before it goes live, usually within a day or two. You can still edit it.'),
      PropertyStatus.rejected => (BannerTone.danger, 'Needs changes',
          '${l.rejectionReason ?? 'The reviewer asked for changes.'} Edit the listing, then submit it again.'),
      PropertyStatus.published => (BannerTone.success, 'Live',
          'Guests can find and contact you. Keep availability confirmed so it ranks well.'),
      PropertyStatus.paused => (BannerTone.info, 'Paused', 'Hidden from guests until you resume it.'),
      PropertyStatus.suspended => (BannerTone.danger, 'Suspended by PataStay',
          '${l.rejectionReason ?? 'This listing broke our rules.'} Contact PataStay support to resolve it.'),
      PropertyStatus.archived => (BannerTone.info, 'Archived', 'This listing is retired.'),
    };

    return AbsorbPointer(
      absorbing: _busy,
      child: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.md),
              child: SizedBox(width: 110, height: 84, child: PropertyPhoto(image: l.property.coverImage, thumbnail: true)),
            ),
            Gap.md,
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.displayTitle, style: context.text.titleMedium),
                Text(
                  [l.reference, l.property.neighbourhood?.name, if (l.property.nightlyRate > 0) '${Money.kes(l.property.nightlyRate)} / night']
                      .whereType<String>()
                      .join(' · '),
                  style: context.text.bodySmall,
                ),
                Gap.xs,
                ListingStatusChip(status: l.status),
              ]),
            ),
          ]),
          Gap.lg,
          InfoBanner(tone: tone, title: title, message: message),
          if (_busy) ...[Gap.md, const LinearProgressIndicator()],
          if (l.approvedAt != null) ...[
            Gap.xl,
            Text('All time', style: context.text.titleSmall),
            Gap.sm,
            Wrap(spacing: Space.lg, runSpacing: Space.sm, children: [
              StatPill(icon: Icons.visibility_outlined, value: stats.views, label: 'views'),
              StatPill(icon: Icons.chat_outlined, value: stats.contactClicks, label: 'WhatsApp / calls'),
              StatPill(icon: Icons.favorite_border_rounded, value: stats.favourites, label: 'saves'),
              StatPill(icon: Icons.mail_outline_rounded, value: stats.enquiries, label: 'enquiries'),
            ]),
          ],
          Gap.xl,
          if (l.canEdit)
            FilledButton.icon(
              onPressed: () => context.push(Routes.hostEdit(l.id)),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l.status == PropertyStatus.draft ? 'Continue setting up' : 'Edit listing'),
            ),
          if (l.canSubmit && l.readyToSubmit) ...[
            Gap.sm,
            OutlinedButton.icon(
              onPressed: () => _run(() async => repo.submitForReview(l.id), done: 'Submitted. We will review it shortly.'),
              icon: const Icon(Icons.send_outlined),
              label: const Text('Submit for review'),
            ),
          ],
          Gap.sm,
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.property(l.id)),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Preview as a guest'),
          ),
          if (l.status == PropertyStatus.published || l.status == PropertyStatus.paused) ...[
            Gap.xl,
            Text('Availability', style: context.text.titleMedium),
            Gap.xs,
            FreshnessLabel(property: l.property),
            Gap.sm,
            FilledButton.tonalIcon(
              onPressed: () => _run(() => repo.confirmAvailability(l.id), done: 'Thanks, availability confirmed.'),
              icon: const Icon(Icons.event_available_outlined),
              label: const Text('Yes, it is still available'),
            ),
          ],
          if (l.canEdit) ...[
            Gap.xl,
            Row(children: [
              Expanded(child: Text('Blocked dates', style: context.text.titleMedium)),
              TextButton.icon(onPressed: _blockDates, icon: const Icon(Icons.add_rounded), label: const Text('Block dates')),
            ]),
            if (upcomingBlocks.isEmpty)
              Text('None. Block dates when the place is already taken or you are using it.', style: context.text.bodySmall),
            for (final r in upcomingBlocks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_busy_outlined),
                title: Text('${Dates.shortDay(r.startsOn)} – ${Dates.shortDay(r.endsOn)}'),
                subtitle: r.note == null ? null : Text(r.note!),
                trailing: IconButton(
                  tooltip: 'Unblock these dates',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: r.id == null ? null : () => _run(() => repo.unblockDates(r.id!), done: 'Dates unblocked.'),
                ),
              ),
          ],
          Gap.xl,
          const Divider(),
          if (l.canPause)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.pause_circle_outline_rounded),
              title: const Text('Pause listing'),
              subtitle: const Text('Hide it from guests for a while, for example when it is fully booked.'),
              onTap: () => _run(() => repo.setPaused(l.id, paused: true), done: 'Listing paused.'),
            ),
          if (l.canResume)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.play_circle_outline_rounded),
              title: const Text('Resume listing'),
              subtitle: const Text('Show it to guests again.'),
              onTap: () => _run(() => repo.setPaused(l.id, paused: false), done: 'Listing is live again.'),
            ),
          if (l.canDelete)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline_rounded, color: context.colors.error),
              title: Text('Delete draft', style: TextStyle(color: context.colors.error)),
              onTap: () async {
                if (await _confirm('Delete this draft?', 'Its details and photos will be removed.', 'Delete', destructive: true)) {
                  await _run(() => repo.deleteDraft(l.id));
                  if (mounted) this.context.go(Routes.hostDashboard);
                }
              },
            )
          else if (l.canArchive)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.archive_outlined, color: context.colors.error),
              title: Text('Archive listing', style: TextStyle(color: context.colors.error)),
              subtitle: const Text('Remove it permanently from PataStay. Past enquiries are kept.'),
              onTap: () async {
                if (await _confirm('Archive this listing?', 'Guests will no longer see it. This cannot be undone in the app.',
                    'Archive', destructive: true)) {
                  await _run(() => repo.archive(l.id));
                  if (mounted) this.context.go(Routes.hostDashboard);
                }
              },
            ),
        ],
      ),
    );
  }
}
