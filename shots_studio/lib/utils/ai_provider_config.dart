class AIProviderConfig {
  // Available models for each provider
  static const Map<String, List<String>> providerModels = {
    'gemini': ['gemini-2.0-flash', 'gemini-2.5-pro'],
    'gemma': ['gemma-3n-e4b', 'gemma-3n-e2b'],
    'none': ['No AI Model'],
  };

  // Preference keys for provider settings
  static const Map<String, String> providerPrefKeys = {
    'gemini': 'ai_provider_gemini_enabled',
    'gemma': 'ai_provider_gemma_enabled',
  };

  // Get all available providers (excluding 'none')
  static List<String> getProviders() {
    return providerModels.keys.where((key) => key != 'none').toList();
  }

  // Get models for a specific provider
  static List<String> getModelsForProvider(String provider) {
    return providerModels[provider] ?? [];
  }

  // Get preference key for a provider
  static String? getPrefKeyForProvider(String provider) {
    return providerPrefKeys[provider];
  }

  // Check if a model belongs to a specific provider
  static String getProviderForModel(String model) {
    for (final entry in providerModels.entries) {
      if (entry.value.contains(model)) {
        return entry.key;
      }
    }
    return 'unknown';
  }
}
