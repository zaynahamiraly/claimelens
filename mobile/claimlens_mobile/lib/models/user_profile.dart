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
    this.emailVerified = false,
    this.mustChangePassword = false,
    this.permissions = const [],
    this.verificationRequired = false,
  });

  final String id;
  final String displayName;
  final String role;
  final String status;
  final String? email;
  final String phone, theme;
  final bool notificationsEnabled;
  final bool emailVerified, mustChangePassword;
  final List<String> permissions;
  final bool verificationRequired;

  bool get isClient => role == 'client';
  bool get isAdmin => role == 'administrator';
  bool get isManager => isAdmin || role == 'supervisor';
  bool get isFinance =>
      role == 'finance' || permissions.contains('payments.record');

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        role: json['role'] as String,
        status: json['status'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String? ?? '',
        theme: json['theme'] as String? ?? 'system',
        notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
        emailVerified: json['email_verified'] as bool? ?? false,
        mustChangePassword: json['must_change_password'] as bool? ?? false,
        permissions: List<String>.from(json['permissions'] as List? ?? []),
        verificationRequired: json['verification_required'] as bool? ?? false,
      );
}
