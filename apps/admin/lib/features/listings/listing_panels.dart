import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../core/admin_widgets.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../reports/reports_screen.dart';
import 'listing_review_screen.dart';

/// Automatic warning signs. They inform the decision; they never block it.
class RiskPanel extends StatelessWidget {
  const RiskPanel({super.key, required this.risks});

  final List<RiskSignal> risks;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final high = risks.any((r) => r.high);
    return Card(
      margin: const EdgeInsets.only(bottom: Space.lg),
      color: high ? p.dangerContainer : p.warningContainer,
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded, color: high ? p.danger : p.warning),
            Gap.sm,
            Expanded(
              child: Text(
                '${risks.length} warning sign${risks.length == 1 ? '' : 's'}',
                style: context.text.titleMedium?.copyWith(color: high ? p.danger : p.warning),
              ),
            ),
          ]),
          Gap.xs,
          Text('Look closer before approving. Call the host or ask for a video walkthrough if unsure.',
              style: context.text.bodySmall),
          Gap.md,
          for (final r in risks)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Tag(
                    label: r.high ? 'High' : 'Check',
                    foreground: r.high ? p.danger : p.warning,
                    background: context.colors.surface,
                  ),
                ),
                Gap.sm,
                Expanded(child: Text(r.message)),
              ]),
            ),
        ]),
      ),
    );
  }
}

/// Status, reviewer checklist and the actions allowed in the current status.
class ModerationPanel extends ConsumerStatefulWidget {
  const ModerationPanel({super.key, required this.listing});

  final AdminListing listing;

  @override
  ConsumerState<ModerationPanel> createState() => _ModerationPanelState();
}

class _ModerationPanelState extends ConsumerState<ModerationPanel> {
  static const _checklist = [
    'Photos are clear, show the real place and include the main rooms',
    'Title, type and description match the photos',
    'Price and fees look realistic for the area',
    'The map pin is in the area the listing names',
    'No payment requests or contact details in the text',
  ];
  final _checked = <int>{};
  bool _busy = false;

