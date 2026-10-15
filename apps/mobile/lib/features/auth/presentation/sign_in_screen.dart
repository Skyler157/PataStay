import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/routing/routes.dart';
import '../../../core/widgets/form_widgets.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signIn(email: _email.text, password: _password.text);
      // The router redirects away from this screen once signed in.
    } on AppFailure catch (failure) {
      if (mounted) context.showFailure(failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    return FormPage(
      showWordmark: true,
      children: [
        Text('Welcome back', style: context.text.headlineMedium),
        Gap.sm,
        Text(
          'Sign in to save places, send enquiries and contact hosts.',
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
                  validator: Validators.required('Enter your password'),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(Routes.forgotPassword),
            child: const Text('Forgot password?'),
          ),
        ),
        Gap.sm,
        BusyButton(label: 'Sign in', busy: _busy, onPressed: _submit),
        Gap.lg,
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('New to PataStay?', style: context.text.bodyMedium),
            TextButton(
              onPressed: () => context.pushReplacement(
                from == null ? Routes.register : '${Routes.register}?from=${Uri.encodeComponent(from)}',
              ),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ],
    );
  }
}
