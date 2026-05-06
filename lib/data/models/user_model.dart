import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.firstName,
    required super.lastName,
    required super.email,
    super.cedula,
    super.avatarPath,
    required super.createdAt,
    required super.birthDate,
    super.subscriptionType = SubscriptionType.free,
    required super.isMinor,
    super.acceptedTerms = false,
    super.acceptedPrivacy = false,
    super.acceptedIntellectual = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        username: json['username'] as String,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String,
        cedula: json['cedula'] as String?,
        avatarPath: json['avatarPath'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        birthDate: DateTime.parse(
            json['birthDate'] as String? ?? DateTime(2000).toIso8601String()),
        subscriptionType:
            SubscriptionType.values.firstWhere(
          (e) => e.name == (json['subscriptionType'] as String? ?? 'free'),
          orElse: () => SubscriptionType.free,
        ),
        isMinor: json['isMinor'] as bool? ?? false,
        acceptedTerms: json['acceptedTerms'] as bool? ?? false,
        acceptedPrivacy: json['acceptedPrivacy'] as bool? ?? false,
        acceptedIntellectual: json['acceptedIntellectual'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'cedula': cedula,
        'avatarPath': avatarPath,
        'createdAt': createdAt.toIso8601String(),
        'birthDate': birthDate.toIso8601String(),
        'subscriptionType': subscriptionType.name,
        'isMinor': isMinor,
        'acceptedTerms': acceptedTerms,
        'acceptedPrivacy': acceptedPrivacy,
        'acceptedIntellectual': acceptedIntellectual,
      };
}
