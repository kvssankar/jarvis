import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateCheckerService {
  static const String githubApiUrl = 'https://api.github.com/repos';
  static const String repoOwner = 'AnsahMohammad';
  static const String repoName = 'shots-studio';

  /// Checks for app updates by comparing current version with latest GitHub release
  /// Returns null if no update available, or UpdateInfo if update is available
  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Fetch latest release from GitHub
      final latestRelease = await _getLatestRelease();
      if (latestRelease == null) {
        return null;
      }

      // Compare versions
      final latestVersion = _extractVersionFromTag(latestRelease['tag_name']);
      if (latestVersion == null) {
        return null;
      }

      if (_isNewerVersion(currentVersion, latestVersion)) {
        return UpdateInfo(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          releaseUrl: latestRelease['html_url'],
          releaseNotes: latestRelease['body'] ?? '',
          tagName: latestRelease['tag_name'],
          publishedAt: latestRelease['published_at'],
        );
      } else {}

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetches the latest release from GitHub API
  static Future<Map<String, dynamic>?> _getLatestRelease() async {
    try {
      final response = await http
          .get(
            Uri.parse('$githubApiUrl/$repoOwner/$repoName/releases/latest'),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'shots_studio_app',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('GitHub API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Network error fetching latest release: $e');
      return null;
    }
  }

  /// Extracts version number from GitHub tag (e.g., "v1.8.52" -> "1.8.52")
  static String? _extractVersionFromTag(String tagName) {
    if (tagName.startsWith('v')) {
      return tagName.substring(1);
    }
    return tagName;
  }

  /// Compares two version strings to determine if the new version is newer
  /// Supports semantic versioning format (major.minor.patch)
  static bool _isNewerVersion(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      // Ensure both versions have the same number of parts by padding with zeros
      while (currentParts.length < latestParts.length) {
        currentParts.add(0);
      }
      while (latestParts.length < currentParts.length) {
        latestParts.add(0);
      }

      // Compare version parts
      for (int i = 0; i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) {
          return true;
        } else if (latestParts[i] < currentParts[i]) {
          return false;
        }
      }

      return false; // Versions are equal
    } catch (e) {
      print('Error comparing versions: $e');
      return false;
    }
  }
}

/// Contains information about an available app update
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;
  final String releaseNotes;
  final String tagName;
  final String publishedAt;

  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
    required this.releaseNotes,
    required this.tagName,
    required this.publishedAt,
  });

  @override
  String toString() {
    return 'UpdateInfo(current: $currentVersion, latest: $latestVersion)';
  }
}
