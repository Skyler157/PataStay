import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/routing/routes.dart';
import '../../../core/widgets/form_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _wantsToHost = false;
  bool _busy = false;
  String? _confirmationSentTo;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final outcome = await ref.read(authRepositoryProvider).signUp(
            email: _email.text,
            password: _password.text,
            fullName: _name.text,
            wantsToHost: _wantsToHost,
          );
      if (!mounted) return;
      if (outcome == SignUpOutcome.confirmationEmailSent) {
        setState(() => _confirmationSentTo = _email.text.trim());
      } else {
        context.go(Routes.afterSignIn(GoRouterState.of(context).uri.queryParameters['from']));
      }
    } on AppFailure catch (failure) {
      if (mounted) context.showFailure(failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_confirmationSentTo != null) {
      return FormPage(
        showWordmark: true,
        children: [
          Text('Check your email', style: context.text.headlineMedium),
          Gap.md,
          InfoBanner(
            tone: BannerTone.success,
            message: 'We sent a confirmation link to $_confirmationSentTo. Open it on this phone to finish creating your account.',
          ),
          Gap.xl,
          OutlinedButton(onPressed: () => context.go(Routes.signIn), child: const Text('Back to sign in')),
        ],
      );
    }

    return FormPage(
      showWordmark: true,
      children: [
        Text('Create your account', style: context.text.headlineMedium),
        Gap.sm,
        Text(
          'Browsing is free and open to everyone. An account lets you save places and contact hosts.',
          style: context.text.bodyLarge?.copyWith(color: context.palette.mutedText),
        ),
        Gap.xl,
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.fullName,
                  decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.badge_outlined)),
                ),
                Gap.lg,
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  validator: Validators.email,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                ),
                Gap.lg,
                PasswordField(
                  controller: _password,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                ),
                Gap.lg,
                PasswordField(
                  controller: _confirm,
                  label: 'Confirm password',
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.confirmPassword(() => _password.text),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        Gap.md,
        Text('At least 8 characters, with letters and numbers.', style: context.text.bodySmall),
        Gap.lg,
        Card(
          child: CheckboxListTile(
            value: _wantsToHost,
            onChanged: (value) => setState(() => _wantsToHost = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('I also want to list a property'),
            subtitle: const Text('Listing is free. Every listing is reviewed before it goes live.'),
          ),
        ),
        Gap.xl,
        BusyButton(label: 'Create account', busy: _busy, onPressed: _submit),
        Gap.lg,
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Already have an account?', style: context.text.bodyMedium),
            TextButton(onPressed: () => context.pushReplacement(Routes.signIn), child: const Text('Sign in')),
          ],
        ),
      ],
    );
  }
}
