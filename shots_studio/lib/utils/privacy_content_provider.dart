import 'package:flutter/material.dart';

/// A utility class that provides standardized privacy policy content
/// to be used consistently across different parts of the application.
class PrivacyContentProvider {
  /// Returns common privacy policy information as a list of widgets
  static List<Widget> getPrivacyContent(
    BuildContext context, {
    required Function(BuildContext, String) launchUrlCallback,
  }) {
    final theme = Theme.of(context);

    return [
      Text(
        "Shots Studio offers optional integration with Google Gemini, a third-party cloud-based AI service, to enhance your experience with features such as generating searchable text, suggesting tags, and organizing collections. This integration is entirely optional and only activated when you provide your own Google Gemini API key.\n\n"
        "Important: No data is sent to Google's servers unless you explicitly configure your own API key. The app can be used partially without these AI features.\n\n"
        "When you choose to enable these features by setting your API key, your images will be transmitted to and processed by Google's servers only for the specific AI-powered functions you request.\n",
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 10),
      Text(
        "When AI features are enabled (by providing your API key), this image processing is subject to:",
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 5),
      InkWell(
        child: Text(
          "This image processing is subject to Google's Privacy Policy.",
          style: TextStyle(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
        onTap:
            () => launchUrlCallback(
              context,
              'https://policies.google.com/privacy',
            ),
      ),
      const SizedBox(height: 5),
      InkWell(
        child: Text(
          "And Google's Gemini API Terms of Service.",
          style: TextStyle(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
        onTap: () => launchUrlCallback(context, 'https://ai.google.dev/terms'),
      ),
      const SizedBox(height: 10),
      Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          child: Row(
            children: [
              Icon(
                Icons.open_in_new,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "View our complete Privacy Policy for more details",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          onTap:
              () => launchUrlCallback(
                context,
                'https://ansahmohammad.github.io/shots-studio/privacy.html',
              ),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        "\nShots Studio itself does not permanently store your original images for any AI features.\n\n"
        "The app is only partially functional without AI features - you can capture, organize, and manage your screenshots without any data being sent to third-party services.\n\n"
        "Anonymous usage analytics are collected to help improve the app experience. This includes basic feature usage patterns and performance metrics, but no personal information or image content is included.\n\n"
        "Please ensure you review and are comfortable with Google's terms and privacy practices before enabling AI features by setting your API key. If you do not agree, you can continue using the app without these optional features.\n"
        "P.S. Don't worry, your cat memes are safe with us. 😺",
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
    ];
  }
}