  AdminRepository get _repo => ref.read(adminRepositoryProvider);
  String get _id => widget.listing.id;

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    final ok = await runAction(context, action, success: success);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) refreshListing(ref, _id);
  }

  Future<void> _approve() async {
    final unchecked = _checklist.length - _checked.length;
    final risks = widget.listing.risks.length;
    final note = await askForReason(
      context,
      title: 'Approve and publish?',
      message: [
        if (risks > 0) 'This listing has $risks warning sign${risks == 1 ? '' : 's'}.',
        if (unchecked > 0) 'You have not ticked $unchecked checklist item${unchecked == 1 ? '' : 's'}.',
        'The listing goes live for guests straight away.',
      ].join(' '),
      action: 'Approve',
      optional: true,
    );
    if (note == null) return;
    await _run(() => _repo.approve(_id, note: note.isEmpty ? null : note), 'Approved. The listing is live.');
  }

  Future<void> _reject() async {
    final reason = await askForReason(
      context,
      title: 'Ask the host for changes',
      message: 'The host sees this message and can edit the listing and submit it again. Be specific, '
          'for example: "Please add a photo of the bathroom and correct the price."',
      action: 'Send to host',
    );
    if (reason == null) return;
    await _run(() => _repo.reject(_id, reason), 'Sent back to the host.');
  }

  Future<void> _suspend() async {
    final reason = await askForReason(
      context,
      title: 'Suspend this listing?',
      message: 'It is hidden from guests at once and the host cannot edit it. Use this for fraud, misleading '
          'listings or serious reports. The host sees the reason.',
      action: 'Suspend',
      destructive: true,
    );
    if (reason == null) return;
    await _run(() => _repo.suspend(_id, reason), 'Listing suspended.');
  }

  Future<void> _reinstate() async {
    final note = await askForReason(
      context,
      title: 'Reinstate this listing?',
      message: widget.listing.listing.approvedAt != null
          ? 'It was approved before, so it goes straight back live.'
          : 'It was never approved, so it goes back to the review queue.',
      action: 'Reinstate',
      optional: true,
    );
    if (note == null) return;
    await _run(() => _repo.reinstate(_id, note: note.isEmpty ? null : note), 'Listing reinstated.');
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final status = l.status;
    final reason = l.listing.rejectionReason;
    final danger = OutlinedButton.styleFrom(foregroundColor: context.palette.danger);

    return Panel(
      title: 'Decision',
      trailing: StatusChip(status),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (l.property.isSeed) ...[
          const InfoBanner(
            tone: BannerTone.warning,
            message: 'Sample listing from the development seed data. Remove sample data before launch.',
          ),
          Gap.md,
        ],
        if (reason != null && (status == PropertyStatus.rejected || status == PropertyStatus.suspended)) ...[
          InfoBanner(
            tone: BannerTone.danger,
            title: status == PropertyStatus.rejected ? 'Changes requested' : 'Suspended',
            message: reason,
          ),
          Gap.md,
        ],
        if (l.listing.submittedAt != null) Fact('Submitted', formatDateTime(l.listing.submittedAt!)),
        if (l.listing.approvedAt != null) Fact('First approved', formatDateTime(l.listing.approvedAt!)),
        if (status == PropertyStatus.pendingReview) ...[
          Gap.sm,
          Text('Before approving, check that:', style: context.text.labelLarge),
          for (var i = 0; i < _checklist.length; i++)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _checked.contains(i),
              onChanged: (v) => setState(() => v! ? _checked.add(i) : _checked.remove(i)),
              title: Text(_checklist[i]),
            ),
          Gap.md,
        ],
        if (_busy)
          const Padding(padding: EdgeInsets.all(Space.md), child: Center(child: CircularProgressIndicator()))
        else
          Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
            if (status == PropertyStatus.pendingReview) ...[
              FilledButton.icon(
                onPressed: _approve,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Approve'),
              ),
              OutlinedButton.icon(
                onPressed: _reject,
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Ask for changes'),
              ),
            ],
            if (status == PropertyStatus.suspended)
              FilledButton.icon(
                onPressed: _reinstate,
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Reinstate'),
              ),
            if (status != PropertyStatus.suspended && status != PropertyStatus.archived)
              OutlinedButton.icon(
                style: danger,
                onPressed: _suspend,
                icon: const Icon(Icons.block_rounded),
                label: const Text('Suspend'),
              ),
            if (status == PropertyStatus.archived)
              const Text('Archived by the host. Nothing to do.'),
          ]),
      ]),
    );
  }
}

/// Verification checks and the Verified badge.
class VerificationPanel extends ConsumerWidget {
  const VerificationPanel({super.key, required this.listing});

  final AdminListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checks = ref.watch(verificationChecksProvider(listing.id));
    final verified = listing.property.isVerified;

    return Panel(
      title: 'Verification',
      trailing: verified
          ? Tag(
              label: 'Verified',
              icon: Icons.verified_rounded,
              foreground: context.palette.verified,
              background: context.palette.verifiedContainer,
            )
          : null,
      child: switch (checks) {
        AsyncData(:final value) => _VerificationBody(listing: listing, checks: value),
        AsyncError(:final error) => Text(mapToFailure(error).message),
        _ => const LinearProgressIndicator(),
      },
    );
  }
}

class _VerificationBody extends ConsumerWidget {
  const _VerificationBody({required this.listing, required this.checks});

  final AdminListing listing;
  final List<VerificationCheck> checks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = VerificationSummary(checks);
    final verified = listing.property.isVerified;
    final repo = ref.read(adminRepositoryProvider);

