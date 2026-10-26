import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:patastay_core/patastay_core.dart';

import '../../properties/application/property_providers.dart';

/// The signed-in host's listings (all statuses except archived).
final hostListingsProvider = FutureProvider<List<HostListing>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(hostRepositoryProvider).fetchMyListings(userId);
});

final hostListingProvider = FutureProvider.family<HostListing?, String>(
  (ref, id) => ref.watch(hostRepositoryProvider).fetchListing(id),
);

final hostStatsProvider = FutureProvider<Map<String, ListingStats>>((ref) async {
  if (ref.watch(currentUserIdProvider) == null) return const {};
  return ref.watch(hostRepositoryProvider).fetchStats();
});

final hostEnquiriesProvider = FutureProvider<List<Enquiry>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(hostRepositoryProvider).fetchEnquiries(userId);
});

/// Enquiries the host has not opened yet.
final newHostEnquiriesProvider = Provider<int>((ref) {
  final enquiries = ref.watch(hostEnquiriesProvider).value ?? const [];
  return enquiries.where((e) => e.status == EnquiryStatus.newEnquiry).length;
});

/// Refreshes everything on the host side after a change.
void refreshHostData(WidgetRef ref, {String? listingId}) {
  ref.invalidate(hostListingsProvider);
  ref.invalidate(hostStatsProvider);
  if (listingId != null) {
    ref.invalidate(hostListingProvider(listingId));
    ref.invalidate(propertyDetailsProvider(listingId));
  }
}

/// A photo ready to upload: re-encoded (which strips EXIF metadata such as
/// GPS location), at most 1600 px wide, plus a 480 px thumbnail for lists.
class ProcessedPhoto {
  const ProcessedPhoto({
    required this.full,
    required this.thumbnail,
    required this.width,
    required this.height,
    required this.originalWidth,
  });

  final Uint8List full;
  final Uint8List thumbnail;
  final int width;
  final int height;
  final int originalWidth;

  /// Photos narrower than this look soft on large phones.
  static const recommendedWidth = 1200;
  bool get isLowResolution => originalWidth < recommendedWidth;
}

/// Returns null when the file is not a readable image.
Future<ProcessedPhoto?> processPhoto(Uint8List bytes) => compute(_process, bytes);

ProcessedPhoto? _process(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  // Apply the camera's rotation, then drop all metadata by re-encoding.
  final upright = img.bakeOrientation(decoded);
  final full = upright.width > 1600 ? img.copyResize(upright, width: 1600) : upright;
  final thumb = img.copyResize(upright, width: upright.width > 480 ? 480 : upright.width);
  return ProcessedPhoto(
    full: Uint8List.fromList(img.encodeJpg(full, quality: 82)),
    thumbnail: Uint8List.fromList(img.encodeJpg(thumb, quality: 78)),
    width: full.width,
    height: full.height,
    originalWidth: upright.width,
  );
}
