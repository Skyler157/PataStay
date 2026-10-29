import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patastay_admin/app/admin_app.dart';
import 'package:patastay_admin/core/csv.dart';
import 'package:patastay_admin/data/admin_models.dart';
import 'package:patastay_admin/data/admin_repository.dart';
import 'package:patastay_admin/features/dashboard/platform_stats.dart';
import 'package:patastay_admin/features/follow_ups/follow_ups_screen.dart';
import 'package:patastay_core/patastay_core.dart';

final _admin = Profile(id: 'a1', fullName: 'Ada Admin', email: 'ada@test.local', role: UserRole.admin, createdAt: DateTime(2026));

Map<String, dynamic> _ownerRow({String id = 'h1', String? deletionRequestedAt, String role = 'owner'}) => {
      'id': id,
      'full_name': 'Hassan Host',
      'email': 'hassan@test.local',
      'phone': '+254711000111',
      'role': role,
      'account_status': 'active',
      'suspended_reason': null,
      'deletion_requested_at': deletionRequestedAt,
      'created_at': '2026-09-01T08:00:00Z',
      'updated_at': null,
    };

AdminListing _listing({String status = 'pending_review'}) => AdminListing.fromRow({
      'id': 'l1',
      'listing_number': 1042,
      'title': 'Quiet studio off Ngong Road',
      'description': 'Clean, quiet and close to shops and matatus. Fast Wi-Fi and backup power.',
      'property_type': 'studio',
      'nightly_rate': 3500,
      'bedrooms': 0,
      'bathrooms': 1,
      'maximum_guests': 2,
      'minimum_nights': 1,
      'is_featured': false,
      'is_seed': false,
      'created_at': '2026-10-20T08:00:00Z',
      'submitted_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      'status': status,
      'neighbourhoods': {'id': 'n1', 'name': 'Kilimani', 'slug': 'kilimani'},
      'property_images': const [],
      'property_amenities': const [],
      'property_contacts': {'phone': '+254711000111', 'whatsapp_phone': '+254711000111'},
      'property_locations': null,
      'owner': _ownerRow(),
      'enquiries': [
        {'count': 2},
      ],
      'property_reports': [
        {'count': 0},
      ],
    });

class FakeAdminRepository extends Fake implements AdminRepository {
  FakeAdminRepository({this.listing, this.users = const [], this.followUps = const FollowUps(), this.areas = const []});

  AdminListing? listing;
  List<AdminUser> users;
  FollowUps followUps;
  List<AdminArea> areas;
  final calls = <String>[];
  final saved = <Map<String, dynamic>>[];

  @override
  Future<FollowUps> fetchFollowUps() async => followUps;
  @override
  Future<List<AdminArea>> fetchAreas() async => areas;
  @override
  Future<List<AdminAmenity>> fetchAmenities() async => [];
  @override
  Future<void> saveArea(String? id, Map<String, dynamic> fields) async {
    calls.add('saveArea ${id ?? 'new'}');
    saved.add(fields);
  }

  @override
  Future<List<AdminListing>> fetchListings({PropertyStatus? status, String query = ''}) async =>
      [?listing].where((l) => status == null || l.status == status).toList();
  @override
  Future<AdminListing?> fetchListing(String id) async => listing;
  @override
  Future<List<AdminListing>> fetchListingsOf(String ownerId) async => [];
  @override
  Future<List<StatusChange>> fetchHistory(String propertyId) async => [];
  @override
  Future<List<VerificationCheck>> fetchChecks(String propertyId) async => [];
  @override
  Future<List<AdminReport>> fetchReports({bool activeOnly = true, String? propertyId}) async => [];
  @override
  Future<List<AdminUser>> fetchUsers({UserFilter filter = UserFilter.all, String query = ''}) async => users;
  @override
  Future<AdminUser?> fetchUser(String id) async => users.where((u) => u.profile.id == id).firstOrNull;
  @override
  Future<List<DeletionRecord>> fetchDeletionLog() async => [];

  @override
  Future<void> approve(String id, {String? note}) async {
    calls.add('approve $id');
    listing = _listing(status: 'published');
  }

  @override
  Future<void> reject(String id, String reason) async => calls.add('reject $id: $reason');

  @override
  Future<int> processDeletion(String userId) async {
    calls.add('delete $userId');
    users = [];
    return 0;
  }
}

