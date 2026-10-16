import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/routing/routes.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../properties/application/property_providers.dart';
import '../../properties/presentation/search_screen.dart' show GuestStepper;
import '../../properties/presentation/widgets/stay_date_picker.dart';

class EnquiryFormScreen extends ConsumerWidget {
  const EnquiryFormScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = ref.watch(propertyDetailsProvider(propertyId));
    final profile = ref.watch(currentProfileProvider);
    return switch ((property, profile)) {
      (AsyncData(value: final p?), AsyncData(value: final me?)) => _EnquiryForm(property: p, profile: me),
      (AsyncData(value: null), _) => Scaffold(
          appBar: AppBar(),
          body: const EmptyView(title: 'This listing is not available', icon: Icons.home_work_outlined),
        ),
      (AsyncError(:final error), _) || (_, AsyncError(:final error)) => Scaffold(
          appBar: AppBar(),
          body: ErrorView(error: error, onRetry: () {
            ref.invalidate(propertyDetailsProvider(propertyId));
            ref.invalidate(currentProfileProvider);
          }),
        ),
      _ => Scaffold(appBar: AppBar(), body: const LoadingView()),
    };
  }
}

class _EnquiryForm extends ConsumerStatefulWidget {
  const _EnquiryForm({required this.property, required this.profile});

  final Property property;
  final Profile profile;

  @override
  ConsumerState<_EnquiryForm> createState() => _EnquiryFormState();
}

class _EnquiryFormState extends ConsumerState<_EnquiryForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _contact = TextEditingController(
    text: widget.profile.phone != null ? PhoneNumbers.format(widget.profile.phone!) : (widget.profile.email ?? ''),
  );
  final _message = TextEditingController();
  late DateTime? _checkIn = ref.read(searchFiltersProvider).checkIn;
  late DateTime? _checkOut = ref.read(searchFiltersProvider).checkOut;
  late int _guests = (ref.read(searchFiltersProvider).guests ?? 1).clamp(1, widget.property.maximumGuests ?? 30);
  bool _busy = false;
  List<String> _problems = const [];

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final range = await pickStayDates(context, checkIn: _checkIn, checkOut: _checkOut, property: widget.property);
    if (range != null) {
      setState(() {
        _checkIn = range.start;
        _checkOut = range.end;
        _problems = const [];
      });
    }
  }

  static String? _contactValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Add a phone number or email so the host can reply';
    if (v.contains('@')) return Validators.email(v);
    return Validators.phone(isRequired: true)(v);
  }

  Future<void> _submit() async {
    final problems = stayProblems(widget.property, checkIn: _checkIn, checkOut: _checkOut, guests: _guests);
    setState(() => _problems = problems);
    final formOk = _formKey.currentState!.validate();
    if (problems.isNotEmpty || !formOk) return;

    setState(() => _busy = true);
    try {
      final contact = _contact.text.contains('@') ? _contact.text.trim() : PhoneNumbers.normalize(_contact.text)!;
      final enquiry = await ref.read(enquiryRepositoryProvider).create(
            propertyId: widget.property.id,
            checkIn: _checkIn!,
            checkOut: _checkOut!,
            guestCount: _guests,
            guestName: _name.text,
            guestContact: contact,
            message: _message.text,
          );
      ref.invalidate(myEnquiriesProvider);
      if (mounted) context.pushReplacement(Routes.enquirySent, extra: enquiry);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _problems = [failure.message]);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final quote = StayQuote.forStay(p, _checkIn, _checkOut);
    return FormPage(
      title: 'Send an enquiry',
      children: [
        Text(p.title, style: context.text.titleMedium),
        Text('${p.reference} · ${p.neighbourhood?.name ?? ''}', style: context.text.bodySmall),
        Gap.lg,
        const InfoBanner(
          title: 'This is not a booking',
          message: 'Your enquiry asks the host whether the place is available. '
              'The host confirms availability and agrees the stay directly with you.',
        ),
        Gap.xl,
        Text('Your stay', style: context.text.titleSmall),
        Gap.sm,
        OutlinedButton.icon(
          onPressed: _pickDates,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(_checkIn != null && _checkOut != null
              ? '${Dates.shortDay(_checkIn!)} – ${Dates.shortDay(_checkOut!)}'
              : 'Choose dates'),
        ),
        Gap.md,
        GuestStepper(value: _guests, max: p.maximumGuests ?? 30, onChanged: (v) => setState(() => _guests = v)),
        if (quote != null) ...[
          Gap.sm,
          Text(
            'Estimated total: ${Money.kes(quote.total)} for ${quote.nights} night${quote.nights == 1 ? '' : 's'}'
            '${p.refundableDeposit > 0 ? ' + ${Money.kes(p.refundableDeposit)} refundable deposit' : ''}',
            style: context.text.bodyMedium,
          ),
        ],
        for (final problem in _problems) ...[Gap.sm, InfoBanner(tone: BannerTone.danger, message: problem)],
        Gap.xl,
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: Validators.fullName,
                decoration: const InputDecoration(labelText: 'Your name'),
              ),
              Gap.lg,
              TextFormField(
                controller: _contact,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _contactValidator,
                decoration: const InputDecoration(
                  labelText: 'Phone or email for the host to reply',
                  helperText: 'Shared only with this host',
                ),
              ),
              Gap.lg,
              TextFormField(
                controller: _message,
                maxLines: 4,
                maxLength: 2000,
                validator: Validators.maxLength(2000),
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  hintText: 'Arrival time, reason for travel, questions about parking…',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        Gap.md,
        BusyButton(label: 'Send enquiry', busy: _busy, onPressed: _submit),
      ],
    );
  }
}

class EnquirySentScreen extends StatelessWidget {
  const EnquirySentScreen({super.key, this.enquiry});

  final Enquiry? enquiry;

  @override
  Widget build(BuildContext context) {
    final e = enquiry;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.mark_email_read_outlined, size: 56, color: context.palette.success),
                  Gap.lg,
                  Text('Enquiry sent', style: context.text.headlineMedium, textAlign: TextAlign.center),
                  Gap.sm,
                  if (e != null)
                    Text(
                      '${e.propertyTitle ?? 'Your stay'}${e.reference != null ? ' (${e.reference})' : ''}\n'
                      '${Dates.shortDay(e.checkIn)} – ${Dates.shortDay(e.checkOut)} · ${e.guestCount} guest${e.guestCount == 1 ? '' : 's'}',
                      textAlign: TextAlign.center,
                      style: context.text.bodyLarge,
                    ),
                  Gap.xl,
                  const InfoBanner(
                    title: 'What happens next',
                    message: 'The host will reply to the phone or email you gave. Nothing is booked yet. '
                        'Agree the stay with the host, and never pay before confirming the place is real.',
                  ),
                  Gap.xl,
                  FilledButton(onPressed: () => context.go(Routes.enquiries), child: const Text('View my enquiries')),
                  Gap.sm,
                  OutlinedButton(onPressed: () => context.go(Routes.explore), child: const Text('Keep exploring')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
