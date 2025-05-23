import 'dart:typed_data';

class Screenshot {
  String id;
  String? path; // For mobile (file path)
  Uint8List? bytes; // For web (image bytes)
  String? title;
  String? description;
  List<String> tags;
  List<String> collectionIds; // Added field
  bool aiProcessed;
  DateTime addedOn;

  Screenshot({
    required this.id,
    this.path,
    this.bytes,
    this.title,
    this.description,
    required this.tags,
    this.collectionIds = const [], // Initialize with empty list
    required this.aiProcessed,
    required this.addedOn,
  });
}
