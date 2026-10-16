import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/routing/routes.dart';

Future<void> showReportSheet(BuildContext context, Property property) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ReportSheet(property: property),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.property});

  final Property property;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  ReportReason? _reason;
  final _details = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) {
      setState(() => _error = 'Choose what is wrong with this listing.');
      return;
    }
    if (reason == ReportReason.other && _details.text.trim().length < 10) {
      setState(() => _error = 'Tell us a little more (at least 10 characters).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(reportRepositoryProvider).report(
            propertyId: widget.property.id,
            reason: reason,
            description: _details.text,
          );
      if (mounted) setState(() => _sent = true);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(currentUserIdProvider) != null;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    if (_sent) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const InfoBanner(
            tone: BannerTone.success,
            title: 'Thank you, we have received your report',
            message: 'Our team reviews every report. Listings that break our rules are suspended. '
                'If you have already lost money, also report it to the police (DCI).',
          ),
          Gap.lg,
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ]),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.xl + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Report ${widget.property.reference}', style: context.text.titleLarge),
          Gap.xs,
          Text('Reports are private. The host will not see who reported them.', style: context.text.bodySmall),
          Gap.lg,
          if (!signedIn) ...[
            const InfoBanner(message: 'Sign in to report a listing. This stops fake reports.'),
            Gap.lg,
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(Routes.signInReturningTo(Routes.property(widget.property.id)));
              },
              child: const Text('Sign in'),
            ),
          ] else ...[
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v),
              child: Column(children: [
                for (final r in ReportReason.values)
                  RadioListTile<ReportReason>(
                    value: r,
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.label),
                    subtitle: Text(r.hint),
                  ),
              ]),
            ),
            Gap.md,
            TextField(
              controller: _details,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'What happened? (optional)',
                hintText: 'For example: the host asked me to pay a deposit to a paybill before viewing.',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[Gap.sm, InfoBanner(tone: BannerTone.danger, message: _error!)],
            Gap.lg,
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: context.colors.error, foregroundColor: context.colors.onError),
              child: Text(_busy ? 'Sending…' : 'Send report'),
            ),
          ],
        ],
      ),
    );
  }
}
