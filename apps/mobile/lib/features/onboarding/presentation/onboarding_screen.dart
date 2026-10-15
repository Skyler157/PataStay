import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/storage/local_preferences.dart';

class _Page {
  const _Page(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

const _pages = [
  _Page(
    Icons.home_work_outlined,
    'Find a stay that fits your budget',
    'Studios, one-bedrooms, furnished apartments and guest houses across Nairobi, with nightly prices in KES up front.',
  ),
  _Page(
    Icons.fact_check_outlined,
    'Know exactly what you are getting',
    'See every fee and refundable deposit, when availability was last confirmed, and a Verified badge only after our team has checked the property.',
  ),
  _Page(
    Icons.forum_outlined,
    'Talk to the host directly',
    'Send an enquiry, or reach the host on WhatsApp or by phone, and agree your stay with them. Never pay before you are sure the place is real.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() => ref.read(onboardingCompleteProvider.notifier).complete();

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: Column(
            children: [
              SizedBox(
                height: 64,
                child: Row(
                  children: [
                    const PataWordmark(size: 22),
                    const Spacer(),
                    if (!_isLast) TextButton(onPressed: _finish, child: const Text('Skip')),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _OnboardingPage(page: _pages[i]),
                ),
              ),
              Semantics(
                label: 'Page ${_index + 1} of ${_pages.length}',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _pages.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: Space.xs),
                        width: i == _index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index ? context.colors.primary : context.colors.outlineVariant,
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                      ),
                  ],
                ),
              ),
              Gap.xl,
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _next, child: Text(_isLast ? 'Start exploring' : 'Next')),
              ),
              Gap.lg,
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(Radii.xl),
                ),
                child: Icon(page.icon, size: 52, color: context.colors.onPrimaryContainer),
              ),
              Gap.xxl,
              Text(page.title, style: context.text.headlineMedium),
              Gap.md,
              Text(page.body, style: context.text.bodyLarge?.copyWith(color: context.palette.mutedText)),
            ],
          ),
        ),
      ),
    );
  }
}
