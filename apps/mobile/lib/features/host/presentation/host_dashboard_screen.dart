import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/routing/routes.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../properties/presentation/widgets/property_widgets.dart';
import '../application/host_providers.dart';
import 'host_widgets.dart';

class HostDashboardScreen extends ConsumerStatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  ConsumerState<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends ConsumerState<HostDashboardScreen> {
  bool _creating = false;

  Future<void> _addListing() async {
    setState(() => _creating = true);
    try {
      final id = await ref.read(hostRepositoryProvider).createDraft();
      refreshHostData(ref);
      if (mounted) context.push(Routes.hostEdit(id));
    } on AppFailure catch (failure) {
      if (mounted) context.showFailure(failure);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _refresh() async {
    refreshHostData(ref);
    ref.invalidate(hostEnquiriesProvider);
    await ref.read(hostListingsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(hostListingsProvider);
    final stats = ref.watch(hostStatsProvider).value ?? const {};
    final enquiries = ref.watch(hostEnquiriesProvider).value ?? const [];
    final newEnquiries = ref.watch(newHostEnquiriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hosting')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creating ? null : _addListing,
        icon: _creating
            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
            : const Icon(Icons.add_home_outlined),
        label: const Text('Add a listing'),
      ),
      body: switch (listings) {
        AsyncData(:final value) => RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, 96),
              children: [
                _Summary(listings: value, newEnquiries: newEnquiries),
                Gap.xl,
                _EnquiriesPreview(enquiries: enquiries, newCount: newEnquiries),
                Gap.xl,
                Text('Your listings', style: context.text.titleMedium),
                Gap.md,
                if (value.isEmpty)
                  const EmptyView(
                    icon: Icons.add_home_outlined,
                    title: 'List your first place',
                    message: 'Listing is free. Add photos, a price and your contact number, and our team reviews it '
                        'before guests can see it.',
                  ),
                for (final l in value) ...[
                  _ListingTile(listing: l, stats: stats[l.id] ?? const ListingStats()),
                  Gap.md,
                ],
              ],
            ),
          ),
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(hostListingsProvider)),
        _ => const LoadingView(),
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.listings, required this.newEnquiries});

  final List<HostListing> listings;
  final int newEnquiries;

  @override
  Widget build(BuildContext context) {
    int count(bool Function(HostListing) test) => listings.where(test).length;
    final tiles = [
      ('Live', count((l) => l.status == PropertyStatus.published)),
      ('In review', count((l) => l.status == PropertyStatus.pendingReview)),
      ('Drafts & changes', count((l) => l.status == PropertyStatus.draft || l.status == PropertyStatus.rejected)),
      ('New enquiries', newEnquiries),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - Space.md) / 2;
      return Wrap(
        spacing: Space.md,
        runSpacing: Space.md,
        children: [
          for (final (label, value) in tiles)
            SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(Space.lg),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$value', style: context.text.headlineMedium),
                    Text(label, style: context.text.bodySmall),
                  ]),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _EnquiriesPreview extends StatelessWidget {
  const _EnquiriesPreview({required this.enquiries, required this.newCount});

  final List<Enquiry> enquiries;
  final int newCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.hostEnquiries),
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Row(children: [
            Badge(
              isLabelVisible: newCount > 0,
              label: Text('$newCount'),
              child: Icon(Icons.mark_email_unread_outlined, color: context.colors.primary, size: 28),
            ),
            Gap.lg,
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Guest enquiries', style: context.text.titleSmall),
                Text(
                  enquiries.isEmpty
                      ? 'No enquiries yet. They appear here when guests ask about your places.'
                      : newCount > 0
                          ? '$newCount waiting for your reply · ${enquiries.length} in total'
                          : 'All caught up · ${enquiries.length} in total',
                  style: context.text.bodySmall,
                ),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded),
          ]),
        ),
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.listing, required this.stats});

  final HostListing listing;
  final ListingStats stats;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final attention = l.status == PropertyStatus.rejected || l.status == PropertyStatus.suspended;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.hostListing(l.id)),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: SizedBox(width: 84, height: 72, child: PropertyPhoto(image: l.property.coverImage, thumbnail: true)),
              ),
              Gap.md,
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.displayTitle, style: context.text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(
                    [l.reference, l.property.neighbourhood?.name].whereType<String>().join(' · '),
                    style: context.text.bodySmall,
                  ),
                  Gap.xs,
                  ListingStatusChip(status: l.status),
                ]),
              ),
            ]),
            Gap.sm,
            Text(
              nextStepFor(l),
              style: context.text.bodySmall?.copyWith(color: attention ? context.palette.danger : null),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (l.status == PropertyStatus.draft) ...[
              Gap.sm,
              LinearProgressIndicator(value: l.completeness, minHeight: 6, borderRadius: BorderRadius.circular(Radii.pill)),
            ],
            if (l.approvedAt != null) ...[
              Gap.sm,
              Wrap(spacing: Space.lg, runSpacing: Space.xs, children: [
                StatPill(icon: Icons.visibility_outlined, value: stats.views, label: 'views'),
                StatPill(icon: Icons.chat_outlined, value: stats.contactClicks, label: 'contacts'),
                StatPill(icon: Icons.favorite_border_rounded, value: stats.favourites, label: 'saves'),
                StatPill(icon: Icons.mail_outline_rounded, value: stats.enquiries, label: 'enquiries'),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}
