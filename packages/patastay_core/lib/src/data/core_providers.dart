import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/profile.dart';
import '../models/reference_data.dart';
import 'auth_repository.dart';
import 'guest_repositories.dart';
import 'profile_repository.dart';
import 'property_repository.dart';
import 'reference_data_repository.dart';

/// Overridden in each app's bootstrap with the validated configuration.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError('appConfigProvider must be overridden at startup'),
);

final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider).auth),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);

final referenceDataRepositoryProvider = Provider<ReferenceDataRepository>(
  (ref) => ReferenceDataRepository(ref.watch(supabaseClientProvider)),
);

final authStateChangesProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

/// The signed-in user's id, or null. Only notifies listeners when the id
/// actually changes (token refreshes do not cause profile reloads).
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).currentUser?.id;
});

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).fetchProfile(userId);
});

final neighbourhoodsProvider = FutureProvider<List<Neighbourhood>>(
  (ref) => ref.watch(referenceDataRepositoryProvider).fetchNeighbourhoods(),
);

final amenitiesProvider = FutureProvider<List<Amenity>>(
  (ref) => ref.watch(referenceDataRepositoryProvider).fetchAmenities(),
);

final propertyRepositoryProvider = Provider<PropertyRepository>(
  (ref) => PropertyRepository(ref.watch(supabaseClientProvider)),
);

final favouritesRepositoryProvider = Provider<FavouritesRepository>(
  (ref) => FavouritesRepository(ref.watch(supabaseClientProvider)),
);

final enquiryRepositoryProvider = Provider<EnquiryRepository>(
  (ref) => EnquiryRepository(ref.watch(supabaseClientProvider)),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(supabaseClientProvider)),
);
