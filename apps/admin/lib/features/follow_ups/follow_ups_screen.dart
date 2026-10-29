import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/admin_widgets.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';

/// Hosts to remind: unanswered enquiries (guests waiting) and live listings
/// whose availability has not been confirmed. Reminders go by WhatsApp.
class FollowUpsScreen extends ConsumerWidget {
  const FollowUpsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUps = ref.watch(followUpsProvider);
    return AdminPage(
      title: 'Follow-ups',
      subtitle: 'Guests give up when hosts go quiet. Remind hosts on WhatsApp; each reminder is recorded so the team '
          'does not message the same host twice.',
      maxWidth: 1000,
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(followUpsProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      children: [
        switch (followUps) {
          AsyncData(:final value) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _Section(
                title: 'Enquiries waiting for a reply',
                hint: 'Not answered within 24 hours, for stays that have not started yet. Oldest first.',
                empty: 'Every enquiry has been answered within a day.',
                children: [for (final e in value.unanswered) _EnquiryTile(item: e)],
              ),
              _Section(
                title: 'Availability not confirmed',
                hint: 'Live listings not confirmed in 14 days or more. They drop down search results until the host '
                    'confirms.',
                empty: 'All live listings were confirmed recently.',
                children: [for (final s in value.stale) _StaleTile(item: s)],
              ),
            ]),
          AsyncError(:final error) => SizedBox(
              height: 300,
              child: ErrorView(error: error, onRetry: () => ref.invalidate(followUpsProvider)),
            ),
          _ => const SizedBox(height: 300, child: LoadingView()),
        },
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.hint, required this.empty, required this.children});

  final String title;
  final String hint;
  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xxl),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('$title (${children.length})', style: context.text.titleMedium),
        Text(hint, style: context.text.bodySmall),
        Gap.md,
        if (children.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Row(children: [
                Icon(Icons.task_alt_rounded, color: context.palette.success),
                Gap.md,
                Expanded(child: Text(empty)),
              ]),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (var i = 0; i < children.length; i++) ...[if (i > 0) const Divider(height: 1), children[i]],
            ]),
          ),
      ]),
    );
  }
}

String _firstName(String? name) {
  final first = (name ?? '').trim().split(RegExp(r'\s+')).first;
  return first.isEmpty ? 'there' : first;
}

String _ago(DateTime d) {
  final hours = DateTime.now().difference(d).inHours;
  if (hours < 48) return '$hours hours';
  return '${hours ~/ 24} days';
}

/// The WhatsApp reminder for an unanswered enquiry.
String enquiryReminder(UnansweredEnquiry e) =>
    'Hello ${_firstName(e.hostName)}, this is PataStay. A guest asked about ${e.reference} "${e.title}" for '
    '${Dates.shortDay(e.checkIn)} to ${Dates.shortDay(e.checkOut)} (${e.guestCount} guest${e.guestCount == 1 ? '' : 's'}) '
    '${_ago(e.createdAt)} ago and is still waiting for your reply. Please open the PataStay app, go to Profile > '
    'Hosting > Enquiries and reply, even if the dates are not available. Asante!';

/// The WhatsApp reminder for a listing whose availability is stale.
String availabilityReminder(StaleListing s) =>
    'Hello ${_firstName(s.hostName)}, this is PataStay. Is ${s.reference} "${s.title}" still available? Please open '
    'the PataStay app, go to Profile > Hosting, open the listing and tap "Yes, it is still available" so guests keep '
    'seeing it near the top. If it is not available for now, you can pause it there. Asante!';

/// Opens WhatsApp with [message] and records the reminder.
Future<void> _remind(
  BuildContext context,
  WidgetRef ref, {
  required String phone,
  required String message,
  required String propertyId,
  String? enquiryId,
}) async {
  final uri = Uri.parse('https://wa.me/${PhoneNumbers.whatsappDigits(phone)}').replace(queryParameters: {'text': message});
  final opened = await launchUrl(uri, webOnlyWindowName: '_blank');
  if (!context.mounted) return;
  if (!opened) {
    context.showMessage('Could not open WhatsApp.');
    return;
  }
  final ok = await runAction(
    context,
    () => ref.read(adminRepositoryProvider).recordNudge(propertyId, enquiryId: enquiryId),
    success: 'Reminder recorded.',
  );
  if (ok) ref.invalidate(followUpsProvider);
}

class _ReminderButton extends ConsumerWidget {
  const _ReminderButton({
    required this.phone,
    required this.message,
    required this.propertyId,
    this.enquiryId,
    this.lastNudgedAt,
  });

