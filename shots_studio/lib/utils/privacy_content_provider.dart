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
        "How AI Features Work in Shots Studio:\n\n"
        "• Local AI (Gemma): Runs entirely on your device. Your images never leave your phone.\n\n"
        "• Cloud AI (Google Gemini): Optional feature that requires your own API key. When enabled, your images are sent to Google's servers for processing.\n\n"
        "You choose which AI option to use. The app works great with just the local AI model - no internet required!\n",
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 15),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Important Privacy Note",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "If you use Google Gemini (cloud AI), your images will be processed by Google's servers. This only happens when you:",
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "1. Set up your own Google Gemini API key\n2. Choose to use cloud AI features",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text(
        "If you use cloud AI, your image processing follows:",
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
        "What We Don't Store:\n"
        "• Your original images are never permanently stored by Shots Studio\n"
        "• When using local AI (Gemma), your data never leaves your device\n\n"
        "What We Do Collect:\n"
        "• Anonymous usage statistics to improve the app (no personal info or images)\n"
        "• Basic feature usage patterns and performance metrics\n\n",
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
    ];
  }
}
