class Collection {
  final String id;
  final String? name;
  final String? description;
  final List<String> screenshotIds;
  final DateTime lastModified;
  final int screenshotCount;
  final bool isAutoAddEnabled;

  Collection({
    required this.id,
    this.name,
    this.description,
    required this.screenshotIds,
    required this.lastModified,
    required this.screenshotCount,
    this.isAutoAddEnabled = false,
  });

  Collection addScreenshot(String screenshotId) {
    if (!screenshotIds.contains(screenshotId)) {
      final newIds = List<String>.from(screenshotIds)..add(screenshotId);
      return copyWith(
        screenshotIds: newIds,
        screenshotCount: newIds.length,
        lastModified: DateTime.now(),
      );
    }
    return this;
  }

  Collection removeScreenshot(String screenshotId) {
    if (screenshotIds.contains(screenshotId)) {
      final newIds = List<String>.from(screenshotIds)..remove(screenshotId);
      return copyWith(
        screenshotIds: newIds,
        screenshotCount: newIds.length,
        lastModified: DateTime.now(),
      );
    }
    return this;
  }

  Collection copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? screenshotIds,
    DateTime? lastModified,
    int? screenshotCount,
    bool? isAutoAddEnabled,
  }) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      screenshotIds: screenshotIds ?? this.screenshotIds,
      lastModified: lastModified ?? this.lastModified,
      screenshotCount: screenshotCount ?? this.screenshotCount,
      isAutoAddEnabled: isAutoAddEnabled ?? this.isAutoAddEnabled,
    );
  }
}
