class AuthModel {
  final String accessToken;
  final String refreshToken;
  final String customerName;

  AuthModel({
    required this.accessToken,
    required this.refreshToken,
    required this.customerName,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      customerName: json['customer_name'] ?? 'User',
    );
  }

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'customer_name': customerName,
      };
}
