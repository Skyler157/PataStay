import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../../core/routing/routes.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../application/property_providers.dart';

/// Listing photo. Seed listings have no real files, so they show a clearly
/// labelled placeholder rather than a stock image passed off as real.
class PropertyPhoto extends ConsumerStatefulWidget {
  const PropertyPhoto({super.key, this.image, this.thumbnail = false, this.label});

  final PropertyImage? image;

  /// Lists use small images to save mobile data.
  final bool thumbnail;
  final String? label;

  @override
  ConsumerState<PropertyPhoto> createState() => _PropertyPhotoState();
}

class _PropertyPhotoState extends ConsumerState<PropertyPhoto> {
  /// Failed loads (a dropped connection, the server restarting) are retried
  /// once automatically, then on tap, instead of staying broken.
  int _attempt = 0;
  bool _retryScheduled = false;

  Future<void> _retry(String url) async {
    await CachedNetworkImage.evictFromCache(url);
    if (mounted) {
      setState(() {
        _attempt++;
        _retryScheduled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.image;
    if (img == null || img.isPlaceholder) {
      final labelled = ref.watch(appConfigProvider).showSampleLabels;
      return _Placeholder(label: img == null || !labelled ? 'Photo coming soon' : 'Sample photo');
    }
    final url = ref.watch(propertyRepositoryProvider).imageUrl(img, thumbnail: widget.thumbnail);
    final width = MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context);
    return CachedNetworkImage(
      key: ValueKey('$url#$_attempt'),
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheWidth: widget.thumbnail ? (width * 0.9).round().clamp(320, 720) : null,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (_, _) => ColoredBox(color: context.palette.neutralContainer),
      errorWidget: (_, _, _) {
        if (_attempt == 0 && !_retryScheduled) {
          _retryScheduled = true;
          Future<void>.delayed(const Duration(seconds: 2), () => _retry(url));
          return ColoredBox(color: context.palette.neutralContainer);
        }
        return Semantics(
          button: true,
          label: 'Photo did not load. Tap to try again',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _retry(url),
            child: const _Placeholder(label: 'Photo did not load · Tap to retry'),
          ),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: context.palette.neutralContainer),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Small thumbnails (lists, enquiry tiles) only have room for the icon.
          final roomy = constraints.maxHeight >= 110 && constraints.maxWidth >= 140;
          return Center(
            child: Semantics(
              label: label,
              child: roomy
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_outlined, color: context.palette.mutedText, size: 32),
                        const SizedBox(height: Space.xs),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.labelMedium?.copyWith(color: context.palette.mutedText),
                          ),
                        ),
                      ],
                    )
                  : Icon(Icons.photo_outlined, color: context.palette.mutedText, size: 24),
            ),
          );
        },
      ),
    );
  }
}

enum BadgeTone { verified, featured, sample, warning, neutral }

class PataBadge extends StatelessWidget {
  const PataBadge({super.key, required this.label, this.tone = BadgeTone.neutral, this.icon});

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color fg, Color bg) = switch (tone) {
      BadgeTone.verified => (p.verified, p.verifiedContainer),
      BadgeTone.featured => (PataColors.ink, PataColors.saffron),
      BadgeTone.sample => (context.colors.onSecondaryContainer, context.colors.secondaryContainer),
      BadgeTone.warning => (p.warning, p.warningContainer),
      BadgeTone.neutral => (context.colors.onSurface, p.neutralContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(label, style: context.text.labelSmall?.copyWith(color: fg), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/// Shown only when an administrator has actually verified the listing.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, required this.verifiedAt, this.long = false});

  final DateTime verifiedAt;
  final bool long;

  @override
  Widget build(BuildContext context) => PataBadge(
        label: long ? 'Verified by PataStay · ${Dates.day(verifiedAt)}' : 'Verified',
        tone: BadgeTone.verified,
        icon: Icons.verified_rounded,
      );
}

class SampleBadge extends StatelessWidget {
  const SampleBadge({super.key});

  @override
  Widget build(BuildContext context) =>
      const PataBadge(label: 'Sample listing', tone: BadgeTone.sample, icon: Icons.science_outlined);
}

/// "Availability confirmed 2 days ago", or a warning when it is stale.
class FreshnessLabel extends StatelessWidget {
  const FreshnessLabel({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final confirmed = property.availabilityConfirmedAt;
    if (confirmed == null) {
      return Text('Host has not confirmed availability',
          style: context.text.labelMedium?.copyWith(color: context.palette.warning));
    }
    final stale = property.isStale();
    return Text(
      'Availability confirmed ${Dates.relative(confirmed)}',
      style: context.text.labelMedium?.copyWith(color: stale ? context.palette.warning : context.palette.success),
    );
  }
}

/// Nightly rate, plus the stay total when dates are known.
class PriceBlock extends StatelessWidget {
  const PriceBlock({super.key, required this.property, this.quote});

  final Property property;
  final StayQuote? quote;

  @override
  Widget build(BuildContext context) {
    final q = quote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(
            text: Money.kes(property.nightlyRate),
            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: context.palette.price),
          ),
          TextSpan(text: ' / night', style: context.text.bodySmall),
        ])),
        if (q != null)
          Text(
            '${Money.kes(q.total)} total · ${q.nights} night${q.nights == 1 ? '' : 's'}'
            '${q.cleaningFee > 0 ? ', incl. cleaning' : ''}',
            style: context.text.labelMedium?.copyWith(color: context.colors.onSurface),
          ),
      ],
    );
  }
}

