import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../core/admin_widgets.dart';
import 'platform_stats.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(platformStatsProvider(_days));

    return AdminPage(
      title: 'Overview',
      actions: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7 days')),
            ButtonSegment(value: 30, label: Text('30 days')),
            ButtonSegment(value: 90, label: Text('90 days')),
          ],
          selected: {_days},
          onSelectionChanged: (s) => setState(() => _days = s.first),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(platformStatsProvider(_days)),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      children: [
        switch (stats) {
          AsyncData(:final value) => _StatsBody(stats: value),
          AsyncError(:final error) => SizedBox(
              height: 360,
              child: ErrorView(error: error, onRetry: () => ref.invalidate(platformStatsProvider(_days))),
            ),
          _ => const SizedBox(height: 360, child: LoadingView()),
        },
      ],
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final PlatformStats stats;

  static String? _waiting(DateTime? since, String prefix) {
    if (since == null) return null;
    final days = DateTime.now().difference(since).inDays;
    return '$prefix ${days == 0 ? 'today' : '$days day${days == 1 ? '' : 's'} ago'}';
  }

  @override
  Widget build(BuildContext context) {
    final period = 'last ${stats.periodDays} days';
    final responseRate = stats.enquiries == 0 ? null : stats.enquiriesResponded / stats.enquiries;
    final oldestDeletion = stats.deletionOldestRequestedAt;
    final deletionDaysLeft = oldestDeletion == null ? null : 30 - DateTime.now().difference(oldestDeletion).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(title: 'Needs attention', tiles: [
          _Tile('Listings to review', '${stats.listingsPending}',
              caption: _waiting(stats.pendingOldestSubmittedAt, 'Oldest submitted') ?? 'Nothing waiting',
              tone: stats.listingsPending > 0 ? BannerTone.warning : null,
              path: '/review'),
          _Tile('Open reports', '${stats.reportsOpen}',
              tone: stats.reportsOpen > 0 ? BannerTone.danger : null, path: '/reports'),
          _Tile('Account deletions', '${stats.deletionRequests}',
              caption: deletionDaysLeft == null
                  ? 'No requests'
                  : deletionDaysLeft <= 0
                      ? 'Overdue: the 30-day promise has passed'
                      : 'Oldest due in $deletionDaysLeft day${deletionDaysLeft == 1 ? '' : 's'}',
              tone: stats.deletionRequests == 0
                  ? null
                  : (deletionDaysLeft ?? 30) <= 7
                      ? BannerTone.danger
                      : BannerTone.warning,
              path: '/users?filter=deletionRequested'),
          _Tile('Stale listings', '${stats.listingsStale}', caption: 'Availability not confirmed in 14+ days'),
        ]),
        _Section(title: 'Listings', tiles: [
          _Tile('Published', '${stats.listingsWithStatus(PropertyStatus.published)}',
              caption: 'Excludes sample data', path: '/listings?status=published'),
          _Tile('Verified', '${stats.listingsVerified}'),
          _Tile('Featured', '${stats.listingsFeatured}'),
          _Tile('Suspended', '${stats.listingsWithStatus(PropertyStatus.suspended)}',
              path: '/listings?status=suspended'),
        ]),
        _Section(title: 'Demand ($period)', tiles: [
          _Tile('Listing views', '${stats.views}'),
          _Tile('Contact clicks', '${stats.contactClicks}', caption: 'WhatsApp and phone'),
          _Tile('Enquiries', '${stats.enquiries}'),
          _Tile(
            'Host response rate',
            responseRate == null ? '–' : '${(responseRate * 100).round()}%',
          ),
        ]),
        _Section(title: 'Outcomes and revenue ($period)', tiles: [
          _Tile('Stays reported', '${stats.bookingsReported}', caption: 'Reported by host or guest'),
          _Tile('Confirmed by both', '${stats.bookingsConfirmedByBoth}'),
          _Tile('Promotion revenue', Money.kes(stats.promotionRevenueKes)),
        ]),
        _Section(title: 'People', tiles: [
          _Tile('Users', '${stats.usersTotal}', path: '/users'),
          _Tile('Hosts', '${stats.ownersTotal}', path: '/users?filter=hosts'),
          _Tile('New users ($period)', '${stats.usersNew}'),
        ]),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.tiles});

  final String title;
  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleMedium),
          Gap.md,
          Wrap(spacing: Space.lg, runSpacing: Space.lg, children: tiles),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, {this.caption, this.tone, this.path});

  final String label;
  final String value;
  final String? caption;
  final BannerTone? tone;

  /// Where the tile leads, if anywhere.
  final String? path;

  @override
  Widget build(BuildContext context) {
    final accent = switch (tone) {
      BannerTone.warning => context.palette.warning,
      BannerTone.danger => context.palette.danger,
      _ => context.colors.onSurface,
    };
    return SizedBox(
      width: 220,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: path == null ? null : () => context.go(path!),
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(label, style: context.text.bodyMedium?.copyWith(color: context.palette.mutedText)),
                  ),
                  if (path != null) Icon(Icons.chevron_right_rounded, size: 18, color: context.palette.mutedText),
                ]),
                Gap.sm,
                Text(value, style: context.text.headlineMedium?.copyWith(color: accent)),
                if (caption != null) ...[Gap.xs, Text(caption!, style: context.text.bodySmall)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
