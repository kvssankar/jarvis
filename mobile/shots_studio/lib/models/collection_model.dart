class Collection {
  String id;
  String? name;
  String? description;
  List<String> screenshotIds; // List of Screenshot IDs
  DateTime lastModified;
  int screenshotCount;

  Collection({
    required this.id,
    this.name,
    this.description,
    List<String>? screenshotIds,
    DateTime? lastModified,
    this.screenshotCount = 0,
  }) : screenshotIds = screenshotIds ?? [],
       lastModified = lastModified ?? DateTime.now();

  // Add a screenshot ID to the collection
  void addScreenshot(String screenshotId) {
    if (!screenshotIds.contains(screenshotId)) {
      screenshotIds.add(screenshotId);
      screenshotCount = screenshotIds.length;
      lastModified = DateTime.now();
    }
  }

  // Remove a screenshot ID from the collection
  void removeScreenshot(String screenshotId) {
    if (screenshotIds.remove(screenshotId)) {
      screenshotCount = screenshotIds.length;
      lastModified = DateTime.now();
    }
  }
}
