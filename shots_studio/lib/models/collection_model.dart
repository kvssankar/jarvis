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

  // Method to convert a Collection instance to a Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'screenshotIds': screenshotIds,
      'lastModified': lastModified.toIso8601String(),
      'screenshotCount': screenshotCount,
      'isAutoAddEnabled': isAutoAddEnabled,
    };
  }

  // Factory constructor to create a Collection instance from a Map (JSON)
  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      screenshotIds: List<String>.from(json['screenshotIds'] as List<dynamic>),
      lastModified: DateTime.parse(json['lastModified'] as String),
      screenshotCount: json['screenshotCount'] as int,
      isAutoAddEnabled:
          json['isAutoAddEnabled'] as bool? ??
          false, // Default to false if null
    );
  }
}
