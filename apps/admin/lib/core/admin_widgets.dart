import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patastay_core/patastay_core.dart';

extension AdminFeedback on BuildContext {
  void showMessage(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, width: 480));
  }

  void showFailure(Object error) => showMessage(mapToFailure(error).message);
}

/// Standard page body: title row with actions, then scrolling content
/// limited to a readable width.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.leading,
    this.maxWidth = 1200,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? leading;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.xl, Space.xxxl),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: Space.lg,
                  runSpacing: Space.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      if (leading != null) ...[leading!, Gap.sm],
                      Flexible(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(title, style: context.text.headlineSmall),
                          if (subtitle != null)
                            Text(subtitle!, style: context.text.bodyMedium?.copyWith(color: context.palette.mutedText)),
                        ]),
                      ),
                    ]),
                    if (actions.isNotEmpty) Wrap(spacing: Space.sm, runSpacing: Space.sm, children: actions),
                  ],
                ),
                Gap.xl,
                ...children,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A titled card used for the panels on detail pages.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.title, required this.child, this.trailing});

  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: Space.lg),
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: Text(title, style: context.text.titleMedium)),
              ?trailing,
            ]),
            Gap.md,
            child,
          ],
        ),
      ),
    );
  }
}

/// Label and value on one line, wrapping on narrow screens.
class Fact extends StatelessWidget {
  const Fact(this.label, this.value, {super.key});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 150,
          child: Text(label, style: context.text.bodyMedium?.copyWith(color: context.palette.mutedText)),
        ),
        Expanded(child: SelectableText(value == null || value!.trim().isEmpty ? '–' : value!)),
      ]),
    );
  }
}

/// Coloured listing status label.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final PropertyStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color fg, Color bg) = switch (status) {
      PropertyStatus.published => (p.success, p.successContainer),
      PropertyStatus.pendingReview => (p.warning, p.warningContainer),
      PropertyStatus.rejected || PropertyStatus.suspended => (p.danger, p.dangerContainer),
      _ => (context.colors.onSurface, p.neutralContainer),
    };
    return Tag(label: status.label, foreground: fg, background: bg);
  }
}

class Tag extends StatelessWidget {
  const Tag({super.key, required this.label, required this.foreground, required this.background, this.icon});

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(Radii.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 14, color: foreground), const SizedBox(width: 4)],
        Flexible(
          child: Text(label,
              style: context.text.labelSmall?.copyWith(color: foreground), overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

/// Listing photo from public storage, with a quiet fallback.
class ListingPhoto extends ConsumerWidget {
  const ListingPhoto({super.key, required this.image, this.thumbnail = true, this.fit = BoxFit.cover});

  final PropertyImage? image;
  final bool thumbnail;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fallback = ColoredBox(
      color: context.palette.neutralContainer,
      child: Center(child: Icon(Icons.image_outlined, color: context.palette.mutedText)),
    );
    final img = image;
    if (img == null) return fallback;
    return Image.network(
      ref.watch(propertyRepositoryProvider).imageUrl(img, thumbnail: thumbnail),
      fit: fit,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

/// Asks for a written reason. Returns null when cancelled.
Future<String?> askForReason(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  int minLength = 10,
  String? initial,
  bool optional = false,
  bool destructive = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ReasonDialog(
      title: title,
      message: message,
      action: action,
      minLength: optional ? 0 : minLength,
      initial: initial,
      destructive: destructive,
    ),
  );
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.message,
    required this.action,
    required this.minLength,
    required this.destructive,
    this.initial,
  });

  final String title;
  final String message;
  final String action;
  final int minLength;
  final bool destructive;
  final String? initial;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.message),
            Gap.lg,
            TextFormField(
              controller: _controller,
              autofocus: true,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(labelText: widget.minLength == 0 ? 'Note (optional)' : 'Reason'),
              validator: (v) => (v ?? '').trim().length < widget.minLength
                  ? 'Please write at least ${widget.minLength} characters'
                  : null,
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: widget.destructive
              ? FilledButton.styleFrom(
                  backgroundColor: context.palette.danger, foregroundColor: context.colors.onError)
              : null,
          onPressed: _submit,
          child: Text(widget.action),
        ),
      ],
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(width: 480, child: Text(message)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: context.palette.danger, foregroundColor: context.colors.onError)
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Runs [action] while showing nothing extra; reports failures in a snack bar
/// and returns whether it succeeded.
Future<bool> runAction(BuildContext context, Future<void> Function() action, {String? success}) async {
  try {
    await action();
    if (context.mounted && success != null) context.showMessage(success);
    return true;
  } catch (e) {
    if (context.mounted) context.showFailure(e);
    return false;
  }
}

/// Search box used on list pages. Searches after a short pause in typing.
class SearchBox extends StatefulWidget {
  const SearchBox({super.key, required this.hint, required this.onChanged, this.initial = ''});

  final String hint;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  late final _controller = TextEditingController(text: widget.initial);
  Future<void>? _pending;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    final current = _pending = Future.delayed(const Duration(milliseconds: 350));
    current.then((_) {
      if (mounted && identical(current, _pending)) widget.onChanged(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: TextField(
        controller: _controller,
        onChanged: _changed,
        onSubmitted: (v) => widget.onChanged(v.trim()),
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search_rounded),
          isDense: true,
        ),
      ),
    );
  }
}

String formatDateTime(DateTime d) {
  final l = d.toLocal();
  return '${Dates.day(l)}, ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
