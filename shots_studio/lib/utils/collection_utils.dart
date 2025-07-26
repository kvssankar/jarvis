// Collection Management Utilities
class CollectionUtils {
  /// Stores suggested collections for a screenshot in the response map
  static void storeSuggestedCollections(
    Map<String, dynamic> response,
    String screenshotId,
    List<String> collectionNames,
  ) {
    try {
      Map<String, List<String>> suggestedCollections;
      if (response.containsKey('suggestedCollections') &&
          response['suggestedCollections'] is Map) {
        suggestedCollections = Map<String, List<String>>.from(
          response['suggestedCollections'] as Map,
        );
      } else {
        suggestedCollections = {};
      }
      suggestedCollections[screenshotId] = collectionNames;
      response['suggestedCollections'] = suggestedCollections;
    } catch (e) {
      print('Error storing collection suggestions: $e');
    }
  }

  /// Retrieves suggested collections for a screenshot from the response map
  static List<String>? getSuggestedCollections(
    Map<String, dynamic> response,
    String screenshotId,
  ) {
    try {
      if (response.containsKey('suggestedCollections') &&
          response['suggestedCollections'] is Map) {
        final suggestedCollections = Map<String, List<String>>.from(
          response['suggestedCollections'] as Map,
        );
        return suggestedCollections[screenshotId];
      }
    } catch (e) {
      print('Error retrieving collection suggestions: $e');
    }
    return null;
  }

  /// Clears all suggested collections from the response map
  static void clearSuggestedCollections(Map<String, dynamic> response) {
    try {
      response.remove('suggestedCollections');
    } catch (e) {
      print('Error clearing collection suggestions: $e');
    }
  }
}
