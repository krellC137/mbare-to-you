/// String extension methods
extension StringExtension on String {
  /// Capitalizes the first letter of the string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Capitalizes the first letter of each word
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Checks if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Checks if string is a valid phone number (Zimbabwe)
  bool get isValidPhone {
    final phoneRegex = RegExp(r'^(\+263|0)[7][0-9]{8}$');
    return phoneRegex.hasMatch(this);
  }

  /// Truncates string to specified length with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }

  /// Removes all whitespace
  String removeWhitespace() => replaceAll(RegExp(r'\s+'), '');

  /// Checks if string contains only numbers
  bool get isNumeric => double.tryParse(this) != null;

  /// Converts string to double or returns null
  double? toDoubleOrNull() => double.tryParse(this);

  /// Converts string to int or returns null
  int? toIntOrNull() => int.tryParse(this);
}

/// Nullable string extension methods
extension NullableStringExtension on String? {
  /// Returns true if string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns true if string is not null and not empty
  bool get isNotNullOrEmpty => !isNullOrEmpty;

  /// Returns the string or a default value if null
  String orEmpty() => this ?? '';

  /// Returns the string or a default value if null or empty
  String orDefault(String defaultValue) {
    return isNullOrEmpty ? defaultValue : this!;
  }
}
