import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/widgets/form_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AppFailure catch (failure) {
      if (mounted) context.showFailure(failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPage(
      title: 'Reset password',
      children: [
        if (_sent) ...[
          // Same message whether or not the account exists, to avoid revealing who is registered.
          InfoBanner(
            tone: BannerTone.success,
            title: 'Check your email',
            message: 'If an account exists for ${_email.text.trim()}, we have sent a link to reset the password. Open it on this phone.',
          ),
          Gap.xl,
          OutlinedButton(onPressed: () => context.pop(), child: const Text('Back to sign in')),
        ] else ...[
          Text(
            'Enter the email you signed up with and we will send you a link to choose a new password.',
            style: context.text.bodyLarge,
          ),
          Gap.xl,
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              validator: Validators.email,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
            ),
          ),
          Gap.xl,
          BusyButton(label: 'Send reset link', busy: _busy, onPressed: _submit),
        ],
      ],
    );
  }
}