    Widget requirement(String label, bool done) => Padding(
          padding: const EdgeInsets.only(bottom: Space.xs),
          child: Row(children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: done ? context.palette.success : context.palette.mutedText,
            ),
            Gap.sm,
            Expanded(child: Text(label)),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('The Verified badge needs all three:', style: context.text.labelLarge),
      Gap.xs,
      requirement('Owner identity checked', summary.passed(VerificationCheckType.ownerIdentity)),
      requirement('Right to let (title deed, lease or authority)', summary.passed(VerificationCheckType.ownershipOrAuthority)),
      requirement(
        'Site visit or video walkthrough',
        summary.passed(VerificationCheckType.siteVisit) || summary.passed(VerificationCheckType.videoWalkthrough),
      ),
      Gap.md,
      Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
        OutlinedButton.icon(
          onPressed: () async {
            final saved = await showDialog<bool>(context: context, builder: (_) => _RecordCheckDialog(listingId: listing.id));
            if (saved ?? false) refreshListing(ref, listing.id);
          },
          icon: const Icon(Icons.playlist_add_check_rounded),
          label: const Text('Record a check'),
        ),
        if (!verified)
          FilledButton.icon(
            onPressed: summary.canVerify
                ? () async {
                    final ok = await runAction(context, () => repo.setVerified(listing.id, true),
                        success: 'Verified badge added.');
                    if (ok) refreshListing(ref, listing.id);
                  }
                : null,
            icon: const Icon(Icons.verified_rounded),
            label: const Text('Give Verified badge'),
          )
        else
          TextButton(
            onPressed: () async {
              final yes = await confirmAction(context,
                  title: 'Remove the Verified badge?',
                  message: 'Guests will no longer see this listing as verified. The checks stay on record.',
                  action: 'Remove badge',
                  destructive: true);
              if (!yes || !context.mounted) return;
              final ok = await runAction(context, () => repo.setVerified(listing.id, false), success: 'Badge removed.');
              if (ok) refreshListing(ref, listing.id);
            },
            child: const Text('Remove badge'),
          ),
      ]),
      if (checks.isNotEmpty) ...[
        Gap.lg,
        Text('Check history', style: context.text.labelLarge),
        for (final c in checks)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              switch (c.result) {
                VerificationResult.pass => Icons.check_circle_rounded,
                VerificationResult.fail => Icons.cancel_rounded,
                VerificationResult.inconclusive => Icons.help_rounded,
              },
              color: switch (c.result) {
                VerificationResult.pass => context.palette.success,
                VerificationResult.fail => context.palette.danger,
                VerificationResult.inconclusive => context.palette.warning,
              },
            ),
            title: Text('${c.type.label}: ${c.result.label}'),
            subtitle: Text([
              formatDateTime(c.checkedAt),
              if (c.adminName != null && c.adminName!.isNotEmpty) c.adminName!,
              if (c.notes != null) c.notes!,
            ].join(' · ')),
          ),
      ],
    ]);
  }
}

class _RecordCheckDialog extends ConsumerStatefulWidget {
  const _RecordCheckDialog({required this.listingId});

  final String listingId;

  @override
  ConsumerState<_RecordCheckDialog> createState() => _RecordCheckDialogState();
}

class _RecordCheckDialogState extends ConsumerState<_RecordCheckDialog> {
  var _type = VerificationCheckType.ownerIdentity;
  var _result = VerificationResult.pass;
  final _notes = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref.read(adminRepositoryProvider).recordCheck(widget.listingId, _type, _result,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim()),
      success: 'Check recorded.',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record a verification check'),
      content: SizedBox(
        width: 480,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          DropdownButtonFormField<VerificationCheckType>(
            initialValue: _type,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Check'),
            items: [
              for (final t in VerificationCheckType.values) DropdownMenuItem(value: t, child: Text(t.label)),
            ],
            onChanged: (t) => setState(() => _type = t!),
          ),
          Gap.xs,
          Text(_type.hint, style: context.text.bodySmall),
          Gap.lg,
          SegmentedButton<VerificationResult>(
            segments: [
              for (final r in VerificationResult.values) ButtonSegment(value: r, label: Text(r.label)),
            ],
            selected: {_result},
            onSelectionChanged: (s) => setState(() => _result = s.first),
          ),
          Gap.lg,
          TextField(
            controller: _notes,
            maxLines: 3,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              helperText: 'What you saw. Do not paste ID numbers or document photos here.',
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Save check')),
      ],
    );
  }
}

/// Featured placement on Home, with optional end date and amount charged.
class FeaturingPanel extends ConsumerWidget {
  const FeaturingPanel({super.key, required this.listing});

