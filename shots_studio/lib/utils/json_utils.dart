/// JSON utility functions for parsing and fixing JSON responses
class JsonUtils {
  /// Check if JSON string appears to be complete by matching brackets and braces
  static bool isCompleteJson(String jsonString) {
    if (jsonString.trim().isEmpty) return false;

    // Count brackets to see if they match
    int openBrackets = 0;
    int closeBrackets = 0;
    int openBraces = 0;
    int closeBraces = 0;

    for (int i = 0; i < jsonString.length; i++) {
      switch (jsonString[i]) {
        case '[':
          openBrackets++;
          break;
        case ']':
          closeBrackets++;
          break;
        case '{':
          openBraces++;
          break;
        case '}':
          closeBraces++;
          break;
      }
    }

    return openBrackets == closeBrackets && openBraces == closeBraces;
  }

  /// Attempt to fix incomplete JSON by adding missing brackets and braces
  static String attemptJsonFix(String jsonString) {
    String fixed = jsonString.trim();

    // Count missing brackets
    int openBrackets = 0;
    int closeBrackets = 0;
    int openBraces = 0;
    int closeBraces = 0;

    for (int i = 0; i < fixed.length; i++) {
      switch (fixed[i]) {
        case '[':
          openBrackets++;
          break;
        case ']':
          closeBrackets++;
          break;
        case '{':
          openBraces++;
          break;
        case '}':
          closeBraces++;
          break;
      }
    }

    // Add missing closing braces
    int missingBraces = openBraces - closeBraces;
    for (int i = 0; i < missingBraces; i++) {
      fixed += '}';
    }

    // Add missing closing brackets
    int missingBrackets = openBrackets - closeBrackets;
    for (int i = 0; i < missingBrackets; i++) {
      fixed += ']';
    }

    return fixed;
  }

  /// Clean response text by removing markdown code fences
  static String cleanMarkdownCodeFences(String responseText) {
    String cleanedResponseText = responseText.trim();

    // Remove markdown code fences if present
    if (cleanedResponseText.startsWith('```json')) {
      cleanedResponseText = cleanedResponseText.substring(7); // Remove ```json
    } else if (cleanedResponseText.startsWith('```')) {
      cleanedResponseText = cleanedResponseText.substring(3); // Remove ```
    }

    if (cleanedResponseText.endsWith('```')) {
      cleanedResponseText = cleanedResponseText.substring(
        0,
        cleanedResponseText.length - 3,
      ); // Remove ending ```
    }

    return cleanedResponseText.trim();
  }
}
