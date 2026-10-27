import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../core/admin_widgets.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../dashboard/platform_stats.dart';

/// Guest reports about listings. Open reports come oldest first.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _activeOnly = true;

  @override
  Widget build(BuildContext context) {
    final reports = ref.watch(adminReportsProvider(_activeOnly));
    return AdminPage(
      title: 'Reports',
      subtitle: 'Guests report listings that look like scams or do not match reality. Check the listing, '
          'contact the host if needed, then resolve or dismiss the report.',
      actions: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Needs action')),
            ButtonSegment(value: false, label: Text('All reports')),
          ],
          selected: {_activeOnly},
          onSelectionChanged: (s) => setState(() => _activeOnly = s.first),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(adminReportsProvider(_activeOnly)),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      maxWidth: 900,
      children: [
        switch (reports) {
          AsyncData(:final value) when value.isEmpty => SizedBox(
              height: 300,
              child: EmptyView(
                icon: Icons.task_alt_rounded,
                title: _activeOnly ? 'No open reports' : 'No reports yet',
                message: _activeOnly ? 'Nothing needs attention right now.' : null,
              ),
            ),
          AsyncData(:final value) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final r in value) Card(child: Padding(padding: const EdgeInsets.all(Space.lg), child: ReportCard(report: r))),
            ]),
          AsyncError(:final error) => SizedBox(
              height: 300,
              child: ErrorView(error: error, onRetry: () => ref.invalidate(adminReportsProvider(_activeOnly))),
            ),
          _ => const SizedBox(height: 300, child: LoadingView()),
        },
      ],
    );
  }
}

class ReportCard extends ConsumerWidget {
  const ReportCard({super.key, required this.report, this.showListing = true});

  final AdminReport report;
  final bool showListing;

  Future<void> _update(BuildContext context, WidgetRef ref, ReportStatus status) async {
    String? note;
    if (status == ReportStatus.resolved || status == ReportStatus.dismissed) {
      note = await askForReason(
        context,
        title: status == ReportStatus.resolved ? 'Resolve report' : 'Dismiss report',
        message: status == ReportStatus.resolved
            ? 'What did you do? For example: "Suspended the listing" or "Host corrected the price".'
            : 'Why is no action needed? For example: "Photos checked on a video call; they are genuine."',
        action: status == ReportStatus.resolved ? 'Resolve' : 'Dismiss',
        minLength: 5,
      );
      if (note == null) return;
    }
    if (!context.mounted) return;
    final ok = await runAction(
      context,
      () => ref.read(adminRepositoryProvider).updateReport(report.id, status, note: note),
      success: 'Report ${status.label.toLowerCase()}.',
    );
    if (ok) {
      ref
        ..invalidate(adminReportsProvider)
        ..invalidate(listingReportsProvider(report.propertyId))
        ..invalidate(platformStatsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = report;
    final p = context.palette;
    final (Color fg, Color bg) = switch (r.status) {
      ReportStatus.open => (p.danger, p.dangerContainer),
      ReportStatus.investigating => (p.warning, p.warningContainer),
      ReportStatus.resolved => (p.success, p.successContainer),
      ReportStatus.dismissed => (context.colors.onSurface, p.neutralContainer),
    };

    return Padding(
      padding: EdgeInsets.only(bottom: showListing ? 0 : Space.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: Space.sm, runSpacing: Space.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(r.reason.label, style: context.text.titleSmall),
          Tag(label: r.status.label, foreground: fg, background: bg),
        ]),
        Gap.xs,
        Text(
          [
            'Reported ${Dates.relative(r.createdAt)}',
            'by ${r.reporterName?.trim().isNotEmpty ?? false ? r.reporterName : (r.reporterEmail ?? 'a deleted user')}',
            if (r.reporterEmail != null && (r.reporterName?.trim().isNotEmpty ?? false)) r.reporterEmail!,
          ].join(' · '),
          style: context.text.bodySmall,
        ),
        if (showListing) ...[
          Gap.sm,
          InkWell(
            onTap: () => context.go('/listings/${r.propertyId}'),
            child: Row(children: [
              Icon(Icons.home_work_outlined, size: 18, color: context.colors.primary),
              Gap.sm,
              Flexible(
                child: Text(
                  '${r.reference}: ${r.propertyTitle ?? ''}',
                  style: context.text.bodyMedium?.copyWith(color: context.colors.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (r.propertyStatus != null) ...[Gap.sm, StatusChip(r.propertyStatus!)],
            ]),
          ),
        ],
        if (r.description?.trim().isNotEmpty ?? false) ...[
          Gap.sm,
          Container(
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(color: p.neutralContainer, borderRadius: BorderRadius.circular(Radii.sm)),
            child: SelectableText(r.description!),
          ),
        ],
        if (r.resolutionNote != null) ...[
          Gap.sm,
          Text('Outcome: ${r.resolutionNote}', style: context.text.bodyMedium),
        ],
        if (r.status.isActive) ...[
          Gap.md,
          Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
            if (r.status == ReportStatus.open)
              OutlinedButton(
                onPressed: () => _update(context, ref, ReportStatus.investigating),
                child: const Text('Start investigating'),
              ),
            FilledButton.tonal(
              onPressed: () => _update(context, ref, ReportStatus.resolved),
              child: const Text('Resolve'),
            ),
            TextButton(
              onPressed: () => _update(context, ref, ReportStatus.dismissed),
              child: const Text('Dismiss'),
            ),
          ]),
        ],
      ]),
    );
  }
}
