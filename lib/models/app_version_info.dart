class AppVersionInfo {
  final String platform;
  final String latestVersion;
  final int latestBuild;
  final bool forceUpdate;
  final String title;
  final String message;
  final String? changelog;
  final String? storeUrl;
  final double? sizeMb;

  AppVersionInfo({
    required this.platform,
    required this.latestVersion,
    required this.latestBuild,
    required this.forceUpdate,
    required this.title,
    required this.message,
    this.changelog,
    this.storeUrl,
    this.sizeMb,
  });

  factory AppVersionInfo.fromMap(Map<String, dynamic> m) => AppVersionInfo(
        platform: m['platform'] as String,
        latestVersion: m['latest_version'] as String,
        latestBuild: m['latest_build'] as int,
        forceUpdate: m['force_update'] as bool? ?? false,
        title: m['title'] as String? ?? 'Update available',
        message: m['message'] as String? ?? '',
        changelog: m['changelog'] as String?,
        storeUrl: m['store_url'] as String?,
        sizeMb: (m['size_mb'] as num?)?.toDouble(),
      );
}