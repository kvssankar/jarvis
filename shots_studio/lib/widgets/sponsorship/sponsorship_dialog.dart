import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/sponsorship_option.dart';
import '../../services/analytics/analytics_service.dart';

class SponsorshipDialog extends StatelessWidget {
  final List<SponsorshipOption> sponsorshipOptions;

  const SponsorshipDialog({super.key, required this.sponsorshipOptions});

  Future<void> _launchURL(String urlString) async {
    // Log analytics for sponsorship URL clicks
    AnalyticsService().logFeatureUsed('sponsorship_url_clicked');
    AnalyticsService().logFeatureUsed('external_sponsorship_link');

    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabledOptions =
        sponsorshipOptions.where((option) => option.enabled).toList();
    final disabledOptions =
        sponsorshipOptions.where((option) => !option.enabled).toList();
    final isDark = theme.brightness == Brightness.dark;

    if (sponsorshipOptions.isEmpty) {
      return AlertDialog(
        title: Text('Support', style: theme.textTheme.headlineSmall),
        content: const Text('No sponsorship options are currently available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return Dialog.fullscreen(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              isDark
                  ? theme.colorScheme.surface.withValues(alpha: 0.8)
                  : theme.colorScheme.primary.withValues(alpha: 0.02),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () {
                // Log analytics for sponsorship dialog closed
                AnalyticsService().logFeatureUsed('sponsorship_dialog_closed');

                Navigator.pop(context);
              },
            ),
            title: Text(
              'Support the project',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section with better visual hierarchy
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  child: Column(
                    children: [
                      // Main hero container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Icon with glow effect
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.favorite_rounded,
                                color: theme.colorScheme.onPrimary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Support Shots Studio',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your support helps keep this project alive and enables us to add amazing new features',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Available options section
                if (enabledOptions.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Available now',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...enabledOptions.map(
                    (option) => Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 6,
                      ),
                      child: _buildModernOptionCard(
                        context,
                        option,
                        isEnabled: true,
                      ),
                    ),
                  ),
                ],

                // Coming soon section
                if (disabledOptions.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Coming soon',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...disabledOptions.map(
                    (option) => Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 6,
                      ),
                      child: _buildModernOptionCard(
                        context,
                        option,
                        isEnabled: false,
                      ),
                    ),
                  ),
                ],

                // Bottom spacing and footer
                const SizedBox(height: 40),
                Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? theme.colorScheme.onSecondary
                            : theme.colorScheme.onSecondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.handshake_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Every contribution matters',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thank you for considering supporting this project. Your contribution helps us maintain and improve Shots Studio. For special arrangements or international wire transfers, please reach out via GitHub.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          // Log analytics for GitHub contact button
                          AnalyticsService().logFeatureUsed(
                            'github_contact_clicked',
                          );
                          AnalyticsService().logFeatureUsed(
                            'sponsorship_contact_button',
                          );

                          _launchURL('https://github.com/AnsahMohammad');
                        },
                        child: Text(
                          'Contact on GitHub',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernOptionCard(
    BuildContext context,
    SponsorshipOption option, {
    required bool isEnabled,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Card(
        elevation: 0,
        color:
            isEnabled
                ? (isDark
                    ? theme.colorScheme.surfaceContainerHigh.withValues(
                      alpha: 0.8,
                    )
                    : theme.colorScheme.surface)
                : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color:
                isEnabled
                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                    : theme.colorScheme.outline.withValues(alpha: 0.1),
            width: isEnabled ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap:
                isEnabled
                    ? () {
                      // Log analytics for sponsorship option click
                      AnalyticsService().logFeatureUsed(
                        'sponsorship_option_clicked',
                      );
                      AnalyticsService().logFeatureUsed(
                        'sponsorship_${option.title.toLowerCase().replaceAll(' ', '_')}_clicked',
                      );
                      AnalyticsService().logFeatureAdopted(
                        'sponsorship_engagement',
                      );

                      Navigator.pop(context);
                      _launchURL(option.url);
                    }
                    : null,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Enhanced icon container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color:
                          isEnabled
                              ? (option.iconColor ?? theme.colorScheme.primary)
                                  .withValues(alpha: 0.15)
                              : theme.colorScheme.onSurface.withValues(
                                alpha: 0.05,
                              ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isEnabled
                                ? (option.iconColor ??
                                        theme.colorScheme.primary)
                                    .withValues(alpha: 0.3)
                                : theme.colorScheme.outline.withValues(
                                  alpha: 0.1,
                                ),
                      ),
                    ),
                    child: Icon(
                      option.icon,
                      color:
                          isEnabled
                              ? (option.iconColor ?? theme.colorScheme.primary)
                              : theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Content area
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isEnabled
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            if (option.badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isEnabled
                                          ? (option.badgeColor ??
                                              theme
                                                  .colorScheme
                                                  .primaryContainer)
                                          : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  option.badge!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isEnabled
                                            ? theme
                                                .colorScheme
                                                .onPrimaryContainer
                                            : theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          option.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: isEnabled ? 1.0 : 0.5),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Trailing indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          isEnabled
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : theme.colorScheme.onSurface.withValues(
                                alpha: 0.05,
                              ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEnabled
                          ? Icons.arrow_forward_rounded
                          : Icons.schedule_rounded,
                      color:
                          isEnabled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
