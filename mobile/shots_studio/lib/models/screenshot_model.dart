import 'dart:typed_data';

class Screenshot {
  String id;
  String? path; // For mobile (file path)
  Uint8List? bytes; // For web (image bytes)
  String? title;
  String? description;
  List<String> tags;
  String? collectionId;
  bool aiProcessed;
  DateTime addedOn;

  Screenshot({
    required this.id,
    this.path,
    this.bytes,
    this.title,
    this.description,
    required this.tags,
    this.collectionId,
    required this.aiProcessed,
    required this.addedOn,
  });
}
