import 'package:flutter/material.dart';
import 'package:patastay_core/patastay_core.dart';

/// Coloured status label for a listing.
class ListingStatusChip extends StatelessWidget {
  const ListingStatusChip({super.key, required this.status});

  final PropertyStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color fg, Color bg, IconData icon) = switch (status) {
      PropertyStatus.published => (p.success, p.successContainer, Icons.check_circle_outline_rounded),
      PropertyStatus.pendingReview => (p.warning, p.warningContainer, Icons.hourglass_top_rounded),
      PropertyStatus.rejected => (p.danger, p.dangerContainer, Icons.edit_note_rounded),
      PropertyStatus.suspended => (p.danger, p.dangerContainer, Icons.block_rounded),
      PropertyStatus.paused => (context.colors.onSurface, p.neutralContainer, Icons.pause_circle_outline_rounded),
      PropertyStatus.draft || PropertyStatus.archived =>
        (context.colors.onSurface, p.neutralContainer, Icons.drafts_outlined),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            status == PropertyStatus.published ? 'Live' : status.label,
            style: context.text.labelSmall?.copyWith(color: fg),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    );
  }
}

/// What the host should do next for a listing, in one sentence.
String nextStepFor(HostListing l) {
  return switch (l.status) {
    PropertyStatus.draft => l.readyToSubmit
        ? 'Ready to submit for review.'
        : 'Finish ${l.missingForSubmission.length} more item${l.missingForSubmission.length == 1 ? '' : 's'}, then submit for review.',
    PropertyStatus.pendingReview => 'Our team is reviewing it. This usually takes a day or two.',
    PropertyStatus.rejected => 'Needs changes: ${l.rejectionReason ?? 'see the reviewer\'s note'}',
    PropertyStatus.published => l.property.isStale()
        ? 'Confirm it is still available so it keeps showing near the top.'
        : 'Live and visible to guests.',
    PropertyStatus.paused => 'Hidden from guests. Resume it when it is available again.',
    PropertyStatus.suspended => 'Hidden by PataStay: ${l.rejectionReason ?? 'contact support'}',
    PropertyStatus.archived => 'Archived.',
  };
}

/// Small number + label used for listing statistics.
class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.icon, required this.value, required this.label});

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: context.palette.mutedText),
        const SizedBox(width: 4),
        Text('$value', style: context.text.labelLarge),
        const SizedBox(width: 3),
        Text(label, style: context.text.bodySmall),
      ]),
    );
  }
}
