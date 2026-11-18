class ApiException implements Exception {
  const ApiException(this.message, {this.errors = const {}});

  final String message;
  final Map<String, List<String>> errors;

  String get firstError {
    for (final entry in errors.entries) {
      if (entry.value.isNotEmpty) {
        return entry.value.first;
      }
    }

    return message;
  }

  @override
  String toString() => message;
}
