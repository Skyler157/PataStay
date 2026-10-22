import 'package:flutter/material.dart';
import 'package:patastay_core/patastay_core.dart';

/// Scrollable, width-constrained layout for auth and settings forms.
class FormPage extends StatelessWidget {
  const FormPage({super.key, required this.children, this.title, this.showWordmark = false});

  final String? title;
  final bool showWordmark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: title == null ? null : Text(title!)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.xxl),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showWordmark) ...[
                    const Align(alignment: Alignment.centerLeft, child: PataWordmark(size: 24)),
                    Gap.xl,
                  ],
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String> autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _obscured ? 'Show password' : 'Hide password',
          icon: Icon(_obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
    );
  }
}

/// Filled button that shows a spinner and blocks taps while [busy].
class BusyButton extends StatelessWidget {
  const BusyButton({super.key, required this.label, required this.onPressed, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: context.colors.onPrimary),
            )
          : Text(label),
    );
  }
}

extension FeedbackContext on BuildContext {
  void showMessage(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void showFailure(Object error) => showMessage(mapToFailure(error).message);
}

/// What a PataStay account offers guests and hosts (sign-in and register).
class AccountBenefits extends StatelessWidget {
  const AccountBenefits({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: context.palette.neutralContainer,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Benefit(
            icon: Icons.travel_explore_rounded,
            title: 'Looking for a place to stay?',
            body: 'Save places you like, send enquiries, chat with hosts on WhatsApp and keep track of their replies.',
          ),
          SizedBox(height: Space.lg),
          _Benefit(
            icon: Icons.home_work_outlined,
            title: 'Have a place to rent out?',
            body: 'List it for free, receive enquiries from guests, see how many people view and save it, '
                'and earn a Verified badge that guests trust.',
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: context.colors.primaryContainer, shape: BoxShape.circle),
          child: Icon(icon, size: 22, color: context.colors.onPrimaryContainer),
        ),
        const SizedBox(width: Space.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleSmall),
              const SizedBox(height: Space.xxs),
              Text(body, style: context.text.bodyMedium?.copyWith(color: context.palette.mutedText)),
            ],
          ),
        ),
      ],
    );
  }
}
