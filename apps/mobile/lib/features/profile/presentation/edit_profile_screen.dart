import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/widgets/form_widgets.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(currentProfileProvider)) {
      AsyncData(:final value?) => _EditProfileForm(profile: value),
      AsyncError(:final error) => Scaffold(
          appBar: AppBar(),
          body: ErrorView(error: error, onRetry: () => ref.invalidate(currentProfileProvider)),
        ),
      _ => Scaffold(appBar: AppBar(), body: const LoadingView()),
    };
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _phone = TextEditingController(
    text: widget.profile.phone == null ? '' : PhoneNumbers.format(widget.profile.phone!),
  );
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            widget.profile.id,
            fullName: _name.text,
            phone: PhoneNumbers.normalize(_phone.text),
          );
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      context.showMessage('Profile updated');
      context.pop();
    } on AppFailure catch (failure) {
      if (mounted) context.showFailure(failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPage(
      title: 'Edit profile',
      children: [
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
                decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.badge_outlined)),
              ),
              Gap.lg,
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: Validators.phone(),
                onFieldSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  hintText: '0712 345 678',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),
        ),
        Gap.md,
        Text(
          'Your phone number is private. It is never shown on listings.',
          style: context.text.bodySmall,
        ),
        Gap.xl,
        BusyButton(label: 'Save changes', busy: _busy, onPressed: _save),
      ],
    );
  }
}
