import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/widgets/form_widgets.dart';
import '../../properties/presentation/widgets/property_widgets.dart';
import '../application/host_providers.dart';
import 'editor_steps.dart';

/// Photos: add (gallery or camera), reorder (first is the cover), delete.
/// Each photo is compressed and stripped of metadata before upload.
class PhotosStep extends ConsumerStatefulWidget {
  const PhotosStep({super.key, required this.listing, required this.onSaved});

  final HostListing listing;
  final StepSaved onSaved;

  @override
  ConsumerState<PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends ConsumerState<PhotosStep> {
  late List<PropertyImage> _photos = [...widget.listing.property.images];
  final _picker = ImagePicker();
  int _uploading = 0;
  int _lowResolution = 0;
  bool _reordering = false;

  static const _maxPhotos = 20;

  @override
  void didUpdateWidget(covariant PhotosStep old) {
    super.didUpdateWidget(old);
    // Keep the server's latest list once uploads have finished.
    if (_uploading == 0 && !_reordering) _photos = [...widget.listing.property.images];
  }

  Future<void> _add({required bool camera}) async {
    final room = _maxPhotos - _photos.length;
    if (room <= 0) {
      context.showMessage('You can add up to $_maxPhotos photos.');
      return;
    }
    final List<XFile> picked;
    try {
      picked = camera
          ? [?(await _picker.pickImage(source: ImageSource.camera))]
          : await _picker.pickMultiImage(limit: room);
    } catch (_) {
      if (mounted) context.showMessage('Could not open your photos. Check that PataStay may access them.');
      return;
    }
    if (picked.isEmpty) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() {
      _uploading += picked.length;
      _lowResolution = 0;
    });
    var failed = 0;
    for (final file in picked.take(room)) {
      try {
        final processed = await processPhoto(await file.readAsBytes());
        if (processed == null) {
          failed++;
          continue;
        }
        if (processed.isLowResolution) _lowResolution++;
        final image = await ref.read(hostRepositoryProvider).uploadPhoto(
              ownerId: userId,
              propertyId: widget.listing.id,
              full: processed.full,
              thumbnail: processed.thumbnail,
              width: processed.width,
              height: processed.height,
              displayOrder: _photos.length,
            );
        if (mounted) setState(() => _photos = [..._photos, image]);
      } on AppFailure catch (failure) {
        failed++;
        if (mounted) context.showFailure(failure);
      } finally {
        if (mounted) setState(() => _uploading--);
      }
    }
    refreshHostData(ref, listingId: widget.listing.id);
    if (!mounted) return;
    if (failed > 0) {
      context.showMessage('$failed photo${failed == 1 ? '' : 's'} could not be added. Try a JPEG or PNG under 15 MB.');
    } else if (_lowResolution > 0) {
      context.showMessage('$_lowResolution photo${_lowResolution == 1 ? ' is' : 's are'} small and may look blurry. '
          'Photos at least ${ProcessedPhoto.recommendedWidth} px wide look best.');
    }
  }

  Future<void> _delete(PropertyImage image) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    final before = _photos;
    setState(() => _photos = _photos.where((p) => p.id != image.id).toList());
    try {
      await ref.read(hostRepositoryProvider).deletePhoto(image);
      // Close the gap in display order so the remaining photos stay in sequence.
      if (_photos.isNotEmpty) await _saveOrder(_photos);
      refreshHostData(ref, listingId: widget.listing.id);
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() => _photos = before);
        context.showFailure(failure);
      }
    }
  }

  Future<void> _saveOrder(List<PropertyImage> photos) async {
    await ref.read(hostRepositoryProvider).reorderPhotos(widget.listing.id, [for (final p in photos) p.id!]);
  }

  /// [newIndex] is already adjusted for the removed item (onReorderItem).
  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final before = _photos;
    final next = [..._photos];
    next.insert(newIndex, next.removeAt(oldIndex));
    setState(() {
      _photos = next;
      _reordering = true;
    });
    try {
      await _saveOrder(next);
      refreshHostData(ref, listingId: widget.listing.id);
    } on AppFailure catch (failure) {
      if (mounted) {
        setState(() => _photos = before);
        context.showFailure(failure);
      }
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final needed = HostListing.minimumPhotos - _photos.length;
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, Space.xxl),
          children: [
            Text(
              'Add at least ${HostListing.minimumPhotos} real photos of this place: the living area, bedroom, kitchen and bathroom. '
              'Drag to reorder; the first photo is the cover.',
              style: context.text.bodyLarge?.copyWith(color: context.palette.mutedText),
            ),
            Gap.md,
            const InfoBanner(
              message: 'Only use photos of this exact place that you took or are allowed to use. '
                  'Copied photos are a common scam sign and get listings rejected.',
            ),
            Gap.lg,
            Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
              FilledButton.tonalIcon(
                onPressed: _uploading > 0 ? null : () => _add(camera: false),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Add from gallery'),
              ),
              if (!kIsWeb)
                OutlinedButton.icon(
                  onPressed: _uploading > 0 ? null : () => _add(camera: true),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Take a photo'),
                ),
            ]),
            if (_uploading > 0) ...[
              Gap.md,
              Row(children: [
                const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
                Gap.sm,
                Text('Preparing and uploading $_uploading photo${_uploading == 1 ? '' : 's'}…', style: context.text.bodyMedium),
              ]),
            ],
            Gap.lg,
            Text(
              needed > 0
                  ? '${_photos.length} added · add $needed more'
                  : '${_photos.length} photo${_photos.length == 1 ? '' : 's'} · up to $_maxPhotos',
              style: context.text.titleSmall,
            ),
            Gap.sm,
            if (_photos.isEmpty)
              Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: context.colors.outlineVariant),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Text('No photos yet', style: context.text.bodyMedium),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _photos.length,
                onReorderItem: _reorder,
                itemBuilder: (context, i) {
                  final photo = _photos[i];
                  return Padding(
                    key: ValueKey(photo.id ?? photo.storagePath),
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Row(children: [
                        SizedBox(width: 120, height: 84, child: PropertyPhoto(image: photo, thumbnail: true)),
                        Gap.md,
                        Expanded(
                          child: Text(i == 0 ? 'Cover photo' : 'Photo ${i + 1}',
                              style: i == 0 ? context.text.titleSmall : context.text.bodyMedium),
                        ),
                        IconButton(
                          tooltip: 'Remove photo',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: _uploading > 0 ? null : () => _delete(photo),
                        ),
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.all(Space.md),
                            child: Icon(Icons.drag_indicator_rounded, semanticLabel: 'Drag to reorder'),
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      Material(
        color: context.colors.surface,
        elevation: 6,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _uploading > 0 ? null : widget.onSaved,
                child: Text(needed > 0 ? 'Continue (add photos later)' : 'Continue'),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
