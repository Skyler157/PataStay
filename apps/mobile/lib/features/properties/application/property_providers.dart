import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/storage/local_preferences.dart';

/// Filters for the Search screen. Home shortcuts (budget chips, areas,
/// categories) set these before opening Search.
class SearchFiltersController extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();

  void replace(SearchFilters filters) => state = filters;
  void update(SearchFilters Function(SearchFilters current) change) => state = change(state);
  void reset() => state = SearchFilters(checkIn: state.checkIn, checkOut: state.checkOut, guests: state.guests);
}

final searchFiltersProvider = NotifierProvider<SearchFiltersController, SearchFilters>(SearchFiltersController.new);

class SearchResults {
  const SearchResults({this.items = const [], this.hasMore = true, this.page = 0, this.loadingMore = false, this.loadMoreError});

  final List<Property> items;
  final bool hasMore;
  final int page;
  final bool loadingMore;
  final Object? loadMoreError;

  SearchResults copyWith({List<Property>? items, bool? hasMore, int? page, bool? loadingMore, Object? loadMoreError}) =>
      SearchResults(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreError: loadMoreError,
      );
}

/// Paginated results for the current filters. Changing filters restarts at page 0.
class SearchResultsController extends AsyncNotifier<SearchResults> {
  @override
  Future<SearchResults> build() async {
    final filters = ref.watch(searchFiltersProvider);
    final page = await ref.watch(propertyRepositoryProvider).search(filters);
    return SearchResults(items: page.items, hasMore: page.hasMore);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await ref
          .read(propertyRepositoryProvider)
          .search(ref.read(searchFiltersProvider), page: current.page + 1);
      state = AsyncData(current.copyWith(
        items: [...current.items, ...next.items],
        hasMore: next.hasMore,
        page: current.page + 1,
        loadingMore: false,
      ));
    } catch (error) {
      state = AsyncData(current.copyWith(loadingMore: false, loadMoreError: error));
    }
  }
}

final searchResultsProvider = AsyncNotifierProvider<SearchResultsController, SearchResults>(SearchResultsController.new);

/// Home screen rows.
final featuredPropertiesProvider = FutureProvider<List<Property>>((ref) async {
  final page = await ref.watch(propertyRepositoryProvider).search(const SearchFilters(featuredOnly: true));
  return page.items.take(8).toList();
});

final recentPropertiesProvider = FutureProvider<List<Property>>((ref) async {
  final page = await ref.watch(propertyRepositoryProvider).search(const SearchFilters(sort: SearchSort.newest));
  return page.items.take(8).toList();
});

final propertyDetailsProvider = FutureProvider.family<Property?, String>(
  (ref, id) => ref.watch(propertyRepositoryProvider).fetchDetails(id),
);

final hostSummaryProvider = FutureProvider.family<HostSummary?, String>(
  (ref, propertyId) => ref.watch(propertyRepositoryProvider).fetchHostSummary(propertyId),
);

/// Saved listing ids for the signed-in user, with optimistic toggling.
class FavouritesController extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];
    return ref.watch(favouritesRepositoryProvider).fetchIds(userId);
  }

  /// Returns false when the user must sign in first.
  Future<bool> toggle(String propertyId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return false;
    final before = state.value ?? const [];
    final saved = before.contains(propertyId);
    state = AsyncData(saved ? (before.where((id) => id != propertyId).toList()) : [propertyId, ...before]);
    try {
      final repo = ref.read(favouritesRepositoryProvider);
      saved ? await repo.remove(userId, propertyId) : await repo.add(userId, propertyId);
    } catch (error) {
      state = AsyncData(before);
      rethrow;
    }
    return true;
  }
}

final favouritesProvider = AsyncNotifierProvider<FavouritesController, List<String>>(FavouritesController.new);

final savedPropertiesProvider = FutureProvider<List<Property>>((ref) async {
  final ids = await ref.watch(favouritesProvider.future);
  return ref.watch(propertyRepositoryProvider).fetchByIds(ids);
});

final myEnquiriesProvider = FutureProvider<List<Enquiry>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(enquiryRepositoryProvider).fetchMine(userId);
});

/// Remembers when the guest last looked at their enquiries.
class EnquiriesSeenController extends Notifier<DateTime?> {
  @override
  DateTime? build() => ref.watch(localPreferencesProvider).enquiriesSeenAt;

  Future<void> markSeen() async {
    final now = DateTime.now();
    state = now;
    await ref.read(localPreferencesProvider).setEnquiriesSeenAt(now);
  }
}

final enquiriesSeenProvider = NotifierProvider<EnquiriesSeenController, DateTime?>(EnquiriesSeenController.new);

/// Host replies the guest has not looked at yet (badge on the Enquiries tab).
final unreadRepliesProvider = Provider<int>((ref) {
  final enquiries = ref.watch(myEnquiriesProvider).value ?? const [];
  final seen = ref.watch(enquiriesSeenProvider);
  return enquiries.where((e) {
    final replied = e.respondedAt ?? e.ownerReportedBookingAt;
    return replied != null && (seen == null || replied.isAfter(seen));
  }).length;
});
