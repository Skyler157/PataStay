import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/routing/routes.dart';
import '../application/host_providers.dart';
import 'editor_steps.dart';
import 'photos_step.dart';

/// The steps of the listing wizard, in order. Each saves to the server, so a
/// host can stop at any point and come back to the draft later.
enum EditorStep {
  basics('Basics', Icons.title_rounded),
  location('Location', Icons.place_outlined),
  rooms('Rooms & guests', Icons.bed_outlined),
  pricing('Pricing', Icons.payments_outlined),
  amenities('Amenities', Icons.checklist_rounded),
  photos('Photos', Icons.photo_library_outlined),
  rules('Check-in & rules', Icons.rule_rounded),
  contact('Contact number', Icons.call_outlined),
  review('Review & submit', Icons.task_alt_rounded);

  const EditorStep(this.title, this.icon);
  final String title;
  final IconData icon;

  /// Which step fixes a missing checklist item.
  static EditorStep forMissing(String item) {
    final i = item.toLowerCase();
    if (i.contains('title') || i.contains('description') || i.contains('type')) return basics;
    if (i.contains('neighbourhood')) return location;
    if (i.contains('bedroom') || i.contains('bathroom') || i.contains('guests')) return rooms;
    if (i.contains('rate')) return pricing;
    if (i.contains('photo')) return photos;
    if (i.contains('phone')) return contact;
    return review;
  }
}

class ListingEditorScreen extends ConsumerStatefulWidget {
  const ListingEditorScreen({super.key, required this.listingId, this.initialStep = 0});

  final String listingId;
  final int initialStep;

  @override
  ConsumerState<ListingEditorScreen> createState() => _ListingEditorScreenState();
}

class _ListingEditorScreenState extends ConsumerState<ListingEditorScreen> {
  late int _index = widget.initialStep.clamp(0, EditorStep.values.length - 1);

  EditorStep get _step => EditorStep.values[_index];

  void _goTo(EditorStep step) => setState(() => _index = step.index);

  /// Called by a step after it saved: refresh data and move on.
  void _saved() {
    refreshHostData(ref, listingId: widget.listingId);
    if (_index < EditorStep.values.length - 1) setState(() => _index++);
  }

  void _close() {
    refreshHostData(ref, listingId: widget.listingId);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.hostListing(widget.listingId));
    }
  }

  Future<void> _openStepMenu(HostListing listing) async {
    final missing = listing.missingForSubmission.map(EditorStep.forMissing).toSet();
    final chosen = await showModalBottomSheet<EditorStep>(
      context: context,
      // Tall enough to show all nine steps without scrolling.
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (final s in EditorStep.values)
            ListTile(
              leading: Icon(s.icon),
              title: Text(s.title),
              selected: s == _step,
              trailing: s == EditorStep.review
                  ? null
                  : missing.contains(s)
                      ? Icon(Icons.error_outline_rounded, color: context.palette.warning)
                      : Icon(Icons.check_circle_rounded, color: context.palette.success),
              onTap: () => Navigator.pop(context, s),
            ),
        ]),
      ),
    );
    if (chosen != null) _goTo(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final listing = ref.watch(hostListingProvider(widget.listingId));
    final current = listing.value;

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index--);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(tooltip: 'Save and close', icon: const Icon(Icons.close_rounded), onPressed: _close),
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_step.title),
            Text('Step ${_index + 1} of ${EditorStep.values.length} · saved as you go', style: context.text.bodySmall),
          ]),
          actions: [
            if (current != null)
              IconButton(tooltip: 'All steps', icon: const Icon(Icons.list_rounded), onPressed: () => _openStepMenu(current)),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: (_index + 1) / EditorStep.values.length, minHeight: 4),
          ),
        ),
        body: switch (listing) {
          AsyncValue(value: final l?) => _body(l),
          AsyncError(:final error) =>
            ErrorView(error: error, onRetry: () => ref.invalidate(hostListingProvider(widget.listingId))),
          AsyncData() => const EmptyView(title: 'Listing not found', icon: Icons.home_work_outlined),
          _ => const LoadingView(),
        },
      ),
    );
  }

  Widget _body(HostListing l) {
    if (!l.canEdit) {
      return const EmptyView(
        icon: Icons.lock_outline_rounded,
        title: 'This listing cannot be edited',
        message: 'Suspended and archived listings are locked. Contact PataStay support if you think this is a mistake.',
      );
    }
    final key = ValueKey('${_step.name}-${l.id}');
    return switch (_step) {
      EditorStep.basics => BasicsStep(key: key, listing: l, onSaved: _saved),
      EditorStep.location => LocationStep(key: key, listing: l, onSaved: _saved),
      EditorStep.rooms => RoomsStep(key: key, listing: l, onSaved: _saved),
      EditorStep.pricing => PricingStep(key: key, listing: l, onSaved: _saved),
      EditorStep.amenities => AmenitiesStep(key: key, listing: l, onSaved: _saved),
      EditorStep.photos => PhotosStep(key: key, listing: l, onSaved: _saved),
      EditorStep.rules => RulesStep(key: key, listing: l, onSaved: _saved),
      EditorStep.contact => ContactStep(key: key, listing: l, onSaved: _saved),
      EditorStep.review => ReviewStep(key: key, listing: l, onFix: _goTo, onDone: _close),
    };
  }
}
