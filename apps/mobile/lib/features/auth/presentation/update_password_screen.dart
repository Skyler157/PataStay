import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/routing/routes.dart';
import '../../../core/widgets/form_widgets.dart';

/// Reached from a password-reset email link (recovery session) or from Profile.
class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).updatePassword(_password.text);
      if (!mounted) return;
      context.showMessage('Password updated');
      context.go(Routes.profile);
    } on AppFailure catch (failure) {
      if (mounted) context.showFailure(failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPage(
      title: 'Choose a new password',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordField(
                controller: _password,
                label: 'New password',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.password,
              ),
              Gap.lg,
              PasswordField(
                controller: _confirm,
                label: 'Confirm new password',
                autofillHints: const [AutofillHints.newPassword],
                validator: Validators.confirmPassword(() => _password.text),
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        Gap.md,
        Text('At least 8 characters, with letters and numbers.', style: context.text.bodySmall),
        Gap.xl,
        BusyButton(label: 'Save password', busy: _busy, onPressed: _submit),
      ],
    );
  }
}