  final AdminListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = listing.property.isFeatured;
    final until = listing.featuredUntil;
    final repo = ref.read(adminRepositoryProvider);
    return Panel(
      title: 'Featured placement',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(featured
            ? 'Featured${until == null ? ' with no end date' : ' until ${Dates.day(until)}'}. It appears in the Featured row on Home.'
            : 'Not featured. Featured listings appear in a row near the top of Home.'),
        Gap.md,
        Align(
          alignment: Alignment.centerLeft,
          child: featured
              ? OutlinedButton(
                  onPressed: () async {
                    final ok = await runAction(context, () => repo.setFeatured(listing.id, featured: false),
                        success: 'No longer featured.');
                    if (ok) refreshListing(ref, listing.id);
                  },
                  child: const Text('Stop featuring'),
                )
              : FilledButton.tonalIcon(
                  onPressed: () async {
                    final saved =
                        await showDialog<bool>(context: context, builder: (_) => _FeatureDialog(listingId: listing.id));
                    if (saved ?? false) refreshListing(ref, listing.id);
                  },
                  icon: const Icon(Icons.star_rounded),
                  label: const Text('Feature this listing'),
                ),
        ),
      ]),
    );
  }
}

class _FeatureDialog extends ConsumerStatefulWidget {
  const _FeatureDialog({required this.listingId});

  final String listingId;

  @override
  ConsumerState<_FeatureDialog> createState() => _FeatureDialogState();
}

class _FeatureDialogState extends ConsumerState<_FeatureDialog> {
  int? _days = 7;
  final _amount = TextEditingController(text: '0');
  final _notes = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = num.tryParse(_amount.text.replaceAll(',', '').trim());
    if (amount == null || amount < 0) {
      context.showMessage('Enter the amount charged in KES (0 if free).');
      return;
    }
    setState(() => _busy = true);
    final ok = await runAction(
      context,
      () => ref.read(adminRepositoryProvider).setFeatured(
            widget.listingId,
            featured: true,
            until: _days == null ? null : DateTime.now().add(Duration(days: _days!)),
            amountKes: amount,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          ),
      success: 'Listing featured.',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Feature this listing'),
      content: SizedBox(
        width: 480,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('For how long?', style: context.text.labelLarge),
          Gap.sm,
          Wrap(spacing: Space.sm, children: [
            for (final d in [7, 14, 30, null])
              ChoiceChip(
                label: Text(d == null ? 'No end date' : '$d days'),
                selected: _days == d,
                onSelected: (_) => setState(() => _days = d),
              ),
          ]),
          Gap.lg,
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount charged (KES)', helperText: 'Recorded for revenue reports. 0 if free.'),
          ),
          Gap.md,
          TextField(
            controller: _notes,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Notes (optional)', hintText: 'For example: launch promotion'),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Feature')),
      ],
    );
  }
}

class ReportsForListingPanel extends ConsumerWidget {
  const ReportsForListingPanel({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(listingReportsProvider(propertyId));
    return Panel(
      title: 'Reports from guests',
      child: switch (reports) {
        AsyncData(:final value) when value.isEmpty => const Text('No reports.'),
        AsyncData(:final value) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final r in value) ReportCard(report: r, showListing: false),
          ]),
        AsyncError(:final error) => Text(mapToFailure(error).message),
        _ => const LinearProgressIndicator(),
      },
    );
  }
}

class HistoryPanel extends ConsumerWidget {
  const HistoryPanel({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(listingHistoryProvider(propertyId));
    return Panel(
      title: 'Status history',
      child: switch (history) {
        AsyncData(:final value) when value.isEmpty => const Text('No changes recorded.'),
        AsyncData(:final value) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final h in value)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.md),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    h.fromStatus == null ? 'Created as ${h.toStatus.label}' : '${h.fromStatus!.label} → ${h.toStatus.label}',
                    style: context.text.labelLarge,
                  ),
                  Text(
                    [formatDateTime(h.createdAt), if (h.changedByName?.isNotEmpty ?? false) h.changedByName!].join(' · '),
                    style: context.text.bodySmall,
                  ),
                  if (h.reason != null) Text(h.reason!, style: context.text.bodyMedium),
                ]),
              ),
          ]),
        AsyncError(:final error) => Text(mapToFailure(error).message),
        _ => const LinearProgressIndicator(),
      },
    );
  }
}
