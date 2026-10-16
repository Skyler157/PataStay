import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/routing/routes.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../properties/application/property_providers.dart';
import '../../properties/presentation/widgets/property_widgets.dart';

class MyEnquiriesScreen extends ConsumerWidget {
  const MyEnquiriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(currentUserIdProvider) != null;
    final enquiries = ref.watch(myEnquiriesProvider);
    // Opening the list clears the "new reply" badge.
    if (enquiries.hasValue && ref.watch(unreadRepliesProvider) > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(enquiriesSeenProvider.notifier).markSeen());
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Enquiries')),
      body: !signedIn
          ? MessageView(
              icon: Icons.mail_outline_rounded,
              title: 'Track your enquiries',
              message: 'Sign in to send enquiries to hosts and see their replies here.',
              action: FilledButton(
                onPressed: () => context.push(Routes.signInReturningTo(Routes.enquiries)),
                child: const Text('Sign in'),
              ),
            )
          : switch (enquiries) {
              AsyncData(:final value) when value.isEmpty => EmptyView(
                  icon: Icons.mail_outline_rounded,
                  title: 'No enquiries yet',
                  message: 'When you ask a host about a stay, it shows up here with their reply.',
                  action: OutlinedButton(onPressed: () => context.go(Routes.explore), child: const Text('Find a stay')),
                ),
              AsyncData(:final value) => RefreshIndicator(
                  onRefresh: () => ref.refresh(myEnquiriesProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(Space.gutter),
                    itemCount: value.length,
                    separatorBuilder: (_, _) => Gap.md,
                    itemBuilder: (_, i) => _EnquiryTile(enquiry: value[i]),
                  ),
                ),
              AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(myEnquiriesProvider)),
              _ => const LoadingView(),
            },
    );
  }
}

class _EnquiryTile extends ConsumerWidget {
  const _EnquiryTile({required this.enquiry});

  final Enquiry enquiry;

  Future<void> _act(BuildContext context, WidgetRef ref, {required bool cancel}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cancel ? 'Cancel this enquiry?' : 'Did you agree a stay with the host?'),
        content: Text(cancel
            ? 'The host will see that you are no longer interested.'
            : 'This tells PataStay that you and the host agreed this stay. It helps us show which hosts are reliable.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(cancel ? 'Cancel enquiry' : 'Yes, we agreed')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final repo = ref.read(enquiryRepositoryProvider);
      cancel ? await repo.cancel(enquiry.id) : await repo.reportBooked(enquiry.id);
      ref.invalidate(myEnquiriesProvider);
    } on AppFailure catch (failure) {
      if (context.mounted) context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = enquiry;
    final (BadgeTone tone, IconData icon) = switch (e.status) {
      EnquiryStatus.available || EnquiryStatus.booked => (BadgeTone.verified, Icons.check_circle_outline_rounded),
      EnquiryStatus.unavailable || EnquiryStatus.cancelled || EnquiryStatus.closed => (BadgeTone.neutral, Icons.block_rounded),
      EnquiryStatus.newEnquiry || EnquiryStatus.seen => (BadgeTone.warning, Icons.schedule_rounded),
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.enquiry(e.id)),
        child: Padding(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: SizedBox(width: 72, height: 72, child: PropertyPhoto(image: e.propertyCover, thumbnail: true)),
                  ),
                  Gap.md,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.propertyTitle ?? 'Listing', style: context.text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text(
                          '${Dates.shortDay(e.checkIn)} – ${Dates.shortDay(e.checkOut)} · ${e.guestCount} guest${e.guestCount == 1 ? '' : 's'}',
                          style: context.text.bodySmall,
                        ),
                        Gap.xs,
                        PataBadge(label: e.status.label, tone: tone, icon: icon),
                      ],
                    ),
                  ),
                ],
              ),
              if (e.ownerResponse != null && e.ownerResponse!.trim().isNotEmpty) ...[
                Gap.md,
                Text('Host reply', style: context.text.labelMedium),
                Text(e.ownerResponse!, style: context.text.bodyMedium),
              ],
              Gap.sm,
              Text('Sent ${Dates.relative(e.createdAt)}${e.reference != null ? ' · ${e.reference}' : ''}', style: context.text.bodySmall),
              if (e.canCancel || e.canReportBooked)
                Wrap(spacing: Space.sm, children: [
                  if (e.status == EnquiryStatus.available && e.canReportBooked)
                    TextButton(onPressed: () => _act(context, ref, cancel: false), child: const Text('We agreed a stay')),
                  if (e.canCancel)
                    TextButton(onPressed: () => _act(context, ref, cancel: true), child: const Text('Cancel enquiry')),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
