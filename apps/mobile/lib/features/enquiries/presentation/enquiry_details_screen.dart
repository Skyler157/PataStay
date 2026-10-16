import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/routes.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../properties/application/property_providers.dart';
import '../../properties/presentation/widgets/property_widgets.dart';

class EnquiryDetailsScreen extends ConsumerWidget {
  const EnquiryDetailsScreen({super.key, required this.enquiryId});

  final String enquiryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enquiries = ref.watch(myEnquiriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Enquiry')),
      body: switch (enquiries) {
        AsyncData(:final value) => switch (value.where((e) => e.id == enquiryId).firstOrNull) {
            final e? => _Details(enquiry: e),
            null => const EmptyView(title: 'Enquiry not found', icon: Icons.mail_outline_rounded),
          },
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(myEnquiriesProvider)),
        _ => const LoadingView(),
      },
    );
  }
}

class _Details extends ConsumerStatefulWidget {
  const _Details({required this.enquiry});

  final Enquiry enquiry;

  @override
  ConsumerState<_Details> createState() => _DetailsState();
}

class _DetailsState extends ConsumerState<_Details> {
  bool _busy = false;

  Enquiry get e => widget.enquiry;

  Future<void> _whatsappHost() async {
    setState(() => _busy = true);
    try {
      final contact = await ref.read(propertyRepositoryProvider).revealContact(e.propertyId, whatsapp: true);
      final message = 'Hi, I am following up on my PataStay enquiry for "${e.propertyTitle ?? 'your place'}"'
          '${e.reference != null ? ' (${e.reference})' : ''}, '
          '${Dates.shortDay(e.checkIn)} to ${Dates.shortDay(e.checkOut)}, ${e.guestCount} guest${e.guestCount == 1 ? '' : 's'}.';
      final uri = Uri.parse('https://wa.me/${PhoneNumbers.whatsappDigits(contact.whatsappPhone)}')
          .replace(queryParameters: {'text': message});
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) context.showMessage('WhatsApp is not available. Host number: ${PhoneNumbers.format(contact.whatsappPhone)}');
    } on AppFailure catch (failure) {
      if (mounted) context.showFailure(failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _act({required bool cancel}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cancel ? 'Cancel this enquiry?' : 'Did you agree a stay with the host?'),
        content: Text(cancel
            ? 'The host will see that you are no longer interested.'
            : 'This tells PataStay that you and the host agreed this stay. It helps us show which hosts are reliable.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(cancel ? 'Cancel enquiry' : 'Yes, we agreed')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(enquiryRepositoryProvider);
      cancel ? await repo.cancel(e.id) : await repo.reportBooked(e.id);
      ref.invalidate(myEnquiriesProvider);
      if (mounted) context.showMessage(cancel ? 'Enquiry cancelled' : 'Thanks for letting us know');
    } on AppFailure catch (failure) {
      if (mounted) context.showFailure(failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = <_Step>[
      _Step('Enquiry sent', e.createdAt, done: true),
      _Step('Seen by the host', e.seenAt, done: e.seenAt != null || e.hostReplied),
      _Step(
        switch (e.status) {
          EnquiryStatus.available => 'Host says it is available',
          EnquiryStatus.unavailable => 'Host says it is not available',
          _ => 'Host replied',
        },
        e.respondedAt,
        done: e.hostReplied,
      ),
      if (e.status == EnquiryStatus.booked)
        _Step('Stay agreed', e.guestReportedBookingAt ?? e.ownerReportedBookingAt, done: true),
    ];
    final cancelled = e.status == EnquiryStatus.cancelled;

    return ListView(
      padding: const EdgeInsets.all(Space.gutter),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(Routes.property(e.propertyId)),
            child: Row(children: [
              SizedBox(width: 96, height: 80, child: PropertyPhoto(image: e.propertyCover, thumbnail: true)),
              Gap.md,
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.propertyTitle ?? 'Listing', style: context.text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (e.reference != null) Text(e.reference!, style: context.text.bodySmall),
                  Text('View listing', style: context.text.labelMedium?.copyWith(color: context.colors.primary)),
                ]),
              ),
              Gap.md,
            ]),
          ),
        ),
        Gap.xl,
        if (cancelled)
          const InfoBanner(message: 'You cancelled this enquiry.')
        else
          _Timeline(steps: steps),
        if (e.ownerResponse != null && e.ownerResponse!.trim().isNotEmpty) ...[
          Gap.xl,
          Text('Host reply', style: context.text.titleSmall),
          Gap.sm,
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(color: context.palette.neutralContainer, borderRadius: BorderRadius.circular(Radii.md)),
            child: Text(e.ownerResponse!, style: context.text.bodyLarge),
          ),
        ],
        Gap.xl,
        Text('Your enquiry', style: context.text.titleSmall),
        Gap.sm,
        _Row(label: 'Dates', value: '${Dates.shortDay(e.checkIn)} – ${Dates.shortDay(e.checkOut)} · ${e.nights} night${e.nights == 1 ? '' : 's'}'),
        _Row(label: 'Guests', value: '${e.guestCount}'),
        _Row(label: 'Host replies to', value: e.guestContact.startsWith('+') ? PhoneNumbers.format(e.guestContact) : e.guestContact),
        if (e.message != null && e.message!.trim().isNotEmpty) _Row(label: 'Your message', value: e.message!),
        Gap.xl,
        const InfoBanner(
          message: 'An enquiry is not a booking. Agree the stay with the host, and never pay before you are sure the place is real.',
        ),
        Gap.xl,
        if (!cancelled) ...[
          FilledButton.icon(
            onPressed: _busy ? null : _whatsappHost,
            icon: const Icon(Icons.chat_rounded),
            label: const Text('WhatsApp the host'),
          ),
          Gap.sm,
        ],
        if (e.status == EnquiryStatus.available && e.canReportBooked) ...[
          OutlinedButton(onPressed: _busy ? null : () => _act(cancel: false), child: const Text('We agreed a stay')),
          Gap.sm,
        ],
        if (e.canCancel)
          TextButton(
            onPressed: _busy ? null : () => _act(cancel: true),
            child: Text('Cancel enquiry', style: TextStyle(color: context.colors.error)),
          ),
      ],
    );
  }
}

class _Step {
  const _Step(this.label, this.time, {required this.done});

  final String label;
  final DateTime? time;
  final bool done;
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.steps});

  final List<_Step> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(children: [
                  Icon(
                    steps[i].done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 22,
                    color: steps[i].done ? context.palette.success : context.colors.outline,
                  ),
                  if (i < steps.length - 1)
                    Expanded(child: Container(width: 2, color: context.colors.outlineVariant)),
                ]),
                Gap.md,
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Space.lg),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        steps[i].label,
                        style: context.text.titleSmall?.copyWith(
                          color: steps[i].done ? context.colors.onSurface : context.palette.mutedText,
                        ),
                      ),
                      if (steps[i].time != null) Text(Dates.relative(steps[i].time!), style: context.text.bodySmall),
                      if (!steps[i].done) Text('Waiting', style: context.text.bodySmall),
                    ]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(label, style: context.text.bodyMedium?.copyWith(color: context.palette.mutedText))),
        Expanded(child: Text(value, style: context.text.bodyMedium)),
      ]),
    );
  }
}