/// Heart button. Signed-out users are sent to sign in first.
class FavouriteButton extends ConsumerWidget {
  const FavouriteButton({super.key, required this.propertyId, this.onPhoto = true});

  final String propertyId;
  final bool onPhoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(favouritesProvider).value?.contains(propertyId) ?? false;
    final button = IconButton(
      tooltip: saved ? 'Remove from saved' : 'Save',
      onPressed: () async {
        try {
          final ok = await ref.read(favouritesProvider.notifier).toggle(propertyId);
          if (!ok && context.mounted) {
            context.showMessage('Sign in to save places');
            context.push(Routes.signInReturningTo(GoRouterState.of(context).uri.toString()));
          }
        } on AppFailure catch (failure) {
          if (context.mounted) context.showFailure(failure);
        }
      },
      icon: Icon(
        saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        // On photos the button sits on a fixed white circle in both themes, so
        // use fixed colours there; elsewhere follow the theme.
        color: onPhoto
            ? (saved ? PataColors.clay : PataColors.ink)
            : (saved ? (Theme.of(context).brightness == Brightness.dark ? PataColors.clayLight : PataColors.clay) : context.colors.onSurface),
      ),
    );
    if (!onPhoto) return button;
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xEEFFFFFF), shape: BoxShape.circle),
      child: button,
    );
  }
}

/// Listing card used in search results, home rows and Saved.
/// Whether to label a development sample listing (off in presentation mode).
bool showSampleLabel(WidgetRef ref, Property property) =>
    property.isSeed && ref.watch(appConfigProvider).showSampleLabels;

class PropertyCard extends ConsumerWidget {
  const PropertyCard({super.key, required this.property, this.quote, this.compact = false});

  final Property property;
  final StayQuote? quote;

  /// Narrow cards for horizontal home rows.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = property;
    final sample = showSampleLabel(ref, p);
    final subtitle = [p.neighbourhood?.name, p.propertyType?.label].whereType<String>().join(' · ');
    return Semantics(
      button: true,
      label: '${p.title}, ${p.neighbourhood?.name ?? ''}, ${Money.kes(p.nightlyRate)} per night'
          '${p.isVerified ? ', verified' : ''}${sample ? ', sample listing' : ''}',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(Routes.property(p.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PropertyPhoto(image: p.coverImage, thumbnail: true),
                    Positioned(
                      top: Space.sm,
                      left: Space.sm,
                      right: 56,
                      child: Wrap(
                        spacing: Space.xs,
                        runSpacing: Space.xs,
                        children: [
                          if (p.isFeatured) const PataBadge(label: 'Featured', tone: BadgeTone.featured, icon: Icons.star_rounded),
                          if (p.verifiedAt != null) VerifiedBadge(verifiedAt: p.verifiedAt!),
                          if (sample) const SampleBadge(),
                        ],
                      ),
                    ),
                    Positioned(top: Space.xs, right: Space.xs, child: FavouriteButton(propertyId: p.id)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.md, Space.md, Space.md, Space.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: context.text.titleSmall, maxLines: compact ? 1 : 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(subtitle, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (!compact) Text(p.roomsSummary, style: context.text.bodySmall),
                    if (p.distanceLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(children: [
                          Icon(Icons.near_me_outlined, size: 14, color: context.colors.primary),
                          const SizedBox(width: 4),
                          Text(p.distanceLabel!, style: context.text.labelMedium?.copyWith(color: context.colors.primary)),
                        ]),
                      ),
                    const SizedBox(height: Space.sm),
                    PriceBlock(property: p, quote: quote),
                    if (!compact) ...[
                      const SizedBox(height: Space.xs),
                      FreshnessLabel(property: p),
                      if (p.keyAmenities.isNotEmpty) ...[
                        const SizedBox(height: Space.xs),
                        Text(
                          p.keyAmenities.take(3).map((a) => a.name).join(' · '),
                          style: context.text.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

