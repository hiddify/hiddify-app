enum AccessState {
  notConfigured,
  loading,
  active,
  activeMetadataUnavailable,
  expired,
  temporarilyUnavailable;

  static AccessState derive({
    required bool hasProfile,
    required DateTime now,
    bool loading = false,
    DateTime? expiresAt,
    Object? error,
  }) {
    if (loading) return AccessState.loading;
    if (!hasProfile) return AccessState.notConfigured;
    if (error != null) return AccessState.temporarilyUnavailable;
    if (expiresAt == null) return AccessState.activeMetadataUnavailable;
    return expiresAt.isAfter(now) ? AccessState.active : AccessState.expired;
  }
}
