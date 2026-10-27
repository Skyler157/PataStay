import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../core/admin_widgets.dart';
import '../../core/csv.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';

/// All listings with status filters and search. In [reviewQueue] mode it
/// shows only listings waiting for review, oldest first.
class ListingsScreen extends ConsumerStatefulWidget {
  const ListingsScreen({super.key, this.reviewQueue = false, this.initialStatus});

  final bool reviewQueue;
  final PropertyStatus? initialStatus;

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> {
  late PropertyStatus? _status = widget.reviewQueue ? PropertyStatus.pendingReview : widget.initialStatus;
  String _query = '';

  ListingQuery get _key => (status: _status, query: _query);

  static const _filters = [
    PropertyStatus.pendingReview,
    PropertyStatus.published,
    PropertyStatus.rejected,
    PropertyStatus.paused,
    PropertyStatus.suspended,
    PropertyStatus.draft,
    PropertyStatus.archived,
  ];

  void _export(List<AdminListing> listings) {
    final csv = toCsv([
      ['Reference', 'Title', 'Status', 'Type', 'Area', 'Nightly rate (KES)', 'Bedrooms', 'Max guests', 'Verified',
          'Featured', 'Sample', 'Host', 'Host email', 'Enquiries', 'Reports', 'Submitted', 'Approved', 'Updated'],
      for (final l in listings)
        [
          l.property.reference,
          l.listing.displayTitle,
          l.status.label,
          l.property.propertyType?.label,
          l.property.neighbourhood?.name,
          l.property.nightlyRate,
          l.property.bedrooms,
          l.property.maximumGuests,
          l.property.isVerified ? 'Yes' : 'No',
          l.property.isFeatured ? 'Yes' : 'No',
          l.property.isSeed ? 'Yes' : 'No',
          l.owner?.displayName,
          l.owner?.email,
          l.enquiryCount,
          l.reportCount,
          l.listing.submittedAt?.toIso8601String(),
          l.listing.approvedAt?.toIso8601String(),
          l.listing.updatedAt?.toIso8601String(),
        ],
    ]);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final saved = downloadCsv('patastay-listings-$today.csv', csv);
    context.showMessage(saved ? 'Exported ${listings.length} listings.' : 'Export is only available in the browser.');
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(adminListingsProvider(_key));

    return AdminPage(
      title: widget.reviewQueue ? 'Review queue' : 'Listings',
      subtitle: widget.reviewQueue
          ? 'Oldest first. Approve listings that look honest and complete; otherwise ask the host for changes.'
          : null,
      actions: [
        SearchBox(hint: 'PS-number or title', onChanged: (q) => setState(() => _query = q)),
        if (!widget.reviewQueue)
          OutlinedButton.icon(
            onPressed: listings.value == null || listings.value!.isEmpty ? null : () => _export(listings.value!),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export CSV'),
          ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(adminListingsProvider(_key)),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      children: [
        if (!widget.reviewQueue) ...[
          Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
            ChoiceChip(label: const Text('All'), selected: _status == null, onSelected: (_) => setState(() => _status = null)),
            for (final s in _filters)
              ChoiceChip(label: Text(s.label), selected: _status == s, onSelected: (_) => setState(() => _status = s)),
          ]),
          Gap.lg,
        ],
        switch (listings) {
          AsyncData(:final value) when value.isEmpty => SizedBox(
              height: 300,
              child: EmptyView(
                icon: widget.reviewQueue ? Icons.task_alt_rounded : Icons.home_work_outlined,
                title: widget.reviewQueue ? 'All caught up' : 'No listings found',
                message: widget.reviewQueue ? 'No listings are waiting for review.' : 'Try another filter or search.',
              ),
            ),
          AsyncData(:final value) => Card(
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (var i = 0; i < value.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListingRow(listing: value[i], showWaiting: widget.reviewQueue),
                ],
              ]),
            ),
          AsyncError(:final error) => SizedBox(
              height: 300,
              child: ErrorView(error: error, onRetry: () => ref.invalidate(adminListingsProvider(_key))),
            ),
          _ => const SizedBox(height: 300, child: LoadingView()),
        },
      ],
    );
  }
}

class ListingRow extends StatelessWidget {
  const ListingRow({super.key, required this.listing, this.showWaiting = false});

  final AdminListing listing;
  final bool showWaiting;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    final p = l.property;
    final submitted = l.listing.submittedAt;
    final waitingDays = submitted == null ? null : DateTime.now().difference(submitted).inDays;
    final details = [
      p.propertyType?.label,
      p.neighbourhood?.name,
      if (p.nightlyRate > 0) '${Money.kes(p.nightlyRate)} / night',
    ].whereType<String>().join(' · ');

    return InkWell(
      onTap: () => context.go('/listings/${l.id}'),
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.sm),
            child: SizedBox(width: 88, height: 64, child: ListingPhoto(image: p.coverImage)),
          ),
          Gap.lg,
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: Space.sm, runSpacing: Space.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(p.reference, style: context.text.labelLarge?.copyWith(color: context.palette.mutedText)),
                StatusChip(l.status),
                if (p.isVerified)
                  Tag(
                    label: 'Verified',
                    icon: Icons.verified_rounded,
                    foreground: context.palette.verified,
                    background: context.palette.verifiedContainer,
                  ),
                if (p.isFeatured)
                  const Tag(label: 'Featured', foreground: PataColors.ink, background: PataColors.saffronContainer),
                if (p.isSeed)
                  Tag(label: 'Sample', foreground: context.colors.onSurface, background: context.palette.neutralContainer),
                if (l.reportCount > 0)
                  Tag(
                    label: '${l.reportCount} report${l.reportCount == 1 ? '' : 's'}',
                    icon: Icons.flag_rounded,
                    foreground: context.palette.danger,
                    background: context.palette.dangerContainer,
                  ),
              ]),
              Gap.xs,
              Text(l.listing.displayTitle, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (details.isNotEmpty) Text(details, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                [
                  'Host: ${l.owner?.displayName ?? 'unknown'}',
                  if (showWaiting && waitingDays != null)
                    waitingDays == 0 ? 'submitted today' : 'waiting $waitingDays day${waitingDays == 1 ? '' : 's'}',
                  if (!showWaiting && l.listing.updatedAt != null) 'updated ${Dates.relative(l.listing.updatedAt!)}',
                ].join(' · '),
                style: context.text.bodySmall?.copyWith(
                  color: showWaiting && (waitingDays ?? 0) >= 2 ? context.palette.warning : context.palette.mutedText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded),
        ]),
      ),
    );
  }
}
