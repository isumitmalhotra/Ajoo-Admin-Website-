class UnauthorizedUserException implements Exception {
  final String message;

  UnauthorizedUserException([this.message = "Unauthorized access"]);

  @override
  String toString() => message;
}
