import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/routes.dart';
import '../../reports/presentation/report_sheet.dart';
import '../application/property_providers.dart';
import 'widgets/property_widgets.dart';

Future<void> showContactSheet(BuildContext context, Property property, {DateTime? checkIn, DateTime? checkOut}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ContactSheet(property: property, checkIn: checkIn, checkOut: checkOut),
  );
}

/// Pre-filled first message that quotes the listing reference, so the host
/// and guest can confirm they mean the same real listing.
String whatsappMessage(Property property, {String? hostName, DateTime? checkIn, DateTime? checkOut}) {
  final greeting = hostName == null ? 'Hi' : 'Hi $hostName';
  final dates = (checkIn != null && checkOut != null)
      ? ' Is it available ${Dates.shortDay(checkIn)} to ${Dates.shortDay(checkOut)}?'
      : ' Is it available?';
  return '$greeting, I found your place "${property.title}" on PataStay (${property.reference}).$dates';
}

class _ContactSheet extends ConsumerStatefulWidget {
  const _ContactSheet({required this.property, this.checkIn, this.checkOut});

  final Property property;
  final DateTime? checkIn;
  final DateTime? checkOut;

  @override
  ConsumerState<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<_ContactSheet> {
  bool _busy = false;

  Future<void> _contact({required bool whatsapp}) async {
    setState(() => _busy = true);
    try {
      final contact = await ref.read(propertyRepositoryProvider).revealContact(widget.property.id, whatsapp: whatsapp);
      final host = ref.read(hostSummaryProvider(widget.property.id)).value;
      final uri = whatsapp
          ? Uri.parse('https://wa.me/${PhoneNumbers.whatsappDigits(contact.whatsappPhone)}').replace(
              queryParameters: {
                'text': whatsappMessage(widget.property,
                    hostName: host?.displayName, checkIn: widget.checkIn, checkOut: widget.checkOut),
              },
            )
          : Uri(scheme: 'tel', path: contact.phone);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) await _showNumber(whatsapp ? contact.whatsappPhone : contact.phone, whatsapp: whatsapp);
    } on AppFailure catch (failure) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Fallback when WhatsApp or the dialler cannot be opened.
  Future<void> _showNumber(String number, {required bool whatsapp}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(whatsapp ? 'WhatsApp is not available' : 'Could not open the dialler'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Contact the host on this number:"),
          Gap.sm,
          SelectableText(PhoneNumbers.format(number), style: context.text.titleLarge),
        ]),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: number));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Copy number'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final signedIn = ref.watch(currentUserIdProvider) != null;
    final host = ref.watch(hostSummaryProvider(p.id)).value;
    final hostName = host?.displayName ?? 'the host';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Before you contact $hostName', style: context.text.titleLarge),
          Gap.lg,
          const _Rule(text: 'Never pay a deposit before you have seen the place, in person or on a live video call.'),
          _Rule(text: 'Ask the host to confirm the listing reference ${p.reference}.'),
          const _Rule(text: 'PataStay never takes payments. Anyone asking you to pay "PataStay" is a scammer.'),
          if (showSampleLabel(ref, p)) ...[
            Gap.md,
            const InfoBanner(
              tone: BannerTone.warning,
              message: 'This is a sample listing. The number belongs to a test account, not a real host.',
            ),
          ],
          Gap.lg,
          if (!signedIn) ...[
            const InfoBanner(
              message: 'Sign in to see the host\'s number. It keeps host numbers safe from scrapers and lets you track your enquiries.',
            ),
            Gap.lg,
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(Routes.signInReturningTo(Routes.property(p.id)));
              },
              child: const Text('Sign in to continue'),
            ),
          ] else ...[
            Text('Your first message', style: context.text.titleSmall),
            Gap.xs,
            Container(
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: context.palette.neutralContainer,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: Text(
                whatsappMessage(p, hostName: host?.displayName, checkIn: widget.checkIn, checkOut: widget.checkOut),
                style: context.text.bodyMedium,
              ),
            ),
            Gap.lg,
            FilledButton.icon(
              onPressed: _busy ? null : () => _contact(whatsapp: true),
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Continue on WhatsApp'),
            ),
            Gap.sm,
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _contact(whatsapp: false),
              icon: const Icon(Icons.call_outlined),
              label: const Text('Call the host'),
            ),
            Gap.sm,
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push(Routes.enquire(p.id));
              },
              icon: const Icon(Icons.mail_outline_rounded),
              label: const Text('Send an enquiry instead'),
            ),
          ],
          Gap.md,
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                showReportSheet(context, p);
              },
              child: Text('Something feels off? Report this listing', style: TextStyle(color: context.colors.error)),
            ),
          ),
          if (p.verifiedAt == null)
            Text(
              'This listing has been reviewed by PataStay but not yet verified in person.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          if (p.verifiedAt != null) Center(child: VerifiedBadge(verifiedAt: p.verifiedAt!, long: true)),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: context.palette.warningContainer, shape: BoxShape.circle),
            child: Icon(Icons.priority_high_rounded, size: 16, color: context.palette.warning),
          ),
          Gap.md,
          Expanded(child: Text(text, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}
