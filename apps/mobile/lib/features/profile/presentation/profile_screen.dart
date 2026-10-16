import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/routing/routes.dart';
import '../../../core/storage/local_preferences.dart';
import '../../../core/widgets/form_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(currentUserIdProvider) != null;
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Appearance',
            icon: const Icon(Icons.contrast_rounded),
            onPressed: () => showAppearanceSheet(context),
          ),
        ],
      ),
      body: !signedIn
          ? const _SignedOutView()
          : switch (profile) {
              AsyncData(:final value?) => _ProfileView(profile: value),
              AsyncError(:final error) =>
                ErrorView(error: error, onRetry: () => ref.invalidate(currentProfileProvider)),
              _ => const LoadingView(),
            },
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView();

  @override
  Widget build(BuildContext context) {
    return MessageView(
      icon: Icons.person_outline_rounded,
      title: 'Sign in to PataStay',
      message: 'Save places you like, send enquiries to hosts and keep track of their replies.',
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(onPressed: () => context.push(Routes.signIn), child: const Text('Sign in')),
          Gap.md,
          OutlinedButton(onPressed: () => context.push(Routes.register), child: const Text('Create an account')),
        ],
      ),
    );
  }
}

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.profile});

  final Profile profile;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on AppFailure catch (failure) {
      if (context.mounted) context.showFailure(failure);
    }
  }

  Future<void> _requestDeletion(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete your account?'),
        content: Text(
          profile.canHost
              ? 'Your listings will be hidden immediately and your account and data will be permanently deleted '
                  'within 30 days. This cannot be undone.'
              : 'Your account and data will be permanently deleted within 30 days. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.colors.error),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(profileRepositoryProvider).requestAccountDeletion();
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) context.showMessage('Deletion requested. You have been signed out.');
    } on AppFailure catch (failure) {
      if (context.mounted) context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(currentProfileProvider.future),
      child: ListView(
        padding: const EdgeInsets.only(bottom: Space.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: Space.md),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: context.colors.primaryContainer,
                  child: Text(
                    profile.initials,
                    style: context.text.titleLarge?.copyWith(color: context.colors.onPrimaryContainer),
                  ),
                ),
                Gap.lg,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.displayName, style: context.text.titleLarge),
                      if (profile.email != null) Text(profile.email!, style: context.text.bodyMedium),
                      Gap.xs,
                      _RoleTag(role: profile.role),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (profile.isSuspended)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: Space.sm),
              child: InfoBanner(
                tone: BannerTone.danger,
                title: 'Account suspended',
                message: profile.suspendedReason ?? 'Please contact PataStay support.',
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Phone'),
            subtitle: Text(profile.phone == null ? 'Not added' : PhoneNumbers.format(profile.phone!)),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Member since'),
            subtitle: Text(Dates.day(profile.createdAt)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit profile'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.editProfile),
          ),
          ListTile(
            leading: const Icon(Icons.password_rounded),
            title: const Text('Change password'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.updatePassword),
          ),
          ListTile(
            leading: const Icon(Icons.contrast_rounded),
            title: const Text('Appearance'),
            subtitle: Text(_themeLabel(ref.watch(themeModeProvider))),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showAppearanceSheet(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign out'),
            onTap: () => _signOut(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: context.colors.error),
            title: Text('Delete account', style: TextStyle(color: context.colors.error)),
            onTap: () => _requestDeletion(context, ref),
          ),
        ],
      ),
    );
  }
}

class _RoleTag extends StatelessWidget {
  const _RoleTag({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xxs),
      decoration: BoxDecoration(
        color: context.palette.neutralContainer,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(role.label, style: context.text.labelMedium),
    );
  }
}

String _themeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'Same as phone',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

Future<void> showAppearanceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => Consumer(
      builder: (context, ref, _) {
        final current = ref.watch(themeModeProvider);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.sm),
                child: Text('Appearance', style: context.text.titleLarge),
              ),
              RadioGroup<ThemeMode>(
                groupValue: current,
                onChanged: (mode) {
                  if (mode != null) ref.read(themeModeProvider.notifier).set(mode);
                },
                child: Column(children: [
                  for (final (mode, icon) in [
                    (ThemeMode.system, Icons.phone_android_rounded),
                    (ThemeMode.light, Icons.light_mode_outlined),
                    (ThemeMode.dark, Icons.dark_mode_outlined),
                  ])
                    RadioListTile<ThemeMode>(
                      value: mode,
                      title: Text(_themeLabel(mode)),
                      secondary: Icon(icon),
                    ),
                ]),
              ),
              Gap.md,
            ],
          ),
        );
      },
    ),
  );
}
