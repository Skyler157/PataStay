import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/routes.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../properties/presentation/widgets/property_widgets.dart';
import '../application/host_providers.dart';

/// The host's enquiries inbox.
class HostEnquiriesScreen extends ConsumerStatefulWidget {
  const HostEnquiriesScreen({super.key});

  @override
  ConsumerState<HostEnquiriesScreen> createState() => _HostEnquiriesScreenState();
}

class _HostEnquiriesScreenState extends ConsumerState<HostEnquiriesScreen> {
  bool _waitingOnly = true;

  bool _isWaiting(Enquiry e) => e.status == EnquiryStatus.newEnquiry || e.status == EnquiryStatus.seen;

  @override
  Widget build(BuildContext context) {
    final enquiries = ref.watch(hostEnquiriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Guest enquiries')),
      body: switch (enquiries) {
        AsyncData(:final value) => Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.sm),
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text('Waiting for you (${value.where(_isWaiting).length})')),
                  ButtonSegment(value: false, label: Text('All (${value.length})')),
                ],
                selected: {_waitingOnly},
                onSelectionChanged: (s) => setState(() => _waitingOnly = s.first),
              ),
            ),
            Expanded(
              child: Builder(builder: (context) {
                final shown = _waitingOnly ? value.where(_isWaiting).toList() : value;
                if (shown.isEmpty) {
                  return EmptyView(
                    icon: Icons.mark_email_read_outlined,
                    title: _waitingOnly ? 'You are all caught up' : 'No enquiries yet',
                    message: _waitingOnly
                        ? 'New enquiries from guests will appear here.'
                        : 'When guests ask about your places, their enquiries appear here.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(hostEnquiriesProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.xxl),
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => Gap.md,
                    itemBuilder: (_, i) => _Tile(enquiry: shown[i]),
                  ),
                );
              }),
            ),
          ]),
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(hostEnquiriesProvider)),
        _ => const LoadingView(),
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.enquiry});

  final Enquiry enquiry;

  @override
  Widget build(BuildContext context) {
    final e = enquiry;
    final isNew = e.status == EnquiryStatus.newEnquiry;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.hostEnquiry(e.id)),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Radii.sm),
              child: SizedBox(width: 64, height: 64, child: PropertyPhoto(image: e.propertyCover, thumbnail: true)),
            ),
            Gap.md,
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(e.guestName, style: context.text.titleSmall)),
                  if (isNew) const PataBadge(label: 'New', tone: BadgeTone.featured),
                ]),
                Text(
                  '${e.propertyTitle ?? 'Listing'}${e.reference != null ? ' · ${e.reference}' : ''}',
                  style: context.text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${Dates.shortDay(e.checkIn)} – ${Dates.shortDay(e.checkOut)} · ${e.guestCount} guest${e.guestCount == 1 ? '' : 's'}',
                  style: context.text.bodySmall,
                ),
                Gap.xs,
                Text('${_hostStatus(e.status)} · ${Dates.relative(e.createdAt)}', style: context.text.labelMedium),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

String _hostStatus(EnquiryStatus s) => switch (s) {
      EnquiryStatus.newEnquiry => 'Waiting for your reply',
      EnquiryStatus.seen => 'Seen, not answered',
      EnquiryStatus.available => 'You said available',
      EnquiryStatus.unavailable => 'You said not available',
      EnquiryStatus.cancelled => 'Cancelled by guest',
      EnquiryStatus.booked => 'Stay agreed',
      EnquiryStatus.closed => 'Closed',
    };

/// One enquiry, with reply actions. Opening it tells the guest it was seen.
class HostEnquiryScreen extends ConsumerStatefulWidget {
  const HostEnquiryScreen({super.key, required this.enquiryId});

  final String enquiryId;

  @override
  ConsumerState<HostEnquiryScreen> createState() => _HostEnquiryScreenState();
}