Future<void> _pumpAt(WidgetTester tester, FakeAdminRepository repo, String location) async {
  final container = ProviderContainer(overrides: [
    appConfigProvider.overrideWithValue(const AppConfig(supabaseUrl: 'http://localhost', supabasePublishableKey: 'test')),
    currentUserIdProvider.overrideWithValue(_admin.id),
    currentProfileProvider.overrideWith((ref) async => _admin),
    adminRepositoryProvider.overrideWithValue(repo),
    platformStatsProvider.overrideWith((ref, days) async => const PlatformStats({'listings_pending': 1})),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const AdminApp()));
  container.read(adminRouterProvider).go(location);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1600, 1200);
    binding.platformDispatcher.views.first.devicePixelRatio = 1;
  });

  testWidgets('review queue lists pending listings and an admin can approve one', (tester) async {
    final repo = FakeAdminRepository(listing: _listing());
    await _pumpAt(tester, repo, '/review');
    expect(find.text('Review queue'), findsWidgets);
    expect(find.textContaining('waiting 3 days'), findsOneWidget);

    await tester.tap(find.text('Quiet studio off Ngong Road'));
    await tester.pumpAndSettle();
    expect(find.text('Before approving, check that:'), findsOneWidget);
    expect(find.text('+254711000111'), findsWidgets); // private contact is visible to admins

    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();
    expect(find.textContaining('You have not ticked 5 checklist items'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, 'Approve')));
    await tester.pumpAndSettle();

    expect(repo.calls, ['approve l1']);
    expect(find.text('Approved. The listing is live.'), findsOneWidget);
    expect(find.text('Feature this listing'), findsOneWidget); // only for published listings
  });

  testWidgets('asking for changes needs a clear reason', (tester) async {
    final repo = FakeAdminRepository(listing: _listing());
    await _pumpAt(tester, repo, '/listings/l1');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Ask for changes'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Fix it');
    await tester.tap(find.text('Send to host'));
    await tester.pumpAndSettle();
    expect(find.text('Please write at least 10 characters'), findsOneWidget);
    expect(repo.calls, isEmpty);

    await tester.enterText(find.byType(TextFormField), 'Please add a photo of the bathroom.');
    await tester.tap(find.text('Send to host'));
    await tester.pumpAndSettle();
    expect(repo.calls, ['reject l1: Please add a photo of the bathroom.']);
  });

  testWidgets('Verified badge stays disabled until the required checks pass', (tester) async {
    await _pumpAt(tester, FakeAdminRepository(listing: _listing(status: 'published')), '/listings/l1');
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Give Verified badge'));
    expect(button.onPressed, isNull);
  });

  testWidgets('an admin processes a deletion request', (tester) async {
    final requested = DateTime.now().subtract(const Duration(days: 26)).toIso8601String();
    final repo = FakeAdminRepository(users: [AdminUser.fromRow(_ownerRow(deletionRequestedAt: requested))]);
    await _pumpAt(tester, repo, '/users?filter=deletionRequested');
    expect(find.text('Delete within 4 days'), findsOneWidget);

    await tester.tap(find.text('Hassan Host'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account and data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();

    expect(repo.calls, ['delete h1']);
    expect(find.text('Account deleted.'), findsOneWidget);
    expect(find.text('No deletion requests'), findsOneWidget);
  });

  testWidgets('administrator accounts cannot be deleted until the role is removed', (tester) async {
    final requested = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
    final repo = FakeAdminRepository(users: [AdminUser.fromRow(_ownerRow(deletionRequestedAt: requested, role: 'admin'))]);
    await _pumpAt(tester, repo, '/users/h1');
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Delete account and data'));
    expect(button.onPressed, isNull);
  });

  testWidgets('narrow screens use a drawer and pages still fit', (tester) async {
    tester.view.physicalSize = const Size(400, 860);
    addTearDown(tester.view.resetPhysicalSize);
    await _pumpAt(tester, FakeAdminRepository(listing: _listing()), '/listings/l1');
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Review queue'), findsOneWidget);
  });

  testWidgets('warning signs appear in the queue and on the review page', (tester) async {
    final risky = _listing().withRisks(const [
      RiskSignal(code: 'low_price', high: false, message: 'KES 1,500 a night is less than half the usual KES 4,200.'),
      RiskSignal(code: 'payment_words', high: true, message: 'The text mentions paying (M-Pesa).'),
    ]);
    await _pumpAt(tester, FakeAdminRepository(listing: risky), '/review');
    expect(find.text('2 warning signs'), findsOneWidget);

    await tester.tap(find.text('Quiet studio off Ngong Road'));
    await tester.pumpAndSettle();
    expect(find.text('The text mentions paying (M-Pesa).'), findsOneWidget);
    expect(risky.risks.first.high, isTrue, reason: 'serious signs are listed first');

    await tester.tap(find.widgetWithText(FilledButton, 'Approve'));
    await tester.pumpAndSettle();
    expect(find.textContaining('This listing has 2 warning signs.'), findsOneWidget);
  });

  testWidgets('follow-ups list waiting guests and stale listings', (tester) async {
    final now = DateTime.now();
    final repo = FakeAdminRepository(
      followUps: FollowUps(
        unanswered: [
          UnansweredEnquiry(
            enquiryId: 'e1', propertyId: 'l1', listingNumber: 1042, title: 'Quiet studio', hostName: 'Hassan Host',
            hostWhatsapp: '+254711000111', createdAt: now.subtract(const Duration(hours: 30)),
            checkIn: now.add(const Duration(days: 5)), checkOut: now.add(const Duration(days: 7)), guestCount: 2,
          ),
        ],
        stale: [
          StaleListing(propertyId: 'l2', listingNumber: 1043, title: 'Garden flat', hostName: 'Hassan Host',
              confirmedAt: now.subtract(const Duration(days: 20)), lastNudgedAt: now.subtract(const Duration(hours: 2))),
        ],
      ),
    );
    await _pumpAt(tester, repo, '/follow-ups');
    expect(find.text('Enquiries waiting for a reply (1)'), findsOneWidget);
    expect(find.text('Waiting 30 hours'), findsOneWidget);
    expect(find.text('Last confirmed 20 days ago'), findsOneWidget);
    expect(find.text('Remind again'), findsOneWidget); // reminded 2 hours ago
    expect(find.text('WhatsApp host'), findsOneWidget);
    expect(find.byType(Badge), findsWidgets); // the navigation shows the count
  });

  test('reminder messages tell the host exactly what to do', () {
    final now = DateTime.now();
    final message = enquiryReminder(UnansweredEnquiry(
      enquiryId: 'e1', propertyId: 'l1', listingNumber: 1042, title: 'Quiet studio', hostName: 'Hassan Host',
      createdAt: now.subtract(const Duration(hours: 30)), checkIn: DateTime(2026, 11, 6), checkOut: DateTime(2026, 11, 8),
    ));
    expect(message, startsWith('Hello Hassan, this is PataStay. A guest asked about PS-1042 "Quiet studio"'));
    expect(message, contains('Profile > Hosting > Enquiries'));
  });

  testWidgets('an admin adds an area', (tester) async {
    final repo = FakeAdminRepository(areas: const [AdminArea(id: 'n1', name: 'Kilimani', slug: 'kilimani', listingCount: 4)]);
    await _pumpAt(tester, repo, '/areas');
    expect(find.text('Kilimani'), findsOneWidget);

    await tester.tap(find.text('Add area'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the area name'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Upper Hill');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.calls, ['saveArea new']);
    expect(repo.saved.single['slug'], 'upper-hill');
    expect(repo.saved.single['is_active'], isTrue);
  });

  test('verification needs identity, authority and a visit or video', () {
    VerificationCheck check(VerificationCheckType t, VerificationResult r, int day) =>
        VerificationCheck(id: '$t$day', type: t, result: r, checkedAt: DateTime(2026, 10, day));

    final summary = VerificationSummary([
      check(VerificationCheckType.ownerIdentity, VerificationResult.pass, 1),
      check(VerificationCheckType.ownershipOrAuthority, VerificationResult.pass, 1),
      check(VerificationCheckType.videoWalkthrough, VerificationResult.pass, 1),
      check(VerificationCheckType.ownerIdentity, VerificationResult.fail, 2), // latest result wins
    ]);
    expect(summary.canVerify, isFalse);
    expect(summary.missing, ['Owner identity']);
  });

  test('CSV export quotes values and neutralises formulas', () {
    expect(
      toCsv([
        ['Title', 'Note'],
        ['Studio, Kilimani', '=HYPERLINK("http://evil")'],
        ['Say "karibu"', '-5'],
      ]),
      'Title,Note\r\n"Studio, Kilimani","\'=HYPERLINK(""http://evil"")"\r\n"Say ""karibu""",\'-5',
    );
  });
}
