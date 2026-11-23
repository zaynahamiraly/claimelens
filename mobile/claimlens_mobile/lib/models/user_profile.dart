class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.role,
    required this.status,
    this.email,
    this.phone = '',
    this.theme = 'system',
    this.notificationsEnabled = true,
  });

  final String id;
  final String displayName;
  final String role;
  final String status;
  final String? email;
  final String phone, theme;
  final bool notificationsEnabled;

  bool get isClient => role == 'client';
  bool get isAdmin => role == 'administrator';
  bool get isManager => isAdmin || role == 'supervisor';

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        role: json['role'] as String,
        status: json['status'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String? ?? '',
        theme: json['theme'] as String? ?? 'system',
        notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      );
}
