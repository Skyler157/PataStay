import 'package:flutter/material.dart';

import '../errors/app_failure.dart';
import '../theme/tokens.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: message ?? 'Loading',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(dimension: 32, child: CircularProgressIndicator(strokeWidth: 3)),
            if (message != null) ...[
              const SizedBox(height: Space.lg),
              Text(message!, style: context.text.bodyMedium, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

/// Centered message block used for empty and error states.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.iconColor,
    this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconBackground ?? context.palette.neutralContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: iconColor ?? context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: Space.lg),
              Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: Space.sm),
                Text(
                  message!,
                  style: context.text.bodyMedium?.copyWith(color: context.palette.mutedText),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[const SizedBox(height: Space.xl), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title, this.message, this.icon = Icons.inbox_outlined, this.action});

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) =>
      MessageView(icon: icon, title: title, message: message, action: action);
}

/// Error state with a retry action. Shows a friendly message for the failure.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry, this.title});

  final Object error;
  final VoidCallback? onRetry;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final failure = mapToFailure(error);
    final isOffline = failure is NetworkFailure;
    return MessageView(
      icon: isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      iconColor: context.palette.danger,
      iconBackground: context.palette.dangerContainer,
      title: title ?? (isOffline ? 'You appear to be offline' : 'Something went wrong'),
      message: failure.message,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
    );
  }
}

enum BannerTone { info, success, warning, danger }

/// Inline, non-dismissable notice (e.g. "An enquiry is not a reservation").
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.message, this.title, this.tone = BannerTone.info, this.icon});

  final String? title;
  final String message;
  final BannerTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color fg, Color bg, IconData defaultIcon) = switch (tone) {
      BannerTone.info => (context.colors.onSurface, p.neutralContainer, Icons.info_outline_rounded),
      BannerTone.success => (p.success, p.successContainer, Icons.check_circle_outline_rounded),
      BannerTone.warning => (p.warning, p.warningContainer, Icons.warning_amber_rounded),
      BannerTone.danger => (p.danger, p.dangerContainer, Icons.error_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.all(Space.md + 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.md)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, color: fg, size: 22),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: context.text.titleSmall?.copyWith(color: fg)),
                  const SizedBox(height: Space.xxs),
                ],
                Text(message, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
