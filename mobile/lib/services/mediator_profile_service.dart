/// A signed-in mediator's public profile, as returned by the backend on
/// register/login. Session persistence lives in AuthSessionService.
class MediatorProfile {
  final String id;
  final String username;
  final String fullName;
  final String country;
  final String region;
  final String locality;

  MediatorProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.country,
    required this.region,
    required this.locality,
  });

  factory MediatorProfile.fromJson(Map<String, dynamic> json) => MediatorProfile(
        id: json['id'] as String,
        username: json['username'] as String,
        fullName: json['fullName'] as String,
        country: json['country'] as String,
        region: json['region'] as String,
        locality: json['locality'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'fullName': fullName,
        'country': country,
        'region': region,
        'locality': locality,
      };
}
