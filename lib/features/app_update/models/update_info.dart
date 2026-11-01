class UpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String serverVersion;
  final String? buildTime;
  final int? timestamp;
  final String? errorMessage;

  const UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.serverVersion,
    this.buildTime,
    this.timestamp,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
}

