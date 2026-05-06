import 'package:equatable/equatable.dart';

enum SubscriptionType { free, premium }

class User extends Equatable {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? cedula;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime birthDate;
  final SubscriptionType subscriptionType;
  final bool isMinor;
  final bool acceptedTerms;
  final bool acceptedPrivacy;
  final bool acceptedIntellectual;

  const User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.cedula,
    this.avatarPath,
    required this.createdAt,
    required this.birthDate,
    this.subscriptionType = SubscriptionType.free,
    required this.isMinor,
    this.acceptedTerms = false,
    this.acceptedPrivacy = false,
    this.acceptedIntellectual = false,
  });

  @override
  List<Object?> get props => [id, email];
}
