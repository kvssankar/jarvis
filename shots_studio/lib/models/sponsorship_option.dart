import 'package:flutter/material.dart';

class SponsorshipOption {
  final String id;
  final String title;
  final String subtitle;
  final String url;
  final IconData icon;
  final Color? iconColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final bool enabled;
  final String? badge; // Optional badge text like "Popular", "New", etc.
  final Color? badgeColor;

  const SponsorshipOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.icon,
    this.iconColor,
    this.titleColor,
    this.subtitleColor,
    this.enabled = true,
    this.badge,
    this.badgeColor,
  });

  SponsorshipOption copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? url,
    IconData? icon,
    Color? iconColor,
    Color? titleColor,
    Color? subtitleColor,
    bool? enabled,
    String? badge,
    Color? badgeColor,
  }) {
    return SponsorshipOption(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      url: url ?? this.url,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      titleColor: titleColor ?? this.titleColor,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      enabled: enabled ?? this.enabled,
      badge: badge ?? this.badge,
      badgeColor: badgeColor ?? this.badgeColor,
    );
  }
}