  final String? phone;
  final String message;
  final String propertyId;
  final String? enquiryId;
  final DateTime? lastNudgedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = lastNudgedAt != null && DateTime.now().difference(lastNudgedAt!).inHours < 24;
    final button = recent
        ? OutlinedButton.icon(
            onPressed: phone == null
                ? null
                : () => _remind(context, ref,
                    phone: phone!, message: message, propertyId: propertyId, enquiryId: enquiryId),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Remind again'),
          )
        : FilledButton.tonalIcon(
            onPressed: phone == null
                ? null
                : () => _remind(context, ref,
                    phone: phone!, message: message, propertyId: propertyId, enquiryId: enquiryId),
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: const Text('WhatsApp host'),
          );
    return phone == null ? Tooltip(message: 'This listing has no contact number', child: button) : button;
  }
}

class _EnquiryTile extends StatelessWidget {
  const _EnquiryTile({required this.item});

  final UnansweredEnquiry item;

  @override
  Widget build(BuildContext context) {
    final e = item;
    final hours = DateTime.now().difference(e.createdAt).inHours;
    return _FollowUpRow(
      reference: e.reference,
      title: e.title,
      propertyId: e.propertyId,
      lines: [
        'Host: ${e.hostName?.trim().isNotEmpty ?? false ? e.hostName : 'unknown'}',
        '${Dates.shortDay(e.checkIn)} to ${Dates.shortDay(e.checkOut)} · '
            '${e.guestCount} guest${e.guestCount == 1 ? '' : 's'}',
      ],
      urgency: 'Waiting ${_ago(e.createdAt)}',
      urgent: hours >= 48,
      lastNudgedAt: e.lastNudgedAt,
      action: _ReminderButton(
        phone: e.hostWhatsapp,
        message: enquiryReminder(e),
        propertyId: e.propertyId,
        enquiryId: e.enquiryId,
        lastNudgedAt: e.lastNudgedAt,
      ),
    );
  }
}

class _StaleTile extends StatelessWidget {
  const _StaleTile({required this.item});

  final StaleListing item;

  @override
  Widget build(BuildContext context) {
    final s = item;
    final days = s.confirmedAt == null ? null : DateTime.now().difference(s.confirmedAt!).inDays;
    return _FollowUpRow(
      reference: s.reference,
      title: s.title,
      propertyId: s.propertyId,
      isSeed: s.isSeed,
      lines: ['Host: ${s.hostName?.trim().isNotEmpty ?? false ? s.hostName : 'unknown'}'],
      urgency: days == null ? 'Never confirmed' : 'Last confirmed $days days ago',
      urgent: days == null || days >= 30,
      lastNudgedAt: s.lastNudgedAt,
      action: _ReminderButton(
        phone: s.hostWhatsapp,
        message: availabilityReminder(s),
        propertyId: s.propertyId,
        lastNudgedAt: s.lastNudgedAt,
      ),
    );
  }
}

class _FollowUpRow extends StatelessWidget {
  const _FollowUpRow({
    required this.reference,
    required this.title,
    required this.propertyId,
    required this.lines,
    required this.urgency,
    required this.urgent,
    required this.action,
    this.lastNudgedAt,
    this.isSeed = false,
  });

  final String reference;
  final String title;
  final String propertyId;
  final List<String> lines;
  final String urgency;
  final bool urgent;
  final Widget action;
  final DateTime? lastNudgedAt;
  final bool isSeed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(Space.lg),
      child: Wrap(
        spacing: Space.lg,
        runSpacing: Space.md,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: Space.sm, runSpacing: Space.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
                InkWell(
                  onTap: () => context.go('/listings/$propertyId'),
                  child: Text('$reference: $title',
                      style: context.text.titleSmall?.copyWith(color: context.colors.primary)),
                ),
                Tag(
                  label: urgency,
                  foreground: urgent ? p.danger : p.warning,
                  background: urgent ? p.dangerContainer : p.warningContainer,
                ),
                if (isSeed) Tag(label: 'Sample', foreground: context.colors.onSurface, background: p.neutralContainer),
              ]),
              Gap.xs,
              for (final line in lines) Text(line, style: context.text.bodySmall),
              if (lastNudgedAt != null)
                Text('Reminded ${Dates.relative(lastNudgedAt!)}',
                    style: context.text.bodySmall?.copyWith(color: p.success)),
            ]),
          ),
          action,
        ],
      ),
    );
  }
}