class _HostEnquiryScreenState extends ConsumerState<HostEnquiryScreen> {
  final _reply = TextEditingController();
  bool _busy = false;
  bool _markedSeen = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _markSeen(Enquiry e) {
    if (_markedSeen || e.status != EnquiryStatus.newEnquiry) return;
    _markedSeen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(hostRepositoryProvider).respondToEnquiry(e.id, EnquiryStatus.seen);
        ref.invalidate(hostEnquiriesProvider);
      } catch (_) {
        // Not critical; the guest just will not see "Seen" yet.
      }
    });
  }

  Future<void> _respond(Enquiry e, EnquiryStatus status, {String? done}) async {
    setState(() => _busy = true);
    try {
      await ref.read(hostRepositoryProvider).respondToEnquiry(e.id, status, response: _reply.text);
      ref.invalidate(hostEnquiriesProvider);
      ref.invalidate(hostStatsProvider);
      _reply.clear();
      if (mounted && done != null) context.showMessage(done);
    } on AppFailure catch (failure) {
      if (mounted) context.showFailure(failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Uri uri, String fallback) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      await Clipboard.setData(ClipboardData(text: fallback));
      if (mounted) context.showMessage('Copied $fallback');
    }
  }

  @override
  Widget build(BuildContext context) {
    final enquiries = ref.watch(hostEnquiriesProvider);
    final e = enquiries.value?.where((x) => x.id == widget.enquiryId).firstOrNull;
    if (e != null) _markSeen(e);

    return Scaffold(
      appBar: AppBar(title: const Text('Enquiry')),
      body: e == null
          ? (enquiries.isLoading
              ? const LoadingView()
              : enquiries.hasError
                  ? ErrorView(error: enquiries.error!, onRetry: () => ref.invalidate(hostEnquiriesProvider))
                  : const EmptyView(title: 'Enquiry not found', icon: Icons.mail_outline_rounded))
          : _body(e),
    );
  }

  Widget _body(Enquiry e) {
    final phone = PhoneNumbers.normalize(e.guestContact);
    final email = e.guestContact.contains('@') ? e.guestContact.trim() : null;
    final dates = '${Dates.shortDay(e.checkIn)} to ${Dates.shortDay(e.checkOut)}';
    final whatsappText = 'Hi ${e.guestName.split(' ').first}, thanks for your PataStay enquiry for '
        '"${e.propertyTitle ?? 'my place'}"${e.reference != null ? ' (${e.reference})' : ''}, $dates. ';
    final open = e.status != EnquiryStatus.cancelled && e.status != EnquiryStatus.closed;

    return AbsorbPointer(
      absorbing: _busy,
      child: ListView(
        padding: const EdgeInsets.all(Space.gutter),
        children: [
          Text(e.guestName, style: context.text.headlineSmall),
          Text('${e.propertyTitle ?? 'Listing'}${e.reference != null ? ' · ${e.reference}' : ''}', style: context.text.bodyMedium),
          Gap.sm,
          Text(_hostStatus(e.status), style: context.text.labelLarge?.copyWith(color: context.colors.primary)),
          if (_busy) ...[Gap.sm, const LinearProgressIndicator()],
          Gap.lg,
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _row('Dates', '$dates · ${e.nights} night${e.nights == 1 ? '' : 's'}'),
                _row('Guests', '${e.guestCount}'),
                _row('Reply to', phone != null ? PhoneNumbers.format(phone) : e.guestContact),
                _row('Received', Dates.relative(e.createdAt)),
                if (e.message != null && e.message!.trim().isNotEmpty) ...[
                  Gap.sm,
                  Text('Message', style: context.text.labelMedium),
                  Text(e.message!, style: context.text.bodyLarge),
                ],
              ]),
            ),
          ),
          Gap.md,
          Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
            if (phone != null)
              FilledButton.icon(
                onPressed: () => _open(
                  Uri.parse('https://wa.me/${PhoneNumbers.whatsappDigits(phone)}').replace(queryParameters: {'text': whatsappText}),
                  PhoneNumbers.format(phone),
                ),
                icon: const Icon(Icons.chat_rounded),
                label: const Text('WhatsApp guest'),
              ),
            if (phone != null)
              OutlinedButton.icon(
                onPressed: () => _open(Uri(scheme: 'tel', path: phone), PhoneNumbers.format(phone)),
                icon: const Icon(Icons.call_outlined),
                label: const Text('Call'),
              ),
            if (email != null)
              OutlinedButton.icon(
                onPressed: () => _open(
                  Uri(scheme: 'mailto', path: email, queryParameters: {'subject': 'Your PataStay enquiry'}),
                  email,
                ),
                icon: const Icon(Icons.mail_outline_rounded),
                label: const Text('Email'),
              ),
          ]),
          if (e.status == EnquiryStatus.cancelled) ...[
            Gap.lg,
            const InfoBanner(message: 'The guest cancelled this enquiry.'),
          ],
          if (e.ownerResponse != null && e.ownerResponse!.trim().isNotEmpty) ...[
            Gap.lg,
            Text('Your reply', style: context.text.titleSmall),
            Gap.xs,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(color: context.palette.neutralContainer, borderRadius: BorderRadius.circular(Radii.md)),
              child: Text(e.ownerResponse!, style: context.text.bodyLarge),
            ),
          ],
          if (open && e.status != EnquiryStatus.booked) ...[
            Gap.xl,
            Text('Reply on PataStay', style: context.text.titleSmall),
            Gap.xs,
            Text('The guest sees this in their Enquiries tab.', style: context.text.bodySmall),
            Gap.sm,
            TextField(
              controller: _reply,
              maxLength: 2000,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'e.g. Yes, it is free. The caretaker will meet you at the gate.',
                alignLabelWithHint: true,
              ),
            ),
            Row(children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _respond(e, EnquiryStatus.available, done: 'Sent: the place is available.'),
                  child: const Text('It is available'),
                ),
              ),
              Gap.sm,
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _respond(e, EnquiryStatus.unavailable, done: 'Sent: not available.'),
                  child: const Text('Not available'),
                ),
              ),
            ]),
          ],
          if (open && e.status == EnquiryStatus.available) ...[
            Gap.lg,
            OutlinedButton.icon(
              onPressed: () => _respond(e, EnquiryStatus.booked, done: 'Marked as a stay agreed. Thank you.'),
              icon: const Icon(Icons.handshake_outlined),
              label: const Text('We agreed a stay'),
            ),
          ],
          if (open) ...[
            Gap.sm,
            TextButton(
              onPressed: () => _respond(e, EnquiryStatus.closed, done: 'Enquiry closed.'),
              child: const Text('Close enquiry'),
            ),
          ],
          Gap.lg,
          const InfoBanner(
            message: 'Agree prices and payment directly with the guest. Never ask for payment before the guest has '
                'seen the place or had a live video call. PataStay never takes payments.',
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: Space.xs),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 90, child: Text(label, style: context.text.bodyMedium?.copyWith(color: context.palette.mutedText))),
          Expanded(child: Text(value, style: context.text.bodyMedium)),
        ]),
      );
}
