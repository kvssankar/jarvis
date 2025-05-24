import 'dart:typed_data';

class Screenshot {
  String id;
  String? path; // For mobile (file path)
  Uint8List? bytes; // For web (image bytes)
  String? title;
  String? description;
  List<String> tags;
  List<String> collectionIds;
  bool aiProcessed;
  DateTime addedOn;

  Screenshot({
    required this.id,
    this.path,
    this.bytes,
    this.title,
    this.description,
    required this.tags,
    List<String>? collectionIds,
    required this.aiProcessed,
    required this.addedOn,
  }) : collectionIds = collectionIds ?? [];

  void addToCollections(List<String> collections) {
    collectionIds.addAll(
      collections.where((id) => !collectionIds.contains(id)),
    );
  }
}
