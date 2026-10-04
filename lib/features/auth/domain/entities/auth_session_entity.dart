class AuthSessionEntity {
  final String homeserver;
  final String userId;
  final String deviceId;
  final String accessToken;
  final String? refreshToken;

  const AuthSessionEntity({
    required this.homeserver,
    required this.userId,
    required this.deviceId,
    required this.accessToken,
    this.refreshToken,
  });
}
