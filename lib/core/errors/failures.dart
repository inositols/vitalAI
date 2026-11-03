import 'package:equatable/equatable.dart';

/// Base Failure class for domain and data layer error handling.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server or API failure.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Validation failure for clinical and business constraints.
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(super.message, {super.code, this.fieldErrors});

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Database or cache access failure.
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

/// Authentication or authorization failure.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Unauthorized clinical action failure.
class UnauthorizedActionFailure extends Failure {
  const UnauthorizedActionFailure(super.message, {super.code});
}
